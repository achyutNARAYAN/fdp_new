import '../config/api_config.dart';

/// Centralized API Constants and Configuration
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => ApiConfig.baseUrl;
  static String get rootUrl => ApiConfig.rootUrl;
  static Duration get timeout => ApiConfig.timeout;

  // Razorpay
  static String get razorpayKeyId => ApiConfig.razorpayKeyId;

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
  static const String ordersCheckout = '/orders/checkout';
  static const String ordersCreate = '/orders/create';
  static const String myOrders = '/orders/my-orders';
  static const String paymentsInitiate = '/payments/initiate';
  static const String paymentsVerify = '/payments/verify';
  static const String driversTrack = '/drivers/track';
  static const String reviews = '/reviews';
  static const String catalog = '/catalog';
  static const String stores = '/stores';
  static const String storesCustomer = '/stores/customer';
  static const String storesCustomerSearch = '/stores/customer/search';
}

