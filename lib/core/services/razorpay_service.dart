import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';

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
    required String shopName,
    required String gatewayOrderId,
    required int amountPaise,
    String? keyId,
    String? userEmail,
    String? userPhone,
    String? orderDescription,
  }) async {
    if (!isSupportedPlatform || _razorpay == null) {
      throw UnsupportedError('Razorpay checkout is available on Android and iOS.');
    }

    final key = keyId?.isNotEmpty == true ? keyId! : ApiConfig.razorpayKeyId;
    if (key.isEmpty || gatewayOrderId.isEmpty || amountPaise <= 0) {
      throw StateError('Payment gateway order details are incomplete.');
    }

    final digits = userPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final phone = digits.length >= 10 ? digits.substring(digits.length - 10) : null;
    final email = userEmail?.trim();

    _razorpay!.open({
      'key': key,
      'amount': amountPaise,
      'currency': 'INR',
      'name': shopName.isNotEmpty ? shopName : 'Food Delivery',
      'description': orderDescription ?? 'Sweet & Savoury Order',
      'order_id': gatewayOrderId,
      'timeout': 300,
      'prefill': {
        if (phone != null) 'contact': phone,
        if (email != null && email.contains('@')) 'email': email,
      },
      'theme': {'color': '#637A47'},
      'modal': {'confirm_close': true},
    });
  }

  void dispose() {
    _razorpay?.clear();
  }
}
