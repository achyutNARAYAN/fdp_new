import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/models/diet_type.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/badges/diet_marker.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';
import '../../shared/widgets/buttons/app_secondary_button.dart';

class ShopProposedChangesScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ShopProposedChangesScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<ShopProposedChangesScreen> createState() => _ShopProposedChangesScreenState();
}

class _ShopProposedChangesScreenState extends ConsumerState<ShopProposedChangesScreen> {
  bool _acceptSubstitute = true;

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    final bool isPaid = order?.paymentStatus == PaymentStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Shop Changes'),
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Needed Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentTint12,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.announcement, color: AppColors.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Action Required', style: AppTypography.itemName),
                              const SizedBox(height: 2),
                              Text(
                                '${order?.shopName ?? "Anand Sweets"} proposed modifications. This order will NEVER proceed automatically.',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card 1: Available Items
                  const Text('Available Items', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '1x Pure Desi Ghee Motichoor Ladoo (250 g)',
                            style: AppTypography.itemName,
                          ),
                        ),
                        Text(Formatters.formatCurrency(210.0), style: AppTypography.caption),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card 2: Unavailable Item
                  const Text('Unavailable Item', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentTint12,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.remove_circle_outline, color: AppColors.accent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '2x Royal Silver Kaju Katli (250 g)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Reason: Fresh evening batch sold out due to high counter rush.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card 3: Suggested Substitute
                  const Text('Suggested Substitute by Chef', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(
                        color: _acceptSubstitute ? AppColors.primary : AppColors.neutralBorder,
                        width: _acceptSubstitute ? 1.5 : 1.0,
                      ),
                      boxShadow: AppDimensions.elevationLevel1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const DietMarker(dietType: DietType.veg),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Grand Ottoman Rose Pistachio Baklava (Box of 12)',
                                style: AppTypography.itemName,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Crafted fresh with Antep pistachios and rosewater honey glaze.',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Accept this substitute?', style: TextStyle(fontWeight: FontWeight.w600)),
                            Switch(
                              value: _acceptSubstitute,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _acceptSubstitute = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Difference Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Adjusted Total', style: AppTypography.caption),
                            Text(
                              Formatters.formatCurrency((order?.totalAmount ?? 824.5) - (_acceptSubstitute ? 0 : 580)),
                              style: AppTypography.price.copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                        Text(
                          isPaid
                              ? 'Difference will be refunded to original account.'
                              : 'COD collection amount adjusted.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Sticky Footer Actions (Primary: Accept, Secondary: Cancel)
          Container(
            padding: const EdgeInsets.all(AppDimensions.p16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPrimaryButton(
                  label: 'Accept Changes & Continue',
                  onPressed: () {
                    ref.read(orderProvider.notifier).acceptProposedChanges();
                    context.go('/order-confirmed/${widget.orderId}');
                  },
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Cancel Order (Full Refund)',
                  borderColor: AppColors.accent,
                  textColor: AppColors.accent,
                  onPressed: () {
                    ref.read(orderProvider.notifier).cancelOrder(reason: 'Did not accept shop proposed item changes');
                    context.go('/order-details/${widget.orderId}');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
