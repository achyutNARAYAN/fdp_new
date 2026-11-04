import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';

class OffersCouponsScreen extends ConsumerStatefulWidget {
  const OffersCouponsScreen({super.key});

  @override
  ConsumerState<OffersCouponsScreen> createState() => _OffersCouponsScreenState();
}

class _OffersCouponsScreenState extends ConsumerState<OffersCouponsScreen> {
  final TextEditingController _customCodeController = TextEditingController();

  final List<Map<String, dynamic>> _coupons = [
    {
      'code': 'MISHRA10',
      'discount': 50.0,
      'title': 'Flat ₹50 OFF',
      'description': 'Enjoy ₹50 off on authentic sweets & confectionery.',
      'minOrder': 200.0,
    },
    {
      'code': 'SWEETFEAST',
      'discount': 100.0,
      'title': '₹100 Celebration Discount',
      'description': 'Applicable on party boxes and bulk dessert orders.',
      'minOrder': 500.0,
    },
    {
      'code': 'GELATOFUN',
      'discount': 30.0,
      'title': '₹30 Gelato Treat',
      'description': 'Discount for artisanal ice-cream and cold tubs.',
      'minOrder': 150.0,
    },
  ];

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  void _apply(String code, double discount) {
    ref.read(cartProvider.notifier).applyCoupon(code, discount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon "$code" applied! Saved ${Formatters.formatCurrency(discount)}'),
        backgroundColor: AppColors.primary,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Coupons'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom coupon code input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutralBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Enter coupon code',
                          border: InputBorder.none,
                          hintStyle: AppTypography.caption,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final code = _customCodeController.text.trim().toUpperCase();
                        if (code.isNotEmpty) {
                          _apply(code, 40.0);
                        }
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('Available Coupons', style: AppTypography.heading2),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: _coupons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _coupons[index];
                    final String code = item['code'] as String;
                    final double discount = item['discount'] as double;
                    final double minOrder = item['minOrder'] as double;
                    final bool isApplied = cart.appliedCouponCode == code;
                    final bool isEligible = cart.subtotal >= minOrder;

                    return Container(
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTint20,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPressed,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (isApplied)
                                TextButton(
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).removeCoupon();
                                  },
                                  child: const Text('REMOVE', style: TextStyle(color: AppColors.accent)),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEligible ? AppColors.primary : AppColors.neutralLight,
                                    foregroundColor: isEligible ? AppColors.onPrimary : AppColors.textSecondary,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: isEligible ? () => _apply(code, discount) : null,
                                  child: const Text('APPLY'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item['title'] as String, style: AppTypography.itemName),
                          const SizedBox(height: 2),
                          Text(item['description'] as String, style: AppTypography.caption),
                          const SizedBox(height: 6),
                          Text(
                            'Valid on orders above ${Formatters.formatCurrency(minOrder)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isEligible ? AppColors.textSecondary : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
