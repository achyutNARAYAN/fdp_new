import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';
import '../../shared/widgets/buttons/app_secondary_button.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  final String status; // 'success', 'failed', 'timeout'

  const PaymentResultScreen({
    super.key,
    required this.status,
  });

  @override
  ConsumerState<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _proceedToOrderSubmission() {
    final cart = ref.read(cartProvider);
    final location = ref.read(locationProvider);

    // Place the order into Riverpod state
    final newOrder = ref.read(orderProvider.notifier).placeOrder(
          cart: cart,
          paymentMethod: PaymentMethodType.upi,
          deliveryAddress: location.selectedAddress.fullAddress,
        );

    // Clear cart once order is placed
    ref.read(cartProvider.notifier).clearCart();

    context.go('/order-request-submitted/${newOrder.orderId}');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (widget.status == 'success') {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 54, color: AppColors.onPrimary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount of ${Formatters.formatCurrency(cart.grandTotal > 0 ? cart.grandTotal : 824.50)} received securely.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                AppPrimaryButton(
                  label: 'Send Request to Shop',
                  onPressed: _proceedToOrderSubmission,
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.status == 'failed') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.accentTint12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 54, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Failed',
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your bank declined the transaction or network was interrupted. Your cart items are preserved.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Note: If any amount was debited, it will be automatically refunded by your bank within 2–4 business days.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                AppPrimaryButton(
                  label: 'Retry Payment',
                  onPressed: () => context.pushReplacement('/payment-processing?method=upi'),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Change Payment Method',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Timeout state
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_empty, size: 54, color: AppColors.neutralBorder),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Status Delayed',
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Payment status is taking longer than expected. Please do not pay again to avoid duplicate charges.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                AppPrimaryButton(
                  label: 'Check Order Status',
                  onPressed: () => context.go('/orders'),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Contact Support',
                  onPressed: () => context.push('/support'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

