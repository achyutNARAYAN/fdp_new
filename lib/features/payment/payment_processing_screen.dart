import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PaymentProcessingScreen extends StatelessWidget {
  final String method;

  const PaymentProcessingScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTint10,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // 72px Indeterminate Sage Green Ring
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 4.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 36),

              // Amount in 32 Bold
              const Text(
                'Payment gateway unavailable',
                style: AppTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              const Text(
                'Payment cannot be verified because the payment API is not connected.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              const Spacer(),
              TextButton(
                onPressed: () => context.go('/cart'),
                child: const Text('Back to cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
