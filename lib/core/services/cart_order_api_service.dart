import '../network/api_client.dart';

class CartOrderApiService {
  final ApiClient _client;
  CartOrderApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  Future<Map<String, dynamic>> getCart() async => _map((await _client.get('/cart')).data);
  Future<Map<String, dynamic>> addItem({required String storeId, required String menuItemId, required String unit, required int quantity, String cookingInstructions = '', bool replaceCart = false}) async => _map((await _client.post('/cart/items', body: {'storeId': storeId, 'menuItemId': menuItemId, 'unit': unit, 'quantity': quantity, 'cookingInstructions': cookingInstructions, 'replaceCart': replaceCart})).data);
  Future<Map<String, dynamic>> updateItem(String id, {int? quantity, String? cookingInstructions}) async => _map((await _client.patch('/cart/items/$id', body: {'quantity': ?quantity, 'cookingInstructions': ?cookingInstructions})).data);
  Future<void> removeItem(String id) async { await _client.delete('/cart/items/$id'); }
  Future<void> clearCart() async { await _client.delete('/cart'); }
  Future<Map<String, dynamic>> applyCoupon(String code) async => _map((await _client.post('/cart/coupon', body: {'code': code})).data);
  Future<Map<String, dynamic>> removeCoupon() async => _map((await _client.delete('/cart/coupon')).data);
  Future<Map<String, dynamic>> setTip(int paise) async => _map((await _client.post('/cart/tip', body: {'tipPaise': paise})).data);
  Future<Map<String, dynamic>> setAddress(String id, String instructions) async => _map((await _client.post('/cart/address', body: {'addressId': id, 'deliveryInstructions': instructions})).data);
  Future<Map<String, dynamic>> checkout({required String paymentMode, String? addressId, String instructions = ''}) async => _map((await _client.post('/orders', body: {'paymentMode': paymentMode, 'deliveryAddressId': ?addressId, 'deliveryInstructions': instructions})).data);
  Future<List<dynamic>> getOrders({int page = 1, int limit = 20, String? status}) async => (await _client.get('/orders/my-orders', queryParams: {'page': page, 'limit': limit, 'status': ?status})).data as List<dynamic>;
  Future<Map<String, dynamic>> getOrder(String id) async => _map((await _client.get('/orders/$id')).data);
  Future<Map<String, dynamic>> cancelOrder(String id, String reason) async => _map((await _client.post('/orders/$id/cancel', body: {'reason': reason})).data);

  Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
}

final cartOrderApiService = CartOrderApiService();
