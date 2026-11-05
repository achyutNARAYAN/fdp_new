import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';

class RazorpaySignatureHelper {
  /// Calculates HMAC-SHA256 signature for Razorpay payment verification
  static String calculateSignature({
    required String orderId,
    required String paymentId,
    String? secret,
  }) {
    final effectiveSecret = (secret != null && secret.isNotEmpty)
        ? secret
        : ApiConfig.razorpayKeySecret;
    final message = '$orderId|$paymentId';
    final hmac = Hmac(sha256, utf8.encode(effectiveSecret));
    return hmac.convert(utf8.encode(message)).toString();
  }
}

