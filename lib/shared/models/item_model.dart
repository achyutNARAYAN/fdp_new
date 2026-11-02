import 'diet_type.dart';
import '../../core/config/api_config.dart';

enum ItemAvailability {
  available('Available'),
  limited('Limited Stock'),
  unavailable('Out of Stock'),
  preOrderOnly('Pre-order Only');

  final String label;
  const ItemAvailability(this.label);
}

class ItemVariant {
  final String id;
  final String label; // e.g. "250 g", "500 g", "1 kg", "1 Cup (100ml)"
  final double price;
  final double? mrp;
  final bool isDefault;

  const ItemVariant({
    required this.id,
    required this.label,
    required this.price,
    this.mrp,
    this.isDefault = false,
  });

  double get discountPercent => mrp != null && mrp! > price
      ? (((mrp! - price) / mrp!) * 100).roundToDouble()
      : 0;
}

class ItemCustomizationOption {
  final String id;
  final String name;
  final double price;

  const ItemCustomizationOption({
    required this.id,
    required this.name,
    this.price = 0.0,
  });
}

class ItemCustomizationGroup {
  final String id;
  final String title;
  final bool isRequired;
  final bool allowMultiple;
  final List<ItemCustomizationOption> options;

  const ItemCustomizationGroup({
    required this.id,
    required this.title,
    this.isRequired = false,
    this.allowMultiple = false,
    required this.options,
  });
}

class ItemModel {
  final String id;
  final String shopId;
  final String shopName;
  final String name;
  final String? hindiName;
  final String description;
  final String imageUrl;
  final String
  category; // 'Sweets', 'Ice Cream', 'Cakes', 'Desserts', 'Snacks', etc.
  final DietType dietType;
  final List<ItemVariant> variants;
  final ItemAvailability availability;
  final bool isPerishable;
  final String? storageNote;
  final String? shelfLife;
  final List<String> ingredients;
  final List<String> allergens;
  final bool allowsCakeMessage;
  final bool allowsEgglessToggle;
  final List<ItemCustomizationGroup> customizationGroups;

  const ItemModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.name,
    this.hindiName,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.dietType,
    required this.variants,
    this.availability = ItemAvailability.unavailable,
    this.isPerishable = false,
    this.storageNote,
    this.shelfLife,
    this.ingredients = const [],
    this.allergens = const [],
    this.allowsCakeMessage = false,
    this.allowsEgglessToggle = false,
    this.customizationGroups = const [],
  });

  ItemVariant? get defaultVariant => variants.isEmpty
      ? null
      : variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);

  double get price => defaultVariant?.price ?? 0;
  double get discountPercent => defaultVariant?.discountPercent ?? 0;

  static DietType _parseDietType(String? dt) {
    switch (dt?.toUpperCase()) {
      case 'PURE_VEG':
      case 'VEGAN':
        return DietType.veg;
      case 'EGGITARIAN':
        return DietType.egg;
      case 'NON_VEG':
        return DietType.nonVeg;
      default:
        return DietType.unknown;
    }
  }

  static String _formatCategory(String? cat) {
    if (cat == null) return '';
    switch (cat.toUpperCase()) {
      case 'TRADITIONAL_SWEETS':
      case 'BENGALI_SWEETS':
      case 'DRY_FRUIT_SWEETS':
      case 'GHEE_SWEETS':
        return 'Sweets';
      case 'ICE_CREAM':
      case 'KULFI':
        return 'Ice Cream';
      case 'BAKERY_DESSERTS':
        return 'Cakes';
      case 'NAMKEEN_SNACKS':
      case 'CHAAT_STREET_FOOD':
      case 'STARTERS':
        return 'Snacks';
      case 'BEVERAGES':
        return 'Beverages';
      default:
        return cat.replaceAll('_', ' ');
    }
  }

  factory ItemModel.fromCatalogApi(
    Map<String, dynamic> json, {
    String shopId = '',
    String shopName = '',
  }) {
    final variantsList = <ItemVariant>[];

    final cat = json['category']?.toString();
    final isIceCreamOrCold = cat == 'ICE_CREAM' || cat == 'KULFI';

    return ItemModel(
      id:
          json['_id']?.toString() ??
          json['id']?.toString() ??
          json['code']?.toString() ??
          '',
      shopId: json['storeId']?.toString() ?? shopId,
      shopName: json['storeName']?.toString() ?? shopName,
      name: json['name']?.toString() ?? '',
      hindiName: json['hindiName']?.toString(),
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: _formatCategory(cat),
      dietType: _parseDietType(json['dietaryType']?.toString()),
      variants: variantsList,
      availability: json['isActive'] == true
          ? ItemAvailability.available
          : ItemAvailability.unavailable,
      isPerishable: isIceCreamOrCold,
      storageNote: json['storageNote']?.toString(),
      shelfLife: json['shelfLife']?.toString(),
      ingredients:
          (json['standardIngredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allergens:
          (json['allergenTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory ItemModel.fromStoreMenuItemApi(
    Map<String, dynamic> json, {
    String storeName = '',
  }) {
    final catalogObj = json['catalogItemId'];
    Map<String, dynamic> catalogData = {};
    if (catalogObj is Map<String, dynamic>) {
      catalogData = catalogObj;
    }

    final List<dynamic>? pricingList = json['pricing'] as List<dynamic>?;
    final List<ItemVariant> variants = [];

    if (pricingList != null && pricingList.isNotEmpty) {
      for (int i = 0; i < pricingList.length; i++) {
        final p = pricingList[i] as Map<String, dynamic>;
        final unit = p['unit']?.toString() ?? '';
        final pricePaise = p['pricePaise'];
        if (unit.isEmpty || pricePaise == null) continue;
        final double priceRupees = ApiConfig.paiseToRupees(pricePaise);
        final mrpPaise = p['mrpPaise'];

        variants.add(
          ItemVariant(
            id: p['_id']?.toString() ?? unit,
            label: ApiConfig.formatMeasurementUnit(unit),
            price: priceRupees,
            mrp: mrpPaise == null ? null : ApiConfig.paiseToRupees(mrpPaise),
            isDefault: p['isDefault'] == true,
          ),
        );
      }
    }

    final bool inStock = json['isInStock'] == true;
    final cat = catalogData['category']?.toString();
    final isIceCreamOrCold = cat == 'ICE_CREAM' || cat == 'KULFI';

    return ItemModel(
      id: catalogData['_id']?.toString() ?? json['_id']?.toString() ?? '',
      shopId: json['storeId']?.toString() ?? '',
      shopName: storeName,
      name: catalogData['name']?.toString() ?? '',
      hindiName: catalogData['hindiName']?.toString(),
      description: catalogData['description']?.toString() ?? '',
      imageUrl: catalogData['imageUrl']?.toString() ?? '',
      category: _formatCategory(cat),
      dietType: _parseDietType(catalogData['dietaryType']?.toString()),
      variants: variants,
      availability: inStock
          ? ItemAvailability.available
          : ItemAvailability.unavailable,
      isPerishable: isIceCreamOrCold,
      shelfLife: catalogData['shelfLife']?.toString(),
      ingredients:
          (catalogData['standardIngredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allergens:
          (catalogData['allergenTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
