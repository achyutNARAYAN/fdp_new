import '../network/api_client.dart';
import '../errors/api_exception.dart';

class CartOrderApiService {
  final ApiClient _client;

  CartOrderApiService({ApiClient? client})
      : _client = client ?? globalApiClient;

  /// 1. Fetch Current Active Cart
  /// GET /cart
  Future<Map<String, dynamic>> getCart() async {
    final res = await _client.get('/cart');
    final map = _map(res.data);
    // If backend returns {"cart": {...}}, unwrap it cleanly
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 2. Add Item to Cart (Flow A)
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
      '/cart/items',
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
  /// PATCH /cart/items/:itemId
  Future<Map<String, dynamic>> updateItem(
    String id, {
    int? quantity,
    String? cookingInstructions,
  }) async {
    final body = <String, dynamic>{};
    if (quantity != null) body['quantity'] = quantity;
    if (cookingInstructions != null) {
      body['cookingInstructions'] = cookingInstructions;
    }

    final res = await _client.patch('/cart/items/$id', body: body);
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 4. Remove Item from Cart
  /// DELETE /cart/items/:itemId
  Future<void> removeItem(String id) async {
    await _client.delete('/cart/items/$id');
  }

  /// 5. Clear Cart
  /// DELETE /cart
  Future<void> clearCart() async {
    await _client.delete('/cart');
  }

  /// 6. Apply Promo Coupon
  /// POST /cart/coupon
  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final res = await _client.post('/cart/coupon', body: {'code': code});
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 7. Remove Promo Coupon
  /// DELETE /cart/coupon
  Future<Map<String, dynamic>> removeCoupon() async {
    final res = await _client.delete('/cart/coupon');
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 8. Set Driver Tip (paise)
  /// POST /cart/tip
  Future<Map<String, dynamic>> setTip(int paise) async {
    final res = await _client.post('/cart/tip', body: {'tipPaise': paise});
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 9. Set Delivery Address & Instructions on Cart
  /// POST /cart/address
  Future<Map<String, dynamic>> setAddress(
    String id,
    String instructions,
  ) async {
    final res = await _client.post(
      '/cart/address',
      body: {'addressId': id, 'deliveryInstructions': instructions},
    );
    final map = _map(res.data);
    if (map.containsKey('cart') && map['cart'] is Map<String, dynamic>) {
      return map['cart'] as Map<String, dynamic>;
    }
    return map;
  }

  /// 10. Checkout From Cart (Flow A)
  /// POST /orders/checkout (with fallback to /orders)
  Future<Map<String, dynamic>> checkout({
    required String paymentMode, // 'COD' or 'ONLINE'
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

    try {
      final res = await _client.post('/orders/checkout', body: body);
      return _unwrapOrder(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Fallback for servers supporting POST /orders
        final res = await _client.post('/orders', body: body);
        return _unwrapOrder(res.data);
      }
      rethrow;
    }
  }

  /// 11. Direct Order Creation / Buy Now (Flow B)
  /// POST /orders/create (with fallback to /orders)
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

    try {
      final res = await _client.post('/orders/create', body: body);
      return _unwrapOrder(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        final res = await _client.post('/orders', body: body);
        return _unwrapOrder(res.data);
      }
      rethrow;
    }
  }

  /// 12. Initiate Online Payment
  /// POST /payments/initiate
  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    final res = await _client.post(
      '/payments/initiate',
      body: {'orderId': orderId},
    );
    return _map(res.data);
  }

  /// 13. Verify Payment Signature
  /// POST /payments/verify
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    final res = await _client.post(
      '/payments/verify',
      body: {
        'orderId': orderId,
        'gatewayOrderId': gatewayOrderId,
        'gatewayPaymentId': gatewayPaymentId,
        'gatewaySignature': gatewaySignature,
      },
    );
    return _map(res.data);
  }

  /// 14. Get Order Details & Live Milestones
  /// GET /orders/:orderId
  Future<Map<String, dynamic>> getOrder(String id) async {
    final res = await _client.get('/orders/$id');
    return _unwrapOrder(res.data);
  }

  /// 15. Fetch My Orders History
  /// GET /orders/my-orders
  Future<List<dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final qp = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) qp['status'] = status;

    final res = await _client.get('/orders/my-orders', queryParams: qp);
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

  /// 16. Live Driver GPS Telemetry
  /// GET /drivers/track/:orderId
  Future<Map<String, dynamic>> getDriverTracking(String orderId) async {
    final res = await _client.get('/drivers/track/$orderId');
    return _map(res.data);
  }

  /// 17. Cancel Order (Before Preparation)
  /// POST /orders/:orderId/cancel
  Future<Map<String, dynamic>> cancelOrder(String id, String reason) async {
    final res = await _client.post(
      '/orders/$id/cancel',
      body: {'reason': reason},
    );
    return _unwrapOrder(res.data);
  }

  /// 18. Rate & Review Order (After Delivery)
  /// POST /reviews
  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    required String comment,
    int? deliveryRating,
    List<Map<String, dynamic>>? dishRatings,
  }) async {
    final body = <String, dynamic>{
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      if (deliveryRating != null) 'deliveryRating': deliveryRating,
      if (dishRatings != null && dishRatings.isNotEmpty)
        'dishRatings': dishRatings,
    };

    final res = await _client.post('/reviews', body: body);
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
