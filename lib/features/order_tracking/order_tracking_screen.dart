import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/badges/order_status_badge.dart';
import 'package:fdp/core/widgets/badges/payment_status_badge.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';
import '../../core/services/websocket_tracking_service.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _pollingTimer;
  StreamSubscription<OrderUpdateEvent>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
      // Connect to live duplex WebSocket room
      wsTrackingService.subscribeOrder(widget.orderId);
      _wsSubscription = wsTrackingService.orderUpdates.listen((event) {
        if (event.orderId == widget.orderId && mounted) {
          ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
        }
      });
      _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
      });
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    wsTrackingService.unsubscribeOrder(widget.orderId);
    _pollingTimer?.cancel();
    super.dispose();
  }

  int _getStatusStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.orderPlaced:
      case OrderStatus.confirmingOrder:
      case OrderStatus.orderConfirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.readyForPickup:
        return 3;
      case OrderStatus.driverAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      default:
        return 1;
    }
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

    final int currentStep = _getStatusStep(order.orderStatus);
    final bool isOutForDelivery =
        order.orderStatus == OrderStatus.outForDelivery ||
            order.orderStatus == OrderStatus.pickedUp ||
            order.orderStatus == OrderStatus.driverAssigned;
    final bool isDelivered = order.orderStatus == OrderStatus.delivered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          order.orderNumber != null
              ? 'Track #${order.orderNumber}'
              : 'Track #${widget.orderId}',
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () =>
                ref.read(orderProvider.notifier).fetchOrderById(widget.orderId),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(orderProvider.notifier).fetchOrderById(widget.orderId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card (Shop & Estimated Arrival)
              Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                  boxShadow: AppDimensions.elevationLevel1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.shopName,
                            style: AppTypography.heading2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OrderStatusBadge(status: order.orderStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.estimatedDeliveryTime != null
                              ? 'Estimated Arrival: ${Formatters.formatTime(order.estimatedDeliveryTime!)}'
                              : 'Estimated: 30-45 mins',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryPressed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PaymentStatusBadge(status: order.paymentStatus),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Delivery OTP Card (Visible to Customer!)
              if (order.deliveryOtp != null &&
                  order.deliveryOtp!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint20,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: AppColors.onPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Doorstep Delivery OTP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPressed,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Share with delivery partner upon food inspection',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Text(
                          order.deliveryOtp!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.0,
                            color: AppColors.primaryPressed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Live Driver GPS Banner (When Out for Delivery)
              if (isOutForDelivery) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: AppDimensions.elevationLevel2,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.two_wheeler_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery Partner En Route',
                                  style: AppTypography.itemName,
                                ),
                                Text(
                                  order.driverName ?? 'Partner Assigned',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppPrimaryButton(
                        label: 'View Live GPS Map & Route',
                        icon: Icons.map_outlined,
                        onPressed: () =>
                            context.push('/live-map/${widget.orderId}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Rate & Review Button (When Delivered)
              if (isDelivered) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint10,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Delivered Successfully!',
                        style: AppTypography.heading2,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hope you loved your freshly packed sweet treats.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: 'Rate & Review Order',
                        icon: Icons.star_rate_rounded,
                        onPressed: () =>
                            context.push('/rate-review/${widget.orderId}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Order Milestones Stepper
              Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Timeline', style: AppTypography.itemName),
                    const SizedBox(height: 16),
                    _buildTimelineStep(
                      stepNumber: 1,
                      currentStep: currentStep,
                      title: 'Order Confirmed',
                      subtitle: 'Restaurant accepted and queued your order',
                      isFirst: true,
                    ),
                    _buildTimelineStep(
                      stepNumber: 2,
                      currentStep: currentStep,
                      title: 'Preparing Food',
                      subtitle: 'Chef is crafting and boxing sweets',
                    ),
                    _buildTimelineStep(
                      stepNumber: 3,
                      currentStep: currentStep,
                      title: 'Ready for Pickup',
                      subtitle: 'Packed with tamper-proof seal at counter',
                    ),
                    _buildTimelineStep(
                      stepNumber: 4,
                      currentStep: currentStep,
                      title: 'Out for Delivery',
                      subtitle:
                          'Delivery partner verified pickup and is driving to you',
                    ),
                    _buildTimelineStep(
                      stepNumber: 5,
                      currentStep: currentStep,
                      title: 'Delivered',
                      subtitle: 'Doorstep handover verified via OTP',
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. Delivery Address Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: AppTypography.itemName,
                    ),
                    const SizedBox(height: 6),
                    Text(order.deliveryAddress, style: AppTypography.bodySmall),
                    if (order.deliveryInstructions != null &&
                        order.deliveryInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: ${order.deliveryInstructions}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 7. Navigation Actions
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Order Details',
                      icon: Icons.receipt_long_outlined,
                      onPressed: () =>
                          context.push('/order-details/${widget.orderId}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Need Help?',
                      icon: Icons.support_agent_outlined,
                      onPressed: () => context.push('/support'),
                    ),
                  ),
                ],
              ),

              if (order.isCancellable) ...[
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Cancel Order',
                  borderColor: AppColors.accent,
                  textColor: AppColors.accent,
                  onPressed: () =>
                      context.push('/cancel-order/${widget.orderId}'),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required int currentStep,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final bool isCompleted = currentStep > stepNumber;
    final bool isCurrent = currentStep == stepNumber;

    final Color dotColor = isCompleted
        ? AppColors.primary
        : (isCurrent ? AppColors.accent : AppColors.neutral);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Icon / Circle and Line
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : (isCurrent
                          ? AppColors.primaryTint20
                          : AppColors.surface),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dotColor,
                    width: isCurrent ? 2.5 : 2.0,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: AppColors.onPrimary,
                          size: 15,
                        )
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.neutralLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Step Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.itemName.copyWith(
                      fontSize: 14,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isCurrent
                          ? AppColors.textPrimary
                          : (isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
