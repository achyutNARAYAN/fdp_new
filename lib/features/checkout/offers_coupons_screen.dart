import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/offer_model.dart';
import '../../shared/providers/cart_provider.dart';

class OffersCouponsScreen extends ConsumerStatefulWidget {
  const OffersCouponsScreen({super.key});

  @override
  ConsumerState<OffersCouponsScreen> createState() => _OffersCouponsScreenState();
}

class _OffersCouponsScreenState extends ConsumerState<OffersCouponsScreen> {
  final TextEditingController _couponInputController = TextEditingController();
  String? _couponError;

  void _applyCustomCode() {
    final code = _couponInputController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final found = MockData.availableOffers.firstWhere(
      (o) => o.code == code,
      orElse: () => OfferModel(
        code: code,
        title: 'Special Coupon',
        description: 'Custom discount',
        discountAmount: 50,
      ),
    );

    final cart = ref.read(cartProvider);
    if (cart.subtotal < found.minimumOrderAmount) {
      setState(() {
        _couponError = 'Requires minimum order value of ${Formatters.formatCurrency(found.minimumOrderAmount)}.';
      });
      return;
    }

    ref.read(cartProvider.notifier).applyCoupon(found.code, found.discountAmount);
    context.pop();
  }

  @override
  void dispose() {
    _couponInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final appliedCode = cart.appliedCouponCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Coupons'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code Entry Box
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                border: Border.all(
                  color: _couponError != null ? AppColors.accent : AppColors.neutralBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.confirmation_number_outlined, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _couponInputController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter promo or coupon code',
                        hintStyle: AppTypography.bodySmall,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _applyCustomCode,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            if (_couponError != null) ...[
              const SizedBox(height: 6),
              Text(
                _couponError!,
                style: AppTypography.caption.copyWith(color: AppColors.accentPressed),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Available Offers', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),

            // Coupon Cards
            ...MockData.availableOffers.map((offer) {
              final isApplied = appliedCode == offer.code;
              final isEligible = cart.subtotal >= offer.minimumOrderAmount;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(
                    color: isApplied ? AppColors.primary : AppColors.neutralLight,
                    width: isApplied ? 2.0 : 1.0,
                  ),
                  boxShadow: AppDimensions.elevationLevel1,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentTint12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_offer, color: AppColors.accent, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      offer.code,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Save ${Formatters.formatCurrency(offer.discountAmount)}',
                                      style: AppTypography.price.copyWith(
                                        color: AppColors.accentPressed,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(offer.title, style: AppTypography.itemName.copyWith(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(offer.description, style: AppTypography.caption),
                                if (!isEligible) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add ${Formatters.formatCurrency(offer.minimumOrderAmount - cart.subtotal)} more to unlock this coupon.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.accentPressed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dashed Divider & Action
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint10,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusCard)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TERMS & CONDITIONS APPLY', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          if (isApplied)
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                const Text('APPLIED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                TextButton(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                  onPressed: () => ref.read(cartProvider.notifier).removeCoupon(),
                                  child: const Text('Remove', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                                ),
                              ],
                            )
                          else
                            TextButton(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                              onPressed: isEligible
                                  ? () {
                                      ref.read(cartProvider.notifier).applyCoupon(offer.code, offer.discountAmount);
                                      context.pop();
                                    }
                                  : null,
                              child: Text(
                                'Apply Coupon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEligible ? AppColors.textPrimary : AppColors.neutral,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

