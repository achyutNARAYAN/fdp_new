import '../network/api_client.dart';
import '../constants/api_constants.dart';

class CartOrderApiService {
  final ApiClient _client;

  CartOrderApiService({ApiClient? client})
      : _client = client ?? globalApiClient;

  /// 1. Fetch Current Active Cart & Pricing Waterfall
  /// GET /cart
  Future<Map<String, dynamic>> getCart() async {
    final res = await _client.get(ApiConstants.cart);
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 2. Add Item to Cart (Enforces single-restaurant rule)
  /// POST /cart/items
  Future<Map<String, dynamic>> addItem({
    required String storeId,
    required String menuItemId,
    required String unit,
    required int quantity,
    String cookingInstructions = '',
    bool replaceCart = false,
  }) async {
    final res = await _client.post(
      ApiConstants.cartItems,
      body: {
        'storeId': storeId,
        'menuItemId': menuItemId,
        'unit': unit,
        'quantity': quantity,
        if (cookingInstructions.isNotEmpty)
          'cookingInstructions': cookingInstructions,
        if (replaceCart) 'replaceCart': true,
      },
    );
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 3. Update Item Quantity or Instructions
  /// PATCH /cart/items/:itemId (Setting quantity to 0 removes the item)
  Future<Map<String, dynamic>> updateItem(
    String itemId, {
    int? quantity,
    String? cookingInstructions,
  }) async {
    final body = <String, dynamic>{};
    if (quantity != null) body['quantity'] = quantity;
    if (cookingInstructions != null) {
      body['cookingInstructions'] = cookingInstructions;
    }

    final res = await _client.patch(ApiConstants.cartItem(itemId), body: body);
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 4. Remove Item from Cart
  /// DELETE /cart/items/:itemId
  Future<void> removeItem(String itemId) async {
    await _client.delete(ApiConstants.cartItem(itemId));
  }

  /// 5. Clear Cart
  /// DELETE /cart
  Future<void> clearCart() async {
    await _client.delete(ApiConstants.cart);
  }

  /// 6. Apply Promo Coupon (e.g. WELCOME50, FLAT100, SWEET20, FREESHIP)
  /// POST /cart/coupon
  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final res = await _client.post(ApiConstants.cartCoupon, body: {'code': code});
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 7. Remove Promo Coupon
  /// DELETE /cart/coupon
  Future<Map<String, dynamic>> removeCoupon() async {
    final res = await _client.delete(ApiConstants.cartCoupon);
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 8. Set Driver Tip (paise, 0 to 50000)
  /// POST /cart/tip
  Future<Map<String, dynamic>> setTip(int tipPaise) async {
    final res = await _client.post(ApiConstants.cartTip, body: {'tipPaise': tipPaise});
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 9. Set Delivery Address & Instructions on Cart
  /// POST /cart/address
  Future<Map<String, dynamic>> setAddress(
    String addressId,
    String instructions,
  ) async {
    final res = await _client.post(
      ApiConstants.cartAddress,
      body: {'addressId': addressId, 'deliveryInstructions': instructions},
    );
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 10. Checkout From Cart (Acquires 120s cart lease lock)
  /// POST /orders/checkout
  Future<Map<String, dynamic>> checkout({
    required String paymentMode, // 'ONLINE' or 'COD'
    String? addressId,
    String instructions = '',
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'paymentMode': paymentMode,
      if (addressId != null && addressId.isNotEmpty)
        'deliveryAddressId': addressId,
      if (instructions.isNotEmpty) 'deliveryInstructions': instructions,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };

    final res = await _client.post(ApiConstants.ordersCheckout, body: body);
    return _unwrapOrder(res.data);
  }

  /// 11. Direct Order Creation / Buy Now (Flow B)
  /// POST /orders/create
  Future<Map<String, dynamic>> createDirectOrder({
    required String storeId,
    required List<Map<String, dynamic>> items,
    required String paymentMode, // 'ONLINE' or 'COD'
    String? deliveryAddressId,
    String? deliveryInstructions,
    String? couponCode,
    int? tipPaise,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'storeId': storeId,
      'items': items,
      'paymentMode': paymentMode,
      if (deliveryAddressId != null && deliveryAddressId.isNotEmpty)
        'deliveryAddressId': deliveryAddressId,
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
        'deliveryInstructions': deliveryInstructions,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      if (tipPaise != null) 'tipPaise': tipPaise,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };

    final res = await _client.post(ApiConstants.ordersCreate, body: body);
    return _unwrapOrder(res.data);
  }

  /// 12. Create Gateway Order (Razorpay)
  /// POST /payments/create-order
  Future<Map<String, dynamic>> initiatePayment(
    String orderId, {
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'orderId': orderId,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };

    final res = await _client.post(ApiConstants.paymentsCreateOrder, body: body);
    return _map(res.data);
  }

  /// 13. Verify Razorpay Payment Signature
  /// POST /payments/verify
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    final body = <String, dynamic>{
      'orderId': orderId,
      'razorpay_order_id': gatewayOrderId,
      'razorpay_payment_id': gatewayPaymentId,
      'razorpay_signature': gatewaySignature,
    };

    final res = await _client.post(ApiConstants.paymentsVerify, body: body);
    return _map(res.data);
  }

  /// 14. Generate Dynamic Doorstep UPI QR
  /// POST /payments/doorstep-qr
  Future<Map<String, dynamic>> generateDoorstepQr(String orderId) async {
    final res = await _client.post(
      ApiConstants.paymentsDoorstepQr,
      body: {'orderId': orderId},
    );
    return _map(res.data);
  }

  /// 15. Get Order Details & Live Milestones
  /// GET /orders/:orderId
  Future<Map<String, dynamic>> getOrder(String id) async {
    final res = await _client.get(ApiConstants.orderDetails(id));
    return _unwrapOrder(res.data);
  }

  /// 16. Fetch My Orders History
  /// GET /orders/my-orders
  Future<List<dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final qp = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) qp['status'] = status;

    final res = await _client.get(ApiConstants.myOrders, queryParams: qp);
    if (res.data is List) {
      return res.data as List<dynamic>;
    }
    if (res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      if (map['orders'] is List) return map['orders'] as List<dynamic>;
      if (map['data'] is List) return map['data'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  /// 17. Live Driver Location from Order
  /// GET /orders/:orderId
  Future<Map<String, dynamic>> getDriverTracking(String orderId) async {
    final orderRes = await getOrder(orderId);
    final driver = orderRes['driver'] is Map<String, dynamic>
        ? orderRes['driver'] as Map<String, dynamic>
        : <String, dynamic>{};
    final coords = driver['currentLocation'] is List
        ? driver['currentLocation'] as List
        : const [77.088, 28.489];
    return {
      'orderId': orderId,
      'status': orderRes['status'] ?? 'OUT_FOR_DELIVERY',
      'driver': driver,
      'driverLocation': {
        'longitude': coords.isNotEmpty ? coords[0] : 77.088,
        'latitude': coords.length > 1 ? coords[1] : 28.489,
      },
    };
  }

  /// 18. Cancel Order (Before Preparation)
  /// POST /orders/:orderId/cancel
  Future<Map<String, dynamic>> cancelOrder(String id, String reason) async {
    final res = await _client.post(
      ApiConstants.orderCancel(id),
      body: {'reason': reason},
    );
    return _unwrapOrder(res.data);
  }

  /// 19. Rate & Review Delivered Order
  /// POST /reviews
  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    required String comment,
    List<String>? foodTags,
    List<Map<String, dynamic>>? itemRatings,
    int? driverRating,
    List<String>? driverTags,
    String? driverComment,
  }) async {
    final body = <String, dynamic>{
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      if (foodTags != null && foodTags.isNotEmpty) 'foodTags': foodTags,
      if (itemRatings != null && itemRatings.isNotEmpty)
        'itemRatings': itemRatings,
      if (driverRating != null) 'driverRating': driverRating,
      if (driverTags != null && driverTags.isNotEmpty) 'driverTags': driverTags,
      if (driverComment != null && driverComment.isNotEmpty)
        'driverComment': driverComment,
    };

    final res = await _client.post(ApiConstants.reviews, body: body);
    return _map(res.data);
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  Map<String, dynamic> _unwrapOrder(dynamic data) {
    final map = _map(data);
    if (map.containsKey('order') && map['order'] is Map<String, dynamic>) {
      return map['order'] as Map<String, dynamic>;
    }
    return map;
  }
}

final cartOrderApiService = CartOrderApiService();
