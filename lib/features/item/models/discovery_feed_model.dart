import 'shop_model.dart';
import 'item_model.dart';

/// Distance-tiered discovery feed for the Customer Mobile App
class DiscoveryFeedModel {
  final List<ShopModel> tier1; // 0 - 2 km (Fastest delivery)
  final List<ShopModel> tier2; // 2 - 4 km (Neighborhood)
  final List<ShopModel> tier3; // 4 - 8 km (Extended)
  final List<ShopModel> iconicHalwais; // Heritage sweet shops rating >= 4.5

  const DiscoveryFeedModel({
    this.tier1 = const [],
    this.tier2 = const [],
    this.tier3 = const [],
    this.iconicHalwais = const [],
  });

  /// Flat list of all unique shops across all tiers
  List<ShopModel> get allStores {
    final map = <String, ShopModel>{};
    for (final s in [...tier1, ...tier2, ...tier3, ...iconicHalwais]) {
      if (s.id.isNotEmpty && !map.containsKey(s.id)) {
        map[s.id] = s;
      }
    }
    return map.values.toList();
  }

  factory DiscoveryFeedModel.fromApi(Map<String, dynamic> rawJson) {
    final json = rawJson['data'] is Map<String, dynamic>
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    List<ShopModel> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => ShopModel.fromApiJson(e))
            .toList();
      }
      return const [];
    }

    final tiers = json['tiers'] is List
        ? (json['tiers'] as List).whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    List<ShopModel> storesFor(String tierCode) {
      final stores = <dynamic>[];
      for (final tier in tiers) {
        if (tier['tierCode'] == tierCode && tier['stores'] is List) {
          stores.addAll(tier['stores'] as List);
        }
      }
      return parseList(stores);
    }

    final tier1 = parseList(json['tier1']);
    final tier2 = parseList(json['tier2']);
    final tier3 = parseList(json['tier3']);
    final iconicHalwais = parseList(json['iconicHalwais']);

    return DiscoveryFeedModel(
      tier1: tier1.isNotEmpty ? tier1 : storesFor('UNDER_2KM'),
      tier2: tier2.isNotEmpty ? tier2 : storesFor('2_TO_4KM'),
      tier3: tier3.isNotEmpty ? tier3 : storesFor('4_TO_8KM'),
      iconicHalwais: iconicHalwais.isNotEmpty
          ? iconicHalwais
          : parseList(json['featuredTopRated']),
    );
    );
  }
}

/// Global dish search result grouped shop-wise
class ShopWiseSearchResult {
  final ShopModel store;
  final List<ItemModel> matchingItems;

  const ShopWiseSearchResult({
    required this.store,
    required this.matchingItems,
  });

  factory ShopWiseSearchResult.fromApi(Map<String, dynamic> json) {
    final storeData = json['store'] ?? json['shop'] ?? json;
    final rawStore = storeData is Map<String, dynamic>
        ? storeData
        : <String, dynamic>{};

    final store = ShopModel.fromApiJson(rawStore);
    final matchingItems = json['matchingItems'] ?? json['items'];
    final rawItems = matchingItems is List ? matchingItems : const [];

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(
          (itemJson) => ItemModel.fromStoreMenuItemApi(
            itemJson,
            storeId: store.id,
            storeName: store.name,
          ),
        )
        .toList();

    return ShopWiseSearchResult(
      store: store,
      matchingItems: items,
    );
  }
}

