import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/core/models/address_model.dart';
import 'package:fdp/features/checkout/providers/address_provider.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        title: const Text('Delete Address?', style: AppTypography.heading2),
        content: Text('Are you sure you want to remove "${address.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(addressListProvider.notifier)
                    .deleteAddress(address.id);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not delete address: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: addresses.isEmpty
                ? const Center(
                    child: Text(
                      'No saved addresses yet',
                      style: AppTypography.bodySmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.p16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusCard,
                          ),
                          border: Border.all(color: AppColors.neutralLight),
                          boxShadow: AppDimensions.elevationLevel1,
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
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          addr.title,
                                          style: AppTypography.itemName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (addr.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTint20,
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'default') {
                                      try {
                                        await ref
                                            .read(addressListProvider.notifier)
                                            .setDefault(addr.id);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not update default address: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (val == 'delete') {
                                      _confirmDelete(context, ref, addr);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    if (!addr.isDefault)
                                      const PopupMenuItem(
                                        value: 'default',
                                        child: Text('Set as Default'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Address'),
                                    ),
                                  ],
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
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Add Address CTA (with SafeArea for mobile home bars)
          SafeArea(
            top: false,
            child: Container(
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
                label: 'Add New Address',
                icon: Icons.add,
                onPressed: () => context.push('/add-address'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
