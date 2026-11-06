import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class CancelOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const CancelOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends ConsumerState<CancelOrderScreen> {
  String _selectedReason = 'Placed order by mistake';

  static const List<String> _reasons = [
    'Placed order by mistake',
    'Selected wrong delivery address',
    'Delivery timeframe is too long',
    'Want to add more sweets from another shop',
    'Applied wrong coupon code',
    'Other reason',
  ];

  void _confirmCancellation(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        title: const Text(
          'Confirm Cancellation?',
          style: AppTypography.heading2,
        ),
        content: Text(
          'Are you sure you want to cancel Order #${order.orderId}?\nThis action cannot be undone.',
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
              try {
                await ref.read(orderProvider.notifier).cancelOrderApi(
                      orderId: order.orderId,
                      reason: _selectedReason,
                    );
                if (mounted) context.go('/order-details/${order.orderId}');
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not cancel order: $error')),
                  );
                }
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
    final order =
        orderState.pastOrders
            .where((o) => o.orderId == widget.orderId)
            .firstOrNull ??
        (orderState.activeOrder?.orderId == widget.orderId
            ? orderState.activeOrder
            : null);
    if (order == null) return const NoOrderData();
    final bool isPaid = order.paymentStatus == PaymentStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cancel Order'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason for Cancellation',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please tell us why you are cancelling to help our confectionery partners improve.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  // Reason Radios
                  Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCard,
                      ),
                      side: const BorderSide(color: AppColors.neutralLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: _reasons.map((r) {
                        return RadioListTile<String>(
                          value: r,
                          groupValue: _selectedReason,
                          activeColor: AppColors.primary,
                          title: Text(r, style: AppTypography.body),
                          onChanged: (val) =>
                              setState(() => _selectedReason = val!),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Refund Preview Card (Section 24 visual spec)
                  if (isPaid) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint10,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCard,
                        ),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Refund Preview',
                                  style: AppTypography.itemName,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Refund of ${Formatters.formatCurrency(order.totalAmount)} will be credited back to your original payment method. Expected in 2 business days.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom CTA Stack
          Container(
            padding: const EdgeInsets.all(AppDimensions.p16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14171A14),
                  offset: Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPrimaryButton(
                  label: 'Keep My Order',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Proceed to Cancel Order',
                  borderColor: AppColors.accent,
                  textColor: AppColors.accent,
                  onPressed: () => _confirmCancellation(order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
