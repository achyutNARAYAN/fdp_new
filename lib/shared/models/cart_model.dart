import 'item_model.dart';

class CartItemModel {
  final String id;
  final ItemModel item;
  final ItemVariant selectedVariant;
  final int quantity;
  final bool isEggless;
  final String? cakeMessage;
  final String? specialInstructions;
  final List<ItemCustomizationOption> selectedCustomizations;
  final bool hasPriceChanged;
  final double? oldPrice;
  final bool isAvailable;

  const CartItemModel({
    required this.id,
    required this.item,
    required this.selectedVariant,
    required this.quantity,
    this.isEggless = false,
    this.cakeMessage,
    this.specialInstructions,
    this.selectedCustomizations = const [],
    this.hasPriceChanged = false,
    this.oldPrice,
    this.isAvailable = true,
  });

  double get unitPrice {
    double addOns = selectedCustomizations.fold(
      0.0,
      (sum, opt) => sum + opt.price,
    );
    return selectedVariant.price + addOns;
  }

  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    int? quantity,
    ItemVariant? selectedVariant,
    bool? isEggless,
    String? cakeMessage,
    String? specialInstructions,
    List<ItemCustomizationOption>? selectedCustomizations,
    bool? hasPriceChanged,
    double? oldPrice,
    bool? isAvailable,
  }) {
    return CartItemModel(
      id: id,
      item: item,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      quantity: quantity ?? this.quantity,
      isEggless: isEggless ?? this.isEggless,
      cakeMessage: cakeMessage ?? this.cakeMessage,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedCustomizations:
          selectedCustomizations ?? this.selectedCustomizations,
      hasPriceChanged: hasPriceChanged ?? this.hasPriceChanged,
      oldPrice: oldPrice ?? this.oldPrice,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class CartModel {
  final String? shopId;
  final String? shopName;
  final List<CartItemModel> items;
  final String? appliedCouponCode;
  final double discountAmount;
  final double? deliveryFee;
  final double? packagingFee;
  final double? platformFee;
  final double? taxes;
  final String? deliveryInstructions;

  const CartModel({
    this.shopId,
    this.shopName,
    this.items = const [],
    this.appliedCouponCode,
    this.discountAmount = 0.0,
    this.deliveryFee,
    this.packagingFee,
    this.platformFee,
    this.taxes,
    this.deliveryInstructions,
  });

  bool get isEmpty => items.isEmpty;
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  List<CartItemModel> get readyItems =>
      items.where((i) => i.isAvailable && !i.hasPriceChanged).toList();
  List<CartItemModel> get attentionItems =>
      items.where((i) => !i.isAvailable || i.hasPriceChanged).toList();
  bool get hasIssues => attentionItems.isNotEmpty;

  bool get containsPerishable => items.any((i) => i.item.isPerishable);

  double get subtotal => items
      .where((i) => i.isAvailable)
      .fold(0.0, (sum, i) => sum + i.totalPrice);
  double get grandTotal {
    if (isEmpty) return 0.0;
    final total =
        subtotal -
        discountAmount +
        (deliveryFee ?? 0) +
        (packagingFee ?? 0) +
        (platformFee ?? 0) +
        (taxes ?? 0);
    return total > 0 ? total : 0.0;
  }

  CartModel copyWith({
    String? shopId,
    String? shopName,
    List<CartItemModel>? items,
    String? appliedCouponCode,
    double? discountAmount,
    double? deliveryFee,
    double? packagingFee,
    double? platformFee,
    double? taxes,
    String? deliveryInstructions,
  }) {
    return CartModel(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      packagingFee: packagingFee ?? this.packagingFee,
      platformFee: platformFee ?? this.platformFee,
      taxes: taxes ?? this.taxes,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    );
  }
}
