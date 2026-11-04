import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/core/widgets/badges/payment_status_badge.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class OrderDeliveredScreen extends ConsumerWidget {
  final String orderId;

  const OrderDeliveredScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    if (order == null) return const NoOrderData();
    final paymentStatus = order.paymentMethod == PaymentMethodType.cod
        ? PaymentStatus.codCollected
        : PaymentStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            children: [
              const Spacer(),

              // Delivered Header Circle
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint20,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Order Delivered!',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                'Delivered at ${Formatters.formatTime(DateTime.now())} • Enjoy your sweet treats!',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              PaymentStatusBadge(status: paymentStatus),

              const SizedBox(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                  boxShadow: AppDimensions.elevationLevel1,
                ),
                child: Column(
                  children: [
                    _row('Order ID', '#$orderId'),
                    _row('Confectionery Shop', order.shopName ?? ''),
                    _row('Items Count', '${order.items.length ?? 0} items'),
                    _row(
                      'Total Paid',
                      order == null
                          ? ''
                          : Formatters.formatCurrency(order.totalAmount),
                    ),
                    _row('Delivered To', order.deliveryAddress ?? ''),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Issue reporting window note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Freshness guarantee: You can report any item or temperature issue until ${Formatters.formatTime(DateTime.now().add(const Duration(hours: 3)))}.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Primary: Rate Order
              AppPrimaryButton(
                label: 'Rate Order & Partner',
                onPressed: () => context.push('/rate-review/$orderId'),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Report Issue',
                      icon: Icons.flag_outlined,
                      onPressed: () =>
                          context.push('/raise-ticket?orderId=$orderId'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Tax Invoice',
                      icon: Icons.receipt_outlined,
                      onPressed: () => context.push('/invoice/$orderId'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reorder Text Button
              TextButton(
                onPressed: () {
                  if (order != null && order.items.isNotEmpty) {
                    final first = order.items.first;
                    ref
                        .read(cartProvider.notifier)
                        .replaceCartWithItem(
                          item: first.item,
                          variant: first.selectedVariant,
                          quantity: first.quantity,
                        );
                    context.push('/cart');
                  }
                },
                child: const Text(
                  'Reorder These Items',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
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
