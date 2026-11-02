import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/models/address_model.dart';
import '../../shared/providers/address_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class AddressSelectionScreen extends ConsumerWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressListProvider);
    final locationState = ref.watch(locationProvider);
    final selectedId = locationState.selectedAddress?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Delivery Address'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              children: [
                ...addresses.map((addr) {
                  final isSelected = addr.id == selectedId;
                  final bool isBlocked = addr.isServiceable == false;

                  return GestureDetector(
                    onTap: isBlocked
                        ? null
                        : () {
                            ref
                                .read(locationProvider.notifier)
                                .selectAddress(addr);
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? AppColors.neutralLight
                            : (isSelected
                                  ? AppColors.primaryTint10
                                  : AppColors.surface),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCard,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutralLight,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                addr.type == AddressType.home
                                    ? Icons.home_outlined
                                    : (addr.type == AddressType.work
                                          ? Icons.work_outline
                                          : Icons.place_outlined),
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(addr.title, style: AppTypography.itemName),
                              if (addr.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            addr.fullAddress,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Contact: ${addr.contactName} (${addr.contactPhone})',
                            style: AppTypography.caption,
                          ),
                          if (isBlocked) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'This shop doesn’t deliver to this address right now.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accentPressed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Add New Address Card
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppColors.neutralBorder,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: AppColors.textPrimary),
                  label: const Text(
                    'Add New Delivery Address',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => context.push('/add-address'),
                ),
              ],
            ),
          ),

          // Bottom CTA
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
            child: AppPrimaryButton(
              label: 'Deliver to Selected Address',
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
