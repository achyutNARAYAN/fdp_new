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
  final String? catalogItemId;
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
    this.catalogItemId,
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

    // 1. Parse existing pricing array if provided by backend
    final rawPricing = json['pricing'] as List<dynamic>?;
    if (rawPricing != null && rawPricing.isNotEmpty) {
      for (final p in rawPricing) {
        if (p is Map<String, dynamic>) {
          final unit = p['unit']?.toString() ?? 'PORTION';
          final paise = p['customerPricePaise'] ??
              p['pricePaise'] ??
              p['unitPricePaise'] ??
              p['price'] ??
              p['mrpPaise'] ??
              p['mrp'];
          final mrpPaise = p['mrpPaise'] ?? p['mrp'] ?? paise;
          final double price = ApiConfig.paiseToRupees(paise);
          if (price > 0) {
            final double mrp = ApiConfig.paiseToRupees(mrpPaise);
            variantsList.add(
              ItemVariant(
                id: p['_id']?.toString() ?? unit,
                unit: unit,
                label: ApiConfig.formatMeasurementUnit(unit),
                price: price,
                mrp: mrp > 0 ? mrp : null,
                isDefault: p['isDefault'] == true || variantsList.isEmpty,
              ),
            );
          }
        }
      }
    }

    // Only customer-facing prices belong in the app.
    if (variantsList.isEmpty) {
      final flatPaise = json['customerPricePaise'] ??
          json['pricePaise'] ??
          json['unitPricePaise'] ??
          json['price'] ??
          json['mrpPaise'] ??
          json['mrp'];

      final double flatPrice = ApiConfig.paiseToRupees(flatPaise);
      if (flatPrice > 0) {
        final flatUnit = json['unit']?.toString() ??
            json['baseUnit']?.toString() ??
            ((json['allowedUnits'] is List &&
                    (json['allowedUnits'] as List).isNotEmpty)
                ? (json['allowedUnits'] as List).first.toString()
                : 'PORTION');
        final flatMrpPaise = json['mrpPaise'] ?? json['mrp'] ?? flatPaise;
        final double flatMrp = ApiConfig.paiseToRupees(flatMrpPaise);

        variantsList.add(
          ItemVariant(
            id: json['_id']?.toString() ?? flatUnit,
            unit: flatUnit,
            label: ApiConfig.formatMeasurementUnit(flatUnit),
            price: flatPrice,
            mrp: flatMrp > 0 ? flatMrp : null,
            isDefault: true,
          ),
        );
      }
    }

    // 3. If still no pricing, check if allowedUnits exist with a fallback base price
    // Zero hardcoded 500.0 or 260.0 dummy prices. We strictly reflect backend data.

    final String itemId = json['_id']?.toString() ??
        json['id']?.toString() ??
        json['code']?.toString() ??
        'item_${DateTime.now().millisecondsSinceEpoch}';

    final effectiveShopId = json['storeId']?.toString() ??
        (shopId.isNotEmpty ? shopId : (json['shopId']?.toString() ?? ''));
    final effectiveShopName = json['storeName']?.toString() ??
        (shopName.isNotEmpty ? shopName : (json['shopName']?.toString() ?? ''));

    return ItemModel(
      id: itemId,
      menuItemId: itemId,
      catalogItemId: itemId,
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
    String parsedCatalogId = '';
    if (catalogObj is Map<String, dynamic>) {
      catalogData = catalogObj;
      parsedCatalogId = catalogData['_id']?.toString() ??
          catalogData['id']?.toString() ??
          '';
    } else if (catalogObj is String) {
      parsedCatalogId = catalogObj;
    }

    final List<dynamic>? pricingList =
        (json['pricing'] is List && (json['pricing'] as List).isNotEmpty)
            ? json['pricing'] as List<dynamic>
            : (catalogData['pricing'] is List
                ? catalogData['pricing'] as List<dynamic>
                : null);
    final List<ItemVariant> variants = [];

    if (pricingList != null && pricingList.isNotEmpty) {
      for (int i = 0; i < pricingList.length; i++) {
        final p = pricingList[i] as Map<String, dynamic>;
        final unit = p['unit']?.toString() ?? 'PORTION';
        final pricePaise = p['customerPricePaise'];
        final double priceRupees = ApiConfig.paiseToRupees(pricePaise);
        if (priceRupees <= 0) continue;
        final mrpPaise = p['mrpPaise'] ?? p['mrp'] ?? pricePaise;
        final double mrpRupees = ApiConfig.paiseToRupees(mrpPaise);

        variants.add(
          ItemVariant(
            id: p['_id']?.toString() ?? '${unit}_$i',
            unit: unit,
            label: ApiConfig.formatMeasurementUnit(unit),
            price: priceRupees,
            mrp: mrpRupees > 0 ? mrpRupees : null,
            isDefault: p['isDefault'] == true || variants.isEmpty,
          ),
        );
      }
    }

    // Support flat items from shop-wise search or direct item responses
    if (variants.isEmpty) {
      final singleUnit = json['unit']?.toString() ??
          json['baseUnit']?.toString() ??
          catalogData['unit']?.toString() ??
          catalogData['baseUnit']?.toString() ??
          'PORTION';
      final singlePricePaise =
          json['customerPricePaise'] ?? catalogData['customerPricePaise'];

      final double singlePrice = ApiConfig.paiseToRupees(singlePricePaise);
      if (singlePrice > 0) {
        final singleMrpPaise = json['mrpPaise'] ??
            json['mrp'] ??
            catalogData['mrpPaise'] ??
            catalogData['mrp'] ??
            singlePricePaise;
        final double singleMrp = ApiConfig.paiseToRupees(singleMrpPaise);

        variants.add(
          ItemVariant(
            id: json['menuItemId']?.toString() ??
                json['_id']?.toString() ??
                singleUnit,
            unit: singleUnit,
            label: ApiConfig.formatMeasurementUnit(singleUnit),
            price: singlePrice,
            mrp: singleMrp > 0 ? singleMrp : null,
            isDefault: true,
          ),
        );
      }
    }

    final bool inStock = json['isInStock'] != false;
    final String cat = json['category']?.toString() ??
        catalogData['category']?.toString() ??
        '';
    final isIceCreamOrCold = cat == 'ICE_CREAM' || cat == 'KULFI';
    final String name = (json['name'] != null &&
            json['name'].toString().isNotEmpty)
        ? json['name'].toString()
        : (catalogData['name']?.toString() ?? 'Traditional Sweet');
    final String desc = json['description']?.toString() ??
        catalogData['description']?.toString() ??
        '';
    final String img = json['imageUrl']?.toString() ??
        catalogData['imageUrl']?.toString() ??
        '';
    final String diet = json['dietaryType']?.toString() ??
        catalogData['dietaryType']?.toString() ??
        '';
    final String effectiveItemId = json['_id']?.toString() ??
        json['menuItemId']?.toString() ??
        catalogData['_id']?.toString() ??
        '';

    return ItemModel(
      id: effectiveItemId,
      menuItemId: json['menuItemId']?.toString() ??
          json['_id']?.toString() ??
          effectiveItemId,
      catalogItemId: parsedCatalogId.isNotEmpty ? parsedCatalogId : null,
      shopId: json['storeId']?.toString() ?? storeId,
      shopName: storeName,
      name: name,
      hindiName: json['hindiName']?.toString() ?? catalogData['hindiName']?.toString(),
      description: desc,
      imageUrl: img,
      category: _formatCategory(cat),
      dietType: _parseDietType(diet),
      variants: variants,
      availability: inStock
          ? ItemAvailability.available
          : ItemAvailability.unavailable,
      isPerishable: isIceCreamOrCold,
      shelfLife: json['shelfLife']?.toString() ?? catalogData['shelfLife']?.toString(),
      ingredients: (json['standardIngredients'] is List)
          ? (json['standardIngredients'] as List).map((e) => e.toString()).toList()
          : ((catalogData['standardIngredients'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              []),
      allergens: (json['allergenTags'] is List)
          ? (json['allergenTags'] as List).map((e) => e.toString()).toList()
          : ((catalogData['allergenTags'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              []),
      allowedUnits: (catalogData['allowedUnits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      synonyms: (catalogData['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      approxPrepTimeMinutes: (json['approxPrepTimeMinutes'] as num?)?.toInt() ??
          (catalogData['approxPrepTimeMinutes'] as num?)?.toInt(),
      spiceLevel: json['spiceLevel']?.toString() ?? catalogData['spiceLevel']?.toString(),
    );
  }
}
