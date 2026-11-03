import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class PaymentResultScreen extends StatelessWidget {
  final String status;

  const PaymentResultScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = status.toLowerCase() == 'success';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                size: 72,
                color: isSuccess ? AppColors.primary : AppColors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Your payment was verified via Razorpay.'
                    : 'The payment could not be completed. You can try again or choose Cash on Delivery.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: isSuccess ? 'View Active Orders' : 'Retry Payment in Checkout',
                onPressed: () => context.go(isSuccess ? '/orders' : '/checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
