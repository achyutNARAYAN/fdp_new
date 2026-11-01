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
  final double mrp;
  final bool isDefault;

  const ItemVariant({
    required this.id,
    required this.label,
    required this.price,
    required this.mrp,
    this.isDefault = false,
  });

  double get discountPercent => mrp > price ? (((mrp - price) / mrp) * 100).roundToDouble() : 0;
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
  final String category; // 'Sweets', 'Ice Cream', 'Cakes', 'Desserts', 'Snacks', etc.
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
  final int maxQuantity;

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
    this.availability = ItemAvailability.available,
    this.isPerishable = false,
    this.storageNote,
    this.shelfLife,
    this.ingredients = const [],
    this.allergens = const [],
    this.allowsCakeMessage = false,
    this.allowsEgglessToggle = false,
    this.customizationGroups = const [],
    this.maxQuantity = 10,
  });

  ItemVariant get defaultVariant =>
      variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);

  double get price => defaultVariant.price;
  double get mrp => defaultVariant.mrp;
  double get discountPercent => defaultVariant.discountPercent;

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
        return DietType.veg;
    }
  }

  static String _formatCategory(String? cat) {
    if (cat == null) return 'Sweets';
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
    String shopId = 'STR-2026-0001',
    String shopName = 'Bikaner Sweet House',
  }) {
    final List<dynamic>? allowedUnits = json['allowedUnits'] as List<dynamic>?;
    final List<ItemVariant> variantsList = [];

    if (allowedUnits != null && allowedUnits.isNotEmpty) {
      for (int i = 0; i < allowedUnits.length; i++) {
        final unitStr = allowedUnits[i].toString();
        final label = ApiConfig.formatMeasurementUnit(unitStr);
        // Default base price if not mapped in store menu
        final double basePrice = (i == 0) ? 350.0 : (350.0 * (i + 1) * 0.85);
        variantsList.add(
          ItemVariant(
            id: 'v_${json['_id']}_$unitStr',
            label: label,
            price: basePrice,
            mrp: (basePrice * 1.15).roundToDouble(),
            isDefault: i == 0,
          ),
        );
      }
    } else {
      variantsList.add(
        const ItemVariant(
          id: 'v_default',
          label: '500 g',
          price: 350.0,
          mrp: 400.0,
          isDefault: true,
        ),
      );
    }

    final cat = json['category']?.toString();
    final isIceCreamOrCold = cat == 'ICE_CREAM' || cat == 'KULFI';

    return ItemModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? json['code']?.toString() ?? '',
      shopId: shopId,
      shopName: shopName,
      name: json['name']?.toString() ?? 'Artisanal Delicacy',
      hindiName: json['hindiName']?.toString(),
      description: json['description']?.toString() ?? 'Handcrafted with traditional ingredients.',
      imageUrl: json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28',
      category: _formatCategory(cat),
      dietType: _parseDietType(json['dietaryType']?.toString()),
      variants: variantsList,
      availability: (json['isActive'] == false)
          ? ItemAvailability.unavailable
          : ItemAvailability.available,
      isPerishable: isIceCreamOrCold,
      storageNote: isIceCreamOrCold
          ? 'Packed in thermal insulated bag with food-grade gel pack. Freeze immediately.'
          : 'Store in a cool, dry place away from direct sunlight.',
      shelfLife: json['shelfLife']?.toString() ?? '10-15 days',
      ingredients: (json['standardIngredients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      allergens: (json['allergenTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  factory ItemModel.fromStoreMenuItemApi(
    Map<String, dynamic> json, {
    String storeName = 'Bikaner Sweet House',
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
        final unit = p['unit']?.toString() ?? 'UNIT';
        final pricePaise = p['pricePaise'];
        final double priceRupees = ApiConfig.paiseToRupees(pricePaise);

        variants.add(
          ItemVariant(
            id: p['_id']?.toString() ?? 'var_$i',
            label: ApiConfig.formatMeasurementUnit(unit),
            price: priceRupees,
            mrp: (priceRupees * 1.15).roundToDouble(),
            isDefault: i == 0,
          ),
        );
      }
    }

    if (variants.isEmpty) {
      variants.add(
        const ItemVariant(
          id: 'v_def',
          label: 'Standard',
          price: 250.0,
          mrp: 300.0,
          isDefault: true,
        ),
      );
    }

    final bool inStock = json['isInStock'] ?? true;
    final cat = catalogData['category']?.toString();
    final isIceCreamOrCold = cat == 'ICE_CREAM' || cat == 'KULFI';

    return ItemModel(
      id: catalogData['_id']?.toString() ?? json['_id']?.toString() ?? '',
      shopId: json['storeId']?.toString() ?? 'STR-2026-0001',
      shopName: storeName,
      name: catalogData['name']?.toString() ?? 'Special Sweet',
      hindiName: catalogData['hindiName']?.toString(),
      description: catalogData['description']?.toString() ?? '',
      imageUrl: catalogData['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28',
      category: _formatCategory(cat),
      dietType: _parseDietType(catalogData['dietaryType']?.toString()),
      variants: variants,
      availability: inStock ? ItemAvailability.available : ItemAvailability.unavailable,
      isPerishable: isIceCreamOrCold,
      shelfLife: catalogData['shelfLife']?.toString(),
      ingredients: (catalogData['standardIngredients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      allergens: (catalogData['allergenTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
