/// Global Application Constants
class AppConstants {
  AppConstants._();

  static const String appName = 'MishraJi Champaran Wale';
  static const String appTagline = 'Authentic Champaran Taste Delivered';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyCustomerId = 'customer_id';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keySelectedAddress = 'selected_address';

  // Pagination & Limits
  static const int defaultPageSize = 20;
  static const int maxCartItemQuantity = 50;
  static const double codMaxLimitRupees = 2000.0;
  static const int codMaxLimitPaise = 200000;

  // Assets
  static const String logoAsset = 'assets/branding/mishraji_logo.png';
}

