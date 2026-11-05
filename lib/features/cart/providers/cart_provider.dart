import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_model.dart';
import '../../item/models/item_model.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/cart_order_api_service.dart';
import '../../../core/errors/api_exception.dart';

class CartConflictException implements Exception {
  final String currentShopName;
  final String newShopName;
  final ItemModel newItem;
  final ItemVariant variant;

  CartConflictException({
    required this.currentShopName,
    required this.newShopName,
    required this.newItem,
    required this.variant,
  });
}

class CartNotifier extends StateNotifier<CartModel> {
  final CartOrderApiService _api;
  String? lastError;

  CartNotifier({CartOrderApiService? api})
      : _api = api ?? cartOrderApiService,
        super(const CartModel()) {
    loadActiveCart();
  }

  /// Load active cart from backend on app / session start
  Future<void> loadActiveCart() async {
    try {
      final data = await _api.getCart();
      if (data.isNotEmpty) {
        _updateFromApi(data);
      }
    } catch (e) {
      debugPrint('No active remote cart or session not ready: $e');
    }
  }

  /// Check if adding this item would conflict with an existing different shop
  bool canAddItem(ItemModel item) {
    if (state.isEmpty || state.shopId == null || state.shopId!.isEmpty) {
      return true;
    }
    return state.shopId == item.shopId;
  }

  /// Add item to cart. If shop differs, throw CartConflictException
  Future<void> addItem({
    required ItemModel item,
    required ItemVariant variant,
    int quantity = 1,
    bool isEggless = false,
    String? cakeMessage,
    String? specialInstructions,
    List<ItemCustomizationOption> customizations = const [],
  }) async {
    if (!canAddItem(item)) {
      throw CartConflictException(
        currentShopName: state.shopName ?? 'Current Restaurant',
        newShopName: item.shopName,
        newItem: item,
        variant: variant,
      );
    }

    final existingIndex = state.items.indexWhere(
      (ci) =>
          ci.item.id == item.id &&
          ci.selectedVariant.id == variant.id &&
          ci.isEggless == isEggless &&
          ci.cakeMessage == cakeMessage,
    );

    List<CartItemModel> updatedItems = List.from(state.items);

    if (existingIndex >= 0) {
      final current = updatedItems[existingIndex];
      updatedItems[existingIndex] = current.copyWith(
        quantity: current.quantity + quantity,
      );
    } else {
      updatedItems.add(
        CartItemModel(
          id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
          item: item,
          selectedVariant: variant,
          quantity: quantity,
          isEggless: isEggless,
          cakeMessage: cakeMessage,
          specialInstructions: specialInstructions,
          selectedCustomizations: customizations,
        ),
      );
    }

    state = state.copyWith(
      shopId: item.shopId,
      shopName: item.shopName,
      items: updatedItems,
    );

    try {
      final response = await _api.addItem(
        storeId: item.shopId,
        menuItemId: item.menuItemId,
        unit: variant.unit,
        quantity: quantity,
        cookingInstructions: specialInstructions ?? '',
      );
      _updateFromApi(response);
      lastError = null;
    } on ApiException catch (error) {
      if (error.code == 'DIFFERENT_STORE_CART' ||
          error.code == 'RESTAURANT_MISMATCH' ||
          error.statusCode == 409) {
        throw CartConflictException(
          currentShopName: state.shopName ?? 'Current Restaurant',
          newShopName: item.shopName,
          newItem: item,
          variant: variant,
        );
      }
      lastError = _message(error);
    } catch (error) {
      lastError = _message(error);
    }
  }

  /// Replace existing cart with new item from a different shop
  Future<void> replaceCartWithItem({
    required ItemModel item,
    required ItemVariant variant,
    int quantity = 1,
    bool isEggless = false,
    String? cakeMessage,
    String? specialInstructions,
    List<ItemCustomizationOption> customizations = const [],
  }) async {
    state = CartModel(
      shopId: item.shopId,
      shopName: item.shopName,
      items: [
        CartItemModel(
          id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
          item: item,
          selectedVariant: variant,
          quantity: quantity,
          isEggless: isEggless,
          cakeMessage: cakeMessage,
          specialInstructions: specialInstructions,
          selectedCustomizations: customizations,
        ),
      ],
    );

    try {
      final response = await _api.addItem(
        storeId: item.shopId,
        menuItemId: item.menuItemId,
        unit: variant.unit,
        quantity: quantity,
        cookingInstructions: specialInstructions ?? '',
        replaceCart: true,
      );
      _updateFromApi(response);
      lastError = null;
    } catch (error) {
      lastError = _message(error);
    }
  }

  /// Update cart item quantity
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(cartItemId);
      return;
    }

    final updated = state.items.map((ci) {
      if (ci.id == cartItemId) {
        return ci.copyWith(quantity: newQuantity);
      }
      return ci;
    }).toList();

    state = state.copyWith(items: updated);

    // Guard: Do not send local dummy IDs to backend (avoids 404)
    if (cartItemId.startsWith('cart_')) {
      debugPrint('Skipping remote update for unsynced local cart item: $cartItemId');
      return;
    }

    try {
      final response = await _api.updateItem(cartItemId, quantity: newQuantity);
      _updateFromApi(response);
      lastError = null;
    } catch (error) {
      lastError = _message(error);
    }
  }

  /// Remove single item from cart
  Future<void> removeItem(String cartItemId) async {
    final updated = state.items.where((ci) => ci.id != cartItemId).toList();
    if (updated.isEmpty) {
      state = const CartModel();
    } else {
      state = state.copyWith(items: updated);
    }

    // Guard: Do not send local dummy IDs to backend (avoids 404)
    if (cartItemId.startsWith('cart_')) {
      debugPrint('Skipping remote delete for unsynced local cart item: $cartItemId');
      return;
    }

    try {
      await _api.removeItem(cartItemId);
      lastError = null;
    } catch (error) {
      lastError = _message(error);
    }
  }

  /// Apply promo coupon
  Future<void> applyCoupon(String code) async {
    try {
      final response = await _api.applyCoupon(code);
      _updateFromApi(response);
      lastError = null;
    } catch (error) {
      lastError = _message(error);
      rethrow;
    }
  }

  /// Remove promo coupon
  Future<void> removeCoupon() async {
    try {
      final response = await _api.removeCoupon();
      _updateFromApi(response);
      lastError = null;
    } catch (error) {
      state = state.copyWith(appliedCouponCode: null, discountAmount: 0.0);
    }
  }

  /// Set driver tip (amount in Rupees, converted to paise)
  Future<void> setTipInRupees(double rupees) async {
    try {
      final int tipPaise = ApiConfig.rupeesToPaise(rupees);
      final response = await _api.setTip(tipPaise);
      _updateFromApi(response);
      lastError = null;
    } catch (error) {
      lastError = _message(error);
    }
  }

  /// Set delivery address and instructions
  Future<void> setDeliveryAddress(String addressId, [String instructions = '']) async {
    try {
      final response = await _api.setAddress(addressId, instructions);
      _updateFromApi(response);
      lastError = null;
    } catch (error) {
      state = state.copyWith(deliveryInstructions: instructions);
      lastError = _message(error);
    }
  }

  void setDeliveryInstructions(String instructions) {
    state = state.copyWith(deliveryInstructions: instructions);
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      await _api.clearCart();
    } catch (e) {
      debugPrint('Remote clear cart error: $e');
    }
    state = const CartModel();
  }

  /// Synchronize state from backend envelope
  void _updateFromApi(Map<String, dynamic> rawData) {
    if (rawData.isEmpty) return;
    final data = (rawData.containsKey('cart') &&
            rawData['cart'] is Map<String, dynamic>)
        ? rawData['cart'] as Map<String, dynamic>
        : rawData;

    final String? storeId = data['storeId']?.toString();
    final String? storeName = data['storeName']?.toString();

    // Map backend items into CartItemModel with their genuine MongoDB _id
    List<CartItemModel> updatedItems = List.from(state.items);
    final rawItems = data['items'];

    if (rawItems is List) {
      if (rawItems.isEmpty) {
        updatedItems = const [];
      } else {
        final List<CartItemModel> mapped = [];
        for (final raw in rawItems) {
          if (raw is! Map<String, dynamic>) continue;
          final String mongoId = raw['itemId']?.toString() ??
              raw['_id']?.toString() ??
              '';
          final String mId = raw['menuItemId']?.toString() ?? '';
          final String unit = raw['unit']?.toString() ?? 'PORTION';
          final int qty = (raw['quantity'] as num?)?.toInt() ?? 1;
          final dynamic rawPricePaise = raw['unitPricePaise'] ??
              raw['pricePaise'] ??
              raw['customerPricePaise'] ??
              raw['basePricePaise'] ??
              raw['mrpPaise'] ??
              raw['mrp'] ??
              raw['price'];
          final double price = ApiConfig.paiseToRupees(rawPricePaise ?? 0);
          final String name = raw['name']?.toString() ?? '';
          final String instructions =
              raw['cookingInstructions']?.toString() ?? '';

          // Check if local cart already has this item
          final local = state.items.where((ci) =>
              (mongoId.isNotEmpty && ci.id == mongoId) ||
              (mId.isNotEmpty && ci.item.menuItemId == mId) ||
              ci.item.name == name).firstOrNull;

          if (local != null) {
            mapped.add(
              local.copyWith(
                id: mongoId.isNotEmpty ? mongoId : local.id,
                quantity: qty,
                specialInstructions: instructions.isNotEmpty
                    ? instructions
                    : local.specialInstructions,
              ),
            );
          } else {
            final variant = ItemVariant(
              id: unit,
              unit: unit,
              label: ApiConfig.formatMeasurementUnit(unit),
              price: price,
              isDefault: true,
            );

            final item = ItemModel(
              id: raw['catalogItemId']?.toString() ?? mId,
              menuItemId: mId,
              shopId: storeId ?? '',
              shopName: storeName ?? '',
              name: name,
              hindiName: raw['hindiName']?.toString(),
              description: '',
              imageUrl: raw['imageUrl']?.toString() ?? '',
              category: raw['category']?.toString() ?? '',
              dietType: ItemModel.parseDietType(raw['dietaryType']?.toString()),
              variants: [variant],
              availability: ItemAvailability.available,
            );

            mapped.add(
              CartItemModel(
                id: mongoId,
                item: item,
                selectedVariant: variant,
                quantity: qty,
                specialInstructions:
                    instructions.isNotEmpty ? instructions : null,
              ),
            );
          }
        }
        updatedItems = mapped;
      }
    }

    final pricing = data['pricing'] is Map<String, dynamic>
        ? data['pricing'] as Map<String, dynamic>
        : null;

    final appliedCoupon = data['appliedCoupon'] is Map<String, dynamic>
        ? data['appliedCoupon'] as Map<String, dynamic>
        : null;

    final deliveryAddress = data['deliveryAddress'] is Map<String, dynamic>
        ? data['deliveryAddress'] as Map<String, dynamic>
        : null;

    state = state.copyWith(
      shopId: storeId ?? state.shopId,
      shopName: storeName ?? state.shopName,
      items: updatedItems,
      appliedCouponCode:
          appliedCoupon?['code']?.toString() ?? state.appliedCouponCode,
      discountAmount: pricing != null
          ? ApiConfig.paiseToRupees(pricing['discountPaise'])
          : state.discountAmount,
      deliveryFee: pricing != null
          ? ApiConfig.paiseToRupees(pricing['deliveryFeePaise'])
          : state.deliveryFee,
      packagingFee: pricing != null
          ? ApiConfig.paiseToRupees(pricing['packagingFeePaise'])
          : state.packagingFee,
      platformFee: pricing != null
          ? ApiConfig.paiseToRupees(pricing['platformFeePaise'])
          : state.platformFee,
      taxes: pricing != null
          ? ApiConfig.paiseToRupees(
              pricing['taxesPaise'] ??
                  pricing['totalGstPaise'] ??
                  ((pricing['foodGstPaise'] ?? 0) +
                      (pricing['serviceGstPaise'] ?? 0)),
            )
          : state.taxes,
      deliveryInstructions: data['deliveryInstructions']?.toString() ??
          deliveryAddress?['deliveryInstructions']?.toString() ??
          state.deliveryInstructions,
    );
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Could not update your cart. Please try again.';
}

final cartProvider = StateNotifierProvider<CartNotifier, CartModel>((ref) {
  return CartNotifier();
});
