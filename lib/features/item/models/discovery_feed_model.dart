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

  factory DiscoveryFeedModel.fromApi(Map<String, dynamic> json) {
    List<ShopModel> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => ShopModel.fromApiJson(e))
            .toList();
      }
      return const [];
    }

    return DiscoveryFeedModel(
      tier1: parseList(json['tier1']),
      tier2: parseList(json['tier2']),
      tier3: parseList(json['tier3']),
      iconicHalwais: parseList(json['iconicHalwais']),
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
    final rawStore = json['store'] is Map<String, dynamic>
        ? json['store'] as Map<String, dynamic>
        : <String, dynamic>{};

    final store = ShopModel.fromApiJson(rawStore);
    final rawItems = json['matchingItems'] is List ? json['matchingItems'] as List : const [];

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

