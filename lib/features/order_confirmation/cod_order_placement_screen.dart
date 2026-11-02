import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/badges/status_chip.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class CodOrderPlacementScreen extends ConsumerWidget {
  const CodOrderPlacementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cash on Delivery Order'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(
                label: 'Order placement is unavailable.',
                type: StatusChipType.info,
              ),
              const SizedBox(height: 16),

              const Text('Cash on Delivery', style: AppTypography.heading1),
              const SizedBox(height: 8),

              const Text(
                'Order placement will be available when the order API is connected.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),

              // Keep exact change info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 28,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exact Cash Collection',
                            style: AppTypography.itemName,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Please keep ${Formatters.formatCurrency(cart.grandTotal)} ready at handover.',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                ),
                child: Column(
                  children: [
                    _row('Shop', cart.shopName ?? ''),
                    _row('Total Items', '${cart.totalItemCount} items'),
                    _row(
                      'Delivery Address',
                      location.selectedAddress?.title ?? '',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppPrimaryButton(
                label: 'Back to cart',
                onPressed: () => context.go('/cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.itemName.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
