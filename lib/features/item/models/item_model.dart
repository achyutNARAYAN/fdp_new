import 'diet_type.dart';
import '../../../core/config/api_config.dart';

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
  final String unit;
  final String label; // e.g. "250 g", "500 g", "1 kg", "1 Cup (100ml)"
  final double price;
  final double? mrp;
  final bool isDefault;

  const ItemVariant({
    required this.id,
    this.unit = '',
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
  final String menuItemId;
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
  final List<String>? _allowedUnits;
  final List<String>? _synonyms;
  final int? approxPrepTimeMinutes;
  final String? spiceLevel;
  final bool allowsCakeMessage;
  final bool allowsEgglessToggle;
  final List<ItemCustomizationGroup> customizationGroups;

  List<String> get allowedUnits => _allowedUnits ?? const [];
  List<String> get synonyms => _synonyms ?? const [];

  const ItemModel({
    required this.id,
    this.menuItemId = '',
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
    List<String> allowedUnits = const [],
    List<String> synonyms = const [],
    this.approxPrepTimeMinutes,
    this.spiceLevel,
    this.allowsCakeMessage = false,
    this.allowsEgglessToggle = false,
    this.customizationGroups = const [],
  }) : _allowedUnits = allowedUnits,
       _synonyms = synonyms;

  ItemVariant? get defaultVariant => variants.isEmpty
      ? null
      : variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);

  double get price => defaultVariant?.price ?? 0;
  double get discountPercent => defaultVariant?.discountPercent ?? 0;

  static DietType parseDietType(String? dt) {
    switch (dt?.toUpperCase()) {
      case 'PURE_VEG':
      case 'VEG':
      case 'VEGAN':
        return DietType.veg;
      case 'EGGITARIAN':
      case 'EGG':
        return DietType.egg;
      case 'NON_VEG':
        return DietType.nonVeg;
      default:
        return DietType.unknown;
    }
  }

  static DietType _parseDietType(String? dt) => parseDietType(dt);

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

    // Parse existing pricing if provided by backend
    final rawPricing = json['pricing'] as List<dynamic>?;
    if (rawPricing != null && rawPricing.isNotEmpty) {
      for (final p in rawPricing) {
        if (p is Map<String, dynamic>) {
          final unit = p['unit']?.toString() ?? 'PORTION';
          final paise = p['pricePaise'] ?? p['price'];
          final mrpPaise = p['mrpPaise'] ?? p['mrp'];
          final double price = paise is num ? ApiConfig.paiseToRupees(paise) : 150.0;
          final double? mrp = mrpPaise is num ? ApiConfig.paiseToRupees(mrpPaise) : null;
          variantsList.add(
            ItemVariant(
              id: p['_id']?.toString() ?? unit,
              unit: unit,
              label: ApiConfig.formatMeasurementUnit(unit),
              price: price > 0 ? price : 150.0,
              mrp: mrp,
              isDefault: p['isDefault'] == true || variantsList.isEmpty,
            ),
          );
        }
      }
    }

    // If no pricing array, generate realistic standard variants based on allowedUnits
    if (variantsList.isEmpty) {
      final allowed = (json['allowedUnits'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          [];

      final unitsToUse = allowed.isNotEmpty
          ? allowed
          : (isIceCreamOrCold
              ? ['TUB', 'SCOOP', 'LITRE']
              : ['QUARTER_KG', 'HALF_KG', 'KG']);

      for (int i = 0; i < unitsToUse.length; i++) {
        final u = unitsToUse[i];
        double price = 140.0;
        double mrp = 160.0;
        switch (u) {
          case 'QUARTER_KG':
            price = 140.0;
            mrp = 160.0;
            break;
          case 'HALF_KG':
            price = 260.0;
            mrp = 300.0;
            break;
          case 'KG':
            price = 500.0;
            mrp = 580.0;
            break;
          case 'PIECE':
            price = 40.0;
            mrp = 50.0;
            break;
          case 'PLATE':
          case 'PORTION':
            price = 120.0;
            mrp = 140.0;
            break;
          case 'BOX':
            price = 350.0;
            mrp = 400.0;
            break;
          case 'TUB':
            price = 220.0;
            mrp = 250.0;
            break;
          case 'SCOOP':
            price = 85.0;
            mrp = 100.0;
            break;
          case 'LITRE':
            price = 380.0;
            mrp = 440.0;
            break;
          default:
            price = 150.0;
            mrp = 180.0;
        }

        variantsList.add(
          ItemVariant(
            id: 'var_${u.toLowerCase()}',
            unit: u,
            label: ApiConfig.formatMeasurementUnit(u),
            price: price,
            mrp: mrp,
            isDefault: i == 0,
          ),
        );
      }
    }

    final String itemId = json['_id']?.toString() ??
        json['id']?.toString() ??
        json['code']?.toString() ??
        'item_${DateTime.now().millisecondsSinceEpoch}';

    final effectiveShopId = json['storeId']?.toString() ??
        (shopId.isNotEmpty ? shopId : 'STR_MISHRA_MAIN');
    final effectiveShopName = json['storeName']?.toString() ??
        (shopName.isNotEmpty ? shopName : 'Mishra Ji Sweets');

    return ItemModel(
      id: itemId,
      menuItemId: itemId,
      shopId: effectiveShopId,
      shopName: effectiveShopName,
      name: json['name']?.toString() ?? 'Traditional Sweet',
      hindiName: json['hindiName']?.toString(),
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: _formatCategory(cat),
      dietType: _parseDietType(json['dietaryType']?.toString()),
      variants: variantsList,
      availability: ItemAvailability.available,
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
      allowedUnits:
          (json['allowedUnits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      synonyms:
          (json['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      approxPrepTimeMinutes: (json['approxPrepTimeMinutes'] as num?)?.toInt(),
      spiceLevel: json['spiceLevel']?.toString(),
    );
  }

  factory ItemModel.fromStoreMenuItemApi(
    Map<String, dynamic> json, {
    String storeId = '',
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
            unit: unit,
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
      menuItemId: json['_id']?.toString() ?? '',
      shopId: json['storeId']?.toString() ?? storeId,
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
      allowedUnits:
          (catalogData['allowedUnits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      synonyms:
          (catalogData['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      approxPrepTimeMinutes: (catalogData['approxPrepTimeMinutes'] as num?)
          ?.toInt(),
      spiceLevel: catalogData['spiceLevel']?.toString(),
    );
  }
}
