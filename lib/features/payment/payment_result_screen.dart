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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 64,
                color: AppColors.neutral,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment status unavailable',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: 8),
              const Text(
                'The app has no payment API response to confirm this transaction.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
}
