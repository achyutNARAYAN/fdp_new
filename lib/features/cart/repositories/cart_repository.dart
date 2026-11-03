import '../../../core/services/cart_order_api_service.dart';

abstract class CartRepository {
  Future<Map<String, dynamic>> getCart();
  Future<Map<String, dynamic>> addItem({
    required String storeId,
    required String menuItemId,
    required String unit,
    required int quantity,
    String cookingInstructions = '',
    bool replaceCart = false,
  });
  Future<Map<String, dynamic>> updateItem(String id, {int? quantity, String? cookingInstructions});
  Future<void> removeItem(String id);
  Future<void> clearCart();
  Future<Map<String, dynamic>> applyCoupon(String code);
  Future<Map<String, dynamic>> removeCoupon();
  Future<Map<String, dynamic>> setTip(int paise);
  Future<Map<String, dynamic>> setAddress(String id, String instructions);
}

class CartRepositoryImpl implements CartRepository {
  final CartOrderApiService _apiService;

  CartRepositoryImpl({CartOrderApiService? apiService})
      : _apiService = apiService ?? cartOrderApiService;

  @override
  Future<Map<String, dynamic>> getCart() => _apiService.getCart();

  @override
  Future<Map<String, dynamic>> addItem({
    required String storeId,
    required String menuItemId,
    required String unit,
    required int quantity,
    String cookingInstructions = '',
    bool replaceCart = false,
  }) =>
      _apiService.addItem(
        storeId: storeId,
        menuItemId: menuItemId,
        unit: unit,
        quantity: quantity,
        cookingInstructions: cookingInstructions,
        replaceCart: replaceCart,
      );

  @override
  Future<Map<String, dynamic>> updateItem(String id, {int? quantity, String? cookingInstructions}) =>
      _apiService.updateItem(id, quantity: quantity, cookingInstructions: cookingInstructions);

  @override
  Future<void> removeItem(String id) => _apiService.removeItem(id);

  @override
  Future<void> clearCart() => _apiService.clearCart();

  @override
  Future<Map<String, dynamic>> applyCoupon(String code) => _apiService.applyCoupon(code);

  @override
  Future<Map<String, dynamic>> removeCoupon() => _apiService.removeCoupon();

  @override
  Future<Map<String, dynamic>> setTip(int paise) => _apiService.setTip(paise);

  @override
  Future<Map<String, dynamic>> setAddress(String id, String instructions) =>
      _apiService.setAddress(id, instructions);
}

final cartRepository = CartRepositoryImpl();
