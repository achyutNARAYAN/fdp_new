import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/badges/order_status_badge.dart';
import 'package:fdp/core/widgets/badges/payment_status_badge.dart';
import 'package:fdp/core/widgets/badges/diet_marker.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';
import 'package:fdp/features/orders/models/order_model.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    final orderState = ref.read(orderProvider);
    final exists = orderState.pastOrders.any((o) => o.orderId == widget.orderId) ||
        orderState.activeOrder?.orderId == widget.orderId;

    if (!exists) {
      setState(() => _isLoading = true);
    }
    await ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order =
        orderState.pastOrders.where((o) => o.orderId == widget.orderId).firstOrNull ??
        (orderState.activeOrder?.orderId == widget.orderId
            ? orderState.activeOrder
            : null);

    if (order == null) {
      if (_isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      return const NoOrderData();
    }

    final bool isCancellable = order.isCancellable;
    final bool hasRefund = order.refundAmount != null;
    final bool isActive = order.orderStatus != OrderStatus.delivered &&
        order.orderStatus != OrderStatus.cancelled &&
        order.orderStatus != OrderStatus.declined &&
        order.orderStatus != OrderStatus.returned;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          order.orderNumber != null
              ? 'Order #${order.orderNumber}'
              : 'Order #${widget.orderId}',
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(orderProvider.notifier)
                .fetchOrderById(widget.orderId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Badges
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
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
                          maxLines: 1,
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
                      Expanded(
                        child: Text(
                          'Placed on ${Formatters.formatDate(order.createdAt)}',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PaymentStatusBadge(status: order.paymentStatus),
                    ],
                  ),
                  if (order.kotNumber != null &&
                      order.kotNumber!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Kitchen KOT: ${order.kotNumber}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery OTP Card (Prominently displayed)
            if (order.deliveryOtp != null &&
                order.deliveryOtp!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint20,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_rounded,
                      color: AppColors.primaryPressed,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Verification OTP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPressed,
                            ),
                          ),
                          const Text(
                            'Provide to driver upon food handover',
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
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        order.deliveryOtp!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppColors.primaryPressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Active Track Live Order CTA
            if (isActive) ...[
              AppPrimaryButton(
                label: 'Track Order & Live Milestones',
                icon: Icons.timeline_rounded,
                onPressed: () =>
                    context.push('/order-tracking/${widget.orderId}'),
              ),
              const SizedBox(height: 16),
            ],

            // Refund Section (appears ONLY when refund exists)
            if (hasRefund) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint20,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refund Initiated: ${Formatters.formatCurrency(order.refundAmount!)}',
                            style: AppTypography.itemName.copyWith(
                              color: AppColors.primaryPressed,
                            ),
                          ),
                          Text(
                            'Ref: ${order.refundReference ?? "Processing"}',
                            style: AppTypography.caption,
                          ),
                          if (order.refundEta != null)
                            Text(
                              'Expected by ${Formatters.formatDate(order.refundEta!)}',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Item Details List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Ordered', style: AppTypography.itemName),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (ci) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DietMarker(dietType: ci.item.dietType),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ci.quantity}x ${ci.item.name}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ci.selectedVariant.label,
                                  style: AppTypography.caption,
                                ),
                                if (ci.specialInstructions != null &&
                                    ci.specialInstructions!.isNotEmpty)
                                  Text(
                                    'Note: ${ci.specialInstructions}',
                                    style: AppTypography.caption.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(ci.totalPrice),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Detailed Bill Receipt
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill Breakdown', style: AppTypography.itemName),
                  const SizedBox(height: 12),
                  _billRow('Items Subtotal', Formatters.formatCurrency(order.subtotal)),
                  if (order.discountAmount > 0)
                    _billRow(
                      'Discount',
                      '-${Formatters.formatCurrency(order.discountAmount)}',
                      textColor: AppColors.primary,
                    ),
                  _billRow('Delivery Fee', Formatters.formatCurrency(order.deliveryFee)),
                  _billRow('Packaging Fee', Formatters.formatCurrency(order.packagingFee)),
                  _billRow('Platform Fee', Formatters.formatCurrency(order.platformFee)),
                  _billRow('Section 9(5) GST', Formatters.formatCurrency(order.taxes)),
                  if (order.tipAmount > 0)
                    _billRow('Rider Tip', Formatters.formatCurrency(order.tipAmount)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: AppTypography.heading2,
                      ),
                      Text(
                        Formatters.formatCurrency(order.totalAmount),
                        style: AppTypography.price.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Address', style: AppTypography.itemName),
                  const SizedBox(height: 6),
                  Text(order.deliveryAddress, style: AppTypography.bodySmall),
                  if (order.deliveryInstructions != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Instructions: ${order.deliveryInstructions}',
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions row: Invoice, Support, Cancel
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'GST Tax Invoice',
                    icon: Icons.receipt_outlined,
                    onPressed: () => context.push('/invoice/${widget.orderId}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Get Help',
                    icon: Icons.support_agent_outlined,
                    onPressed: () => context.push('/support'),
                  ),
                ),
              ],
            ),

            if (isCancellable) ...[
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Cancel Order',
                borderColor: AppColors.accent,
                textColor: AppColors.accent,
                onPressed: () =>
                    context.push('/cancel-order/${widget.orderId}'),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
