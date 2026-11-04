import '../config/api_config.dart';

/// Centralized API Constants and Configuration
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = ApiConfig.baseUrl;
  static const String rootUrl = ApiConfig.rootUrl;
  static const Duration timeout = ApiConfig.timeout;

  // Razorpay
  static const String razorpayKeyId = ApiConfig.razorpayKeyId;

  // Endpoints
  static const String authLogin = '/customers/auth/login';
  static const String authVerifyOtp = '/customers/auth/verify-otp';
  static const String authGoogle = '/customers/auth/google';
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String cartCoupon = '/cart/coupon';
  static const String cartTip = '/cart/tip';
  static const String cartAddress = '/cart/address';
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static const String catalog = '/catalog';
  static const String stores = '/stores';
}

