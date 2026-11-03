import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final String method;

  const PaymentProcessingScreen({super.key, required this.method});

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
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

              const Text(
                'Processing Payment…',
                style: AppTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Connecting with Razorpay secure gateway (${widget.method.toUpperCase()}).\nPlease do not press back or refresh.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              const Spacer(),
              TextButton(
                onPressed: () => context.go('/checkout'),
                child: const Text('Back to checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
