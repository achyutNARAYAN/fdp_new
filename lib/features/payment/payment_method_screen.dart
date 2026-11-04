import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentMethodType _selectedMethod = PaymentMethodType.upi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Options'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Option',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you would like to pay for your sweet treats order.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // Razorpay Card
              _buildOptionCard(
                title: 'Razorpay Online Payment',
                subtitle: 'UPI (GPay, PhonePe, Paytm), Credit/Debit Cards, NetBanking',
                type: PaymentMethodType.upi,
                icon: Icons.account_balance_wallet_outlined,
                badge: 'Test Mode: ${ApiConfig.razorpayKeyId.substring(0, 12)}...',
              ),

              const SizedBox(height: 12),

              // Cash on Delivery Card
              _buildOptionCard(
                title: 'Cash on Delivery (COD)',
                subtitle: 'Keep exact cash ready for delivery partner handover',
                type: PaymentMethodType.cod,
                icon: Icons.payments_outlined,
              ),

              const Spacer(),

              AppPrimaryButton(
                label: 'Confirm & Continue',
                onPressed: () {
                  context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required PaymentMethodType type,
    required IconData icon,
    String? badge,
  }) {
    final bool isSelected = _selectedMethod == type;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = type),
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.p16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint10 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutralLight,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: AppDimensions.elevationLevel1,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.primary : AppColors.neutral,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.itemName.copyWith(fontSize: 15),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPressed,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
