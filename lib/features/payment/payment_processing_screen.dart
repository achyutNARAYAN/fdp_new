import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/cart_provider.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final String method;

  const PaymentProcessingScreen({
    super.key,
    required this.method,
  });

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateProcessing();
  }

  void _simulateProcessing() async {
    // 2.2 seconds simulated bank verification
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      context.go('/payment-result?status=success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    // PopScope prevents accidental back navigation during banking verification
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                Text(
                  Formatters.formatCurrency(cart.grandTotal),
                  style: AppTypography.display.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Verifying your payment...',
                  style: AppTypography.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                const Text(
                  'Please do not close or refresh the app.\nContacting bank network...',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Lock icon
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Idempotent 256-bit encrypted bank gateway',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),

                const Spacer(),

                // Prototype testing buttons to test Failure or Timeout paths
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/payment-result?status=failed'),
                      child: const Text('Simulate Failure', style: TextStyle(fontSize: 11, color: AppColors.accent)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.go('/payment-result?status=timeout'),
                      child: const Text('Simulate Timeout', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

