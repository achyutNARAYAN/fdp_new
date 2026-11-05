import '../config/api_config.dart';

/// Centralized API Constants and Route Helpers according to OpenAPI 3.0.3.
/// Strictly reflects backend specification paths with zero legacy aliases or deprecated endpoints.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => ApiConfig.baseUrl;
  static String get rootUrl => ApiConfig.rootUrl;
  static String get wsUrl => ApiConfig.wsUrl;
  static Duration get timeout => ApiConfig.timeout;

  // Razorpay Public Key
  static String get razorpayKeyId => ApiConfig.razorpayKeyId;

  // -------------------------------------------------------------
  // Tag 1: Customer Authentication
  // -------------------------------------------------------------
  static const String authRequestOtp = '/customers/auth/request-otp';
  static const String authVerifyOtp = '/customers/auth/verify-otp';
  static const String authCompleteRegistration =
      '/customers/auth/complete-registration';
  static const String authGoogle = '/customers/auth/google';
  static const String authLogout = '/customers/auth/logout';

  // -------------------------------------------------------------
  // Tag 2: Customer Profile & Addresses
  // -------------------------------------------------------------
  static const String customerProfile = '/customers/me/profile';
  static const String customerAddresses = '/customers/me/addresses';
  static String customerAddress(String addressId) =>
      '/customers/me/addresses/$addressId';
  static String customerAddressDefault(String addressId) =>
      '/customers/me/addresses/$addressId/default';

  // -------------------------------------------------------------
  // Tag 3: Store & Dish Discovery
  // -------------------------------------------------------------
  static const String storesDiscoveryFeed = '/stores/discovery/feed';
  static const String storesCustomerSearch = '/stores/customer/search';
  static const String storesCustomer = '/stores/customer';
  static String storeDetails(String storeId) => '/stores/customer/$storeId';
  static String storeMenu(String storeId) => '/stores/customer/$storeId/menu';
  static const String catalogCategories = '/catalog/meta/categories';
  static const String catalog = '/catalog';
  static String catalogItem(String itemId) => '/catalog/$itemId';

  // -------------------------------------------------------------
  // Tag 4: Shopping Cart Engine
  // -------------------------------------------------------------
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(String itemId) => '/cart/items/$itemId';
  static const String cartCoupon = '/cart/coupon';
  static const String cartTip = '/cart/tip';
  static const String cartAddress = '/cart/address';

  // -------------------------------------------------------------
  // Tag 5: Orders & Checkout Lifecycle
  // -------------------------------------------------------------
  static const String ordersCheckout = '/orders/checkout';
  static const String ordersCreate = '/orders/create';
  static const String myOrders = '/orders/my-orders';
  static String orderDetails(String orderId) => '/orders/$orderId';
  static String orderCancel(String orderId) => '/orders/$orderId/cancel';

  // -------------------------------------------------------------
  // Tag 6: Payment Gateway (Razorpay & UPI)
  // -------------------------------------------------------------
  static const String paymentsCreateOrder = '/payments/create-order';
  static const String paymentsVerify = '/payments/verify';
  static const String paymentsDoorstepQr = '/payments/doorstep-qr';

  // -------------------------------------------------------------
  // Tag 7: Real-Time Tracking & WebSocket Gateway
  // -------------------------------------------------------------
  static const String wsGateway = '/ws';

  // -------------------------------------------------------------
  // Tag 8: Reviews & Ratings
  // -------------------------------------------------------------
  static const String reviews = '/reviews';
  static String reviewOrder(String orderId) => '/reviews/order/$orderId';
  static String reviewById(String reviewId) => '/reviews/$reviewId';
  static String reviewStore(String storeId) => '/reviews/store/$storeId';
  static String reviewHelpful(String reviewId) => '/reviews/$reviewId/helpful';

  // -------------------------------------------------------------
  // Tag 9: Push Notifications & Inbox
  // -------------------------------------------------------------
  static const String notificationsDeviceToken = '/notifications/device-token';
  static const String notificationsInbox = '/notifications/inbox';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
}
