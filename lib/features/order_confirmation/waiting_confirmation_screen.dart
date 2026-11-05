import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class WaitingConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const WaitingConfirmationScreen({super.key, required this.orderId});

  @override
  ConsumerState<WaitingConfirmationScreen> createState() =>
      _WaitingConfirmationScreenState();
}

class _WaitingConfirmationScreenState
    extends ConsumerState<WaitingConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _haloController;
  late AnimationController _floatController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // 2.4s ease-in-out loop for outer halo
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 3s floating animation for sweet box icon
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollOrderStatus();
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _pollOrderStatus();
      });
    });
  }

  Future<void> _pollOrderStatus() async {
    if (!mounted) return;
    final updated = await ref
        .read(orderProvider.notifier)
        .fetchOrderById(widget.orderId);

    if (!mounted || updated == null) return;

    if (updated.orderStatus == OrderStatus.orderConfirmed ||
        updated.orderStatus == OrderStatus.preparing ||
        updated.orderStatus == OrderStatus.readyForPickup ||
        updated.orderStatus == OrderStatus.outForDelivery) {
      _pollTimer?.cancel();
      context.go('/order-confirmed/${widget.orderId}');
    } else if (updated.orderStatus == OrderStatus.changesProposed) {
      _pollTimer?.cancel();
      context.go('/shop-proposed-changes/${widget.orderId}');
    } else if (updated.orderStatus == OrderStatus.declined) {
      _pollTimer?.cancel();
      context.go('/shop-declined-order/${widget.orderId}');
    } else if (updated.orderStatus == OrderStatus.cancelled) {
      _pollTimer?.cancel();
      context.go('/order-details/${widget.orderId}');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _haloController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        title: const Text('Cancel Order?', style: AppTypography.heading2),
        content: const Text(
          'Cancellation is completely free while the shop is reviewing your order.\nAre you sure you want to cancel?',
          style: AppTypography.body,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _pollTimer?.cancel();
              await ref.read(orderProvider.notifier).cancelOrderApi(
                    orderId: widget.orderId,
                    reason: 'Cancelled while awaiting confirmation',
                  );
              if (mounted) {
                context.go('/order-details/${widget.orderId}');
              }
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = (orderState.activeOrder?.orderId == widget.orderId
            ? orderState.activeOrder
            : orderState.pastOrders
                .where((o) => o.orderId == widget.orderId)
                .firstOrNull) ??
        orderState.activeOrder;
    if (order == null) return const NoOrderData();
    final int seconds = orderState.confirmationCountdownSeconds;
    final double progress = seconds / 180.0; // 03:00 to 00:00

    // Auto-navigate to Timeout if 00:00 reached
    if (seconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/confirmation-timeout/${widget.orderId}');
      });
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double ringDiameter = min(screenWidth * 0.56, 240.0);

    final bool isFinalWaiting = seconds <= 30;

    return Scaffold(
      backgroundColor: AppColors.primaryTint10,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            tooltip: 'Minimize and browse',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p24,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Title & Supporting text
                    const Text(
                      'Confirming your order…',
                      style: AppTypography.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We’re waiting for ${order.shopName ?? "the shop"} to confirm your items.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // Hero Countdown Ring with Outer Breathing Halo
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Pulsing Halo (scale 1.0 to 1.08, opacity 0.35 to 0)
                          AnimatedBuilder(
                            animation: _haloController,
                            builder: (context, child) {
                              final scale =
                                  1.0 + (_haloController.value * 0.08);
                              final opacity =
                                  (1.0 - _haloController.value) * 0.35;
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: ringDiameter + 24,
                                  height: ringDiameter + 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(
                                      alpha: opacity,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Circular Progress Ring (Diameter max 240, stroke 10)
                          SizedBox(
                            width: ringDiameter,
                            height: ringDiameter,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  AppColors.divider, // Concrete Grey 25%
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),

                          // Inner Content (Floating Sweet Box Icon + Tabular Countdown Time)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 3px floating animation over 3s
                              AnimatedBuilder(
                                animation: _floatController,
                                builder: (context, _) {
                                  final dy =
                                      sin(_floatController.value * pi * 2) * 3;
                                  return Transform.translate(
                                    offset: Offset(0, dy),
                                    child: const Icon(
                                      Icons.cake_outlined,
                                      size: 40,
                                      color: AppColors.textPrimary,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                Formatters.formatCountdown(seconds),
                                style: AppTypography.countdown,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'remaining',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Phase status indicator
                    if (isFinalWaiting) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Your order is taking a little longer to confirm.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.accentPressed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Live kitchen link established • Awaiting chef acceptance',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Pinned Summary Card
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.p16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCard,
                        ),
                        border: Border.all(color: AppColors.neutralLight),
                        boxShadow: AppDimensions.elevationLevel1,
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            'Order Reference',
                            order.orderNumber != null
                                ? '#${order.orderNumber}'
                                : '#${widget.orderId}',
                          ),
                          _summaryRow(
                            'Items Count',
                            '${order.items.length} items',
                          ),
                          _summaryRow(
                            'Estimated Delivery',
                            order.estimatedDeliveryTime != null
                                ? Formatters.formatTime(order.estimatedDeliveryTime!)
                                : '30-45 mins',
                          ),
                          _summaryRow(
                            'Payment Status',
                            order.paymentStatus == PaymentStatus.paid
                                ? 'Confirmed (Paid)'
                                : 'COD Pending',
                          ),
                          _summaryRow(
                            'Delivery Address',
                            order.deliveryAddress,
                          ),
                          if (order.deliveryOtp != null &&
                              order.deliveryOtp!.isNotEmpty) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Delivery OTP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryPressed,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint20,
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: AppColors.primary),
                                  ),
                                  child: Text(
                                    order.deliveryOtp!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: AppColors.primaryPressed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Order Text Button (Section 24: text button, never filled)
                    TextButton(
                      onPressed: _showCancelDialog,
                      child: const Text(
                        'Cancel Order',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Flexible(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
