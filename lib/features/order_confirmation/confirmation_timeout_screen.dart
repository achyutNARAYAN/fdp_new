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

class ConfirmationTimeoutScreen extends ConsumerWidget {
  final String orderId;

  const ConfirmationTimeoutScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    final bool isPaid = order?.paymentStatus == PaymentStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            children: [
              const Spacer(),

              // Static Concrete Grey Ring with Paused Clock Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neutral, width: 8),
                ),
                child: const Icon(Icons.timer_off_outlined, size: 54, color: AppColors.neutral),
              ),

              const SizedBox(height: 24),

              const Text(
                'We couldn’t confirm your order yet.',
                style: AppTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Confirmation from ${order?.shopName ?? "the shop"} took longer than 3 minutes. The shop may be facing a sudden surge.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Payment already received card
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
                      const Icon(Icons.check_circle_outline, color: AppColors.onPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Already Received', style: AppTypography.itemName),
                            const SizedBox(height: 2),
                            Text(
                              'Please don’t pay again. If you cancel, ${Formatters.formatCurrency(order?.totalAmount ?? 824.50)} will be refunded.',
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

              // Action Buttons Stack
              AppPrimaryButton(
                label: 'Try Again (Another 3 Minutes)',
                onPressed: () {
                  ref.read(orderProvider.notifier).restartConfirmationWindow();
                  context.go('/waiting-confirmation/$orderId');
                },
              ),
              const SizedBox(height: 10),

              AppSecondaryButton(
                label: 'Choose Another Shop',
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 10),

              AppSecondaryButton(
                label: 'Cancel Order',
                borderColor: AppColors.accent,
                textColor: AppColors.accent,
                onPressed: () {
                  ref.read(orderProvider.notifier).cancelOrder(reason: 'Confirmation timed out');
                  context.go('/order-details/$orderId');
                },
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => context.push('/support'),
                child: const Text('Contact Customer Support', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

