import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_model.dart';
import '../models/item_model.dart';

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
  CartNotifier() : super(const CartModel());

  /// Check if adding this item would conflict with an existing different shop
  bool canAddItem(ItemModel item) {
    if (state.isEmpty || state.shopId == null) return true;
    return state.shopId == item.shopId;
  }

  /// Add item to cart. If shop differs, throw CartConflictException
  void addItem({
    required ItemModel item,
    required ItemVariant variant,
    int quantity = 1,
    bool isEggless = false,
    String? cakeMessage,
    String? specialInstructions,
    List<ItemCustomizationOption> customizations = const [],
  }) {
    if (!canAddItem(item)) {
      throw CartConflictException(
        currentShopName: state.shopName ?? 'Current Shop',
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
  }

  /// Replace existing cart with new item from a different shop
  void replaceCartWithItem({
    required ItemModel item,
    required ItemVariant variant,
    int quantity = 1,
    bool isEggless = false,
    String? cakeMessage,
    String? specialInstructions,
    List<ItemCustomizationOption> customizations = const [],
  }) {
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
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }

    final updated = state.items.map((ci) {
      if (ci.id == cartItemId) {
        return ci.copyWith(quantity: newQuantity);
      }
      return ci;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeItem(String cartItemId) {
    final updated = state.items.where((ci) => ci.id != cartItemId).toList();
    if (updated.isEmpty) {
      state = const CartModel(); // Empty cart clears shop association
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void applyCoupon(String code, double discountAmount) {
    state = state.copyWith(
      appliedCouponCode: code,
      discountAmount: discountAmount,
    );
  }

  void removeCoupon() {
    state = state.copyWith(appliedCouponCode: null, discountAmount: 0.0);
  }

  void setDeliveryInstructions(String instructions) {
    state = state.copyWith(deliveryInstructions: instructions);
  }

  void clearCart() {
    state = const CartModel();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartModel>((ref) {
  return CartNotifier();
});
