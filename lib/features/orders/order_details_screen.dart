import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/badges/order_status_badge.dart';
import '../../shared/widgets/badges/payment_status_badge.dart';
import '../../shared/widgets/badges/diet_marker.dart';
import '../../shared/widgets/buttons/app_secondary_button.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.pastOrders.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => orderState.activeOrder ?? orderState.pastOrders.first,
    );

    final bool isCancellable = order.isCancellable;
    final bool hasRefund = order.refundAmount != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #$orderId'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
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
                      Text(order.shopName, style: AppTypography.heading2),
                      OrderStatusBadge(status: order.orderStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Placed on ${Formatters.formatDate(order.createdAt)}',
                        style: AppTypography.caption,
                      ),
                      PaymentStatusBadge(status: order.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
                    const Icon(Icons.currency_exchange, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Refund Processed', style: AppTypography.itemName),
                          const SizedBox(height: 2),
                          Text(
                            'Amount: ${Formatters.formatCurrency(order.refundAmount!)} • Ref: ${order.refundReference ?? "REF_BANK_882"}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/refund-status/$orderId'),
                      child: const Text('Track', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Items List
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
                  ...order.items.map((cartItem) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DietMarker(dietType: cartItem.item.dietType),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${cartItem.quantity}x ${cartItem.item.name}', style: AppTypography.itemName.copyWith(fontSize: 14)),
                                Text(cartItem.selectedVariant.label, style: AppTypography.caption),
                                if (cartItem.cakeMessage != null)
                                  Text('Cake Message: "${cartItem.cakeMessage}"', style: AppTypography.caption),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(cartItem.totalPrice),
                            style: AppTypography.itemName.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bill Breakdown
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
                  const Text('Payment Summary', style: AppTypography.itemName),
                  const SizedBox(height: 12),
                  _billRow('Subtotal', Formatters.formatCurrency(order.subtotal)),
                  if (order.discountAmount > 0)
                    _billRow('Discount', '-${Formatters.formatCurrency(order.discountAmount)}', textColor: AppColors.accentPressed),
                  _billRow('Delivery Fee', Formatters.formatCurrency(order.deliveryFee)),
                  _billRow('Packaging Fee', Formatters.formatCurrency(order.packagingFee)),
                  _billRow('Platform Fee', Formatters.formatCurrency(order.platformFee)),
                  _billRow('Taxes (5% GST)', Formatters.formatCurrency(order.taxes)),
                  if (order.tipAmount > 0)
                    _billRow('Delivery Tip', Formatters.formatCurrency(order.tipAmount)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: AppTypography.heading2),
                      Text(Formatters.formatCurrency(order.totalAmount), style: AppTypography.price.copyWith(fontSize: 20)),
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
                    Text('Instructions: ${order.deliveryInstructions}', style: AppTypography.caption),
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
                    onPressed: () => context.push('/invoice/$orderId'),
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
                onPressed: () => context.push('/cancel-order/$orderId'),
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
