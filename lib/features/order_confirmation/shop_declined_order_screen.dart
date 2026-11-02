import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';
import '../../shared/widgets/buttons/app_secondary_button.dart';
import '../../shared/widgets/layout/no_order_data.dart';

class ShopDeclinedOrderScreen extends ConsumerWidget {
  final String orderId;

  const ShopDeclinedOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    if (order == null) return const NoOrderData();
    final bool isPaid =
        order.paymentStatus == PaymentStatus.paid ||
        order.paymentStatus == PaymentStatus.refundInitiated;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            children: [
              const Spacer(),

              // Calm line-art illustration of empty sweet box
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_mall_directory_outlined,
                  size: 48,
                  color: AppColors.neutralBorder,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '${order.shopName ?? "The shop"} couldn’t accept your order',
                style: AppTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              const Text(
                'The kitchen is experiencing peak festival volume and cannot fulfill fresh sweets within the promised timeframe.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Payment already received card (NEVER ask customer to pay again)
              if (isPaid) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint20,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Already Received',
                              style: AppTypography.itemName,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Full reversal of ${Formatters.formatCurrency(order.totalAmount)} has been initiated to your original bank account.',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Spacer(),

              // Actions
              AppPrimaryButton(
                label: 'Choose Another Shop',
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 12),

              AppSecondaryButton(
                label: 'Back to Cart',
                onPressed: () => context.push('/cart'),
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => context.push('/support'),
                child: const Text(
                  'Contact Customer Support',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
