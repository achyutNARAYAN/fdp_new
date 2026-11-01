import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentMethodType _selectedMethod = PaymentMethodType.upi;
  String _selectedUpiApp = 'Google Pay';

  static const List<String> _upiApps = ['Google Pay', 'PhonePe', 'Paytm', 'Any UPI ID'];

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final double maxCod = 2000.0;
    final bool isCodEligible = cart.grandTotal <= maxCod;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Options'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              children: [
                // Total to pay header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint20,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Payable', style: AppTypography.itemName),
                      Text(
                        Formatters.formatCurrency(cart.grandTotal),
                        style: AppTypography.price.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. UPI Section (2x2 Grid)
                _buildMethodCard(
                  method: PaymentMethodType.upi,
                  title: 'UPI (Fastest)',
                  subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                  icon: Icons.account_balance,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: _upiApps.map((app) {
                          final isChosen = _selectedUpiApp == app;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedMethod = PaymentMethodType.upi;
                              _selectedUpiApp = app;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isChosen ? AppColors.primaryTint20 : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isChosen ? AppColors.primary : AppColors.neutralBorder,
                                  width: isChosen ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                app,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Credit / Debit Cards
                _buildMethodCard(
                  method: PaymentMethodType.card,
                  title: 'Credit or Debit Card',
                  subtitle: 'Visa, MasterCard, Rupay, Amex',
                  icon: Icons.credit_card,
                ),

                const SizedBox(height: 12),

                // 3. Net Banking
                _buildMethodCard(
                  method: PaymentMethodType.netBanking,
                  title: 'Net Banking',
                  subtitle: 'All Indian major banks supported',
                  icon: Icons.account_balance_outlined,
                ),

                const SizedBox(height: 12),

                // 4. Wallets
                _buildMethodCard(
                  method: PaymentMethodType.wallet,
                  title: 'Mobile Wallets',
                  subtitle: 'Amazon Pay, Mobikwik, Freecharge',
                  icon: Icons.wallet_outlined,
                ),

                const SizedBox(height: 12),

                // 5. Cash on Delivery (COD)
                _buildMethodCard(
                  method: PaymentMethodType.cod,
                  title: 'Cash on Delivery (COD)',
                  subtitle: isCodEligible
                      ? 'Please keep exact change ready upon arrival.'
                      : 'COD unavailable for orders above ₹2,000.',
                  icon: Icons.currency_rupee,
                  isDisabled: !isCodEligible,
                ),
              ],
            ),
          ),

          // Bottom CTA
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
                ],
              ),
              child: AppPrimaryButton(
                label: _selectedMethod == PaymentMethodType.cod
                    ? 'Confirm COD Payment Method'
                    : 'Pay ${Formatters.formatCurrency(cart.grandTotal)}',
                onPressed: () {
                  if (_selectedMethod == PaymentMethodType.cod) {
                    context.push('/cod-placement');
                  } else {
                    context.push('/payment-processing?method=${_selectedMethod.name}');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required PaymentMethodType method,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? child,
    bool isDisabled = false,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.neutralLight
              : (isSelected ? AppColors.primaryTint10 : AppColors.surface),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutralLight,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: isDisabled ? AppColors.neutral : AppColors.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.itemName.copyWith(
                          color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: isDisabled ? AppColors.accentPressed : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<PaymentMethodType>(
                  value: method,
                  groupValue: _selectedMethod,
                  activeColor: AppColors.primary,
                  onChanged: isDisabled ? null : (val) => setState(() => _selectedMethod = val!),
                ),
              ],
            ),
            if (isSelected && child != null) child,
          ],
        ),
      ),
    );
  }
}
