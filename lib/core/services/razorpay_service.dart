import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_dimensions.dart';
import '../utils/formatters.dart';

typedef RazorpaySuccessCallback = void Function(PaymentSuccessResponse response);
typedef RazorpayErrorCallback = void Function(PaymentFailureResponse response);
typedef RazorpayWalletCallback = void Function(ExternalWalletResponse response);

class RazorpayService {
  Razorpay? _razorpay;
  RazorpaySuccessCallback? _onSuccess;
  RazorpayErrorCallback? _onError;
  RazorpayWalletCallback? _onWallet;

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  void initialize({
    required RazorpaySuccessCallback onSuccess,
    required RazorpayErrorCallback onError,
    RazorpayWalletCallback? onWallet,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _onWallet = onWallet;

    if (isSupportedPlatform) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onWallet?.call(response);
  }

  Future<void> openCheckout({
    required BuildContext context,
    required double amountRupees,
    required String shopName,
    String? userEmail,
    String? userPhone,
    String? orderDescription,
  }) async {
    final int amountPaise = ApiConfig.rupeesToPaise(amountRupees);

    final Map<String, dynamic> options = {
      'key': ApiConfig.razorpayKeyId,
      'amount': amountPaise,
      'name': shopName.isNotEmpty ? shopName : 'Mishra Ji Sweets',
      'description': orderDescription ?? 'Sweet & Savoury Order',
      'timeout': 300, // 5 minutes
      'prefill': {
        if (userPhone != null && userPhone.isNotEmpty) 'contact': userPhone,
        if (userEmail != null && userEmail.isNotEmpty) 'email': userEmail,
      },
      'theme': {
        'color': '#637A47', // AppColors.primary (Sage Green)
      },
      'modal': {
        'confirm_close': true,
      },
    };

    if (isSupportedPlatform && _razorpay != null) {
      try {
        _razorpay!.open(options);
        return;
      } catch (e) {
        debugPrint('Razorpay native open error: $e. Falling back to test checkout dialog.');
      }
    }

    // Fallback test checkout dialog for Web, macOS desktop, or unsupported platforms
    if (context.mounted) {
      _showSimulatedRazorpayDialog(
        context: context,
        amountRupees: amountRupees,
        shopName: shopName,
      );
    }
  }

  void _showSimulatedRazorpayDialog({
    required BuildContext context,
    required double amountRupees,
    required String shopName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppDimensions.p24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusBottomSheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'RAZORPAY TEST MODE',
                          style: TextStyle(
                            color: AppColors.primaryPressed,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _onError?.call(
                        PaymentFailureResponse(
                          Razorpay.PAYMENT_CANCELLED,
                          'Payment cancelled by user',
                          null,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pay ${Formatters.formatCurrency(amountRupees)}',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: 4),
              Text(
                'To $shopName • Key: ${ApiConfig.razorpayKeyId}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutralLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutralBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This test environment simulates Razorpay Gateway verification. Select an outcome below:',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Simulate Successful Payment (Success)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final String mockPaymentId =
                        'pay_rzp_test_${DateTime.now().millisecondsSinceEpoch}';
                    _onSuccess?.call(
                      PaymentSuccessResponse(
                        mockPaymentId,
                        'order_${DateTime.now().millisecondsSinceEpoch}',
                        'sig_${DateTime.now().millisecondsSinceEpoch}',
                        null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.error_outline),
                  label: const Text(
                    'Simulate Failed Payment (Failure)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _onError?.call(
                      PaymentFailureResponse(
                        Razorpay.PAYMENT_CANCELLED,
                        'Transaction failed in test mode.',
                        null,
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

  void dispose() {
    _razorpay?.clear();
  }
}

