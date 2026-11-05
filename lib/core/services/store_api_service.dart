import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'package:fdp/features/item/models/shop_model.dart';
import 'package:fdp/features/item/models/item_model.dart';
import 'package:fdp/features/item/models/discovery_feed_model.dart';

class StoreApiService {
  final ApiClient _client;

  StoreApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  /// Hyperlocal Tiered Discovery Feed (Home Screen Feed)
  /// GET /stores/discovery/feed?lng={lng}&lat={lat}&category={category}&search={search}
  Future<DiscoveryFeedModel> getDiscoveryFeed({
    required double lng,
    required double lat,
    String? category,
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'lng': lng,
      'lat': lat,
    };
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (search != null && search.isNotEmpty) qp['search'] = search;

    final res = await _client.get(
      ApiConstants.storesDiscoveryFeed,
      queryParams: qp,
    );
    if (res.data is Map<String, dynamic>) {
      return DiscoveryFeedModel.fromApi(res.data as Map<String, dynamic>);
    }
    return const DiscoveryFeedModel();
  }

  /// Fetch stores with proximity or category filter via discovery feed
  Future<List<ShopModel>> getStores({
    String? category,
    String? status,
    String? search,
    double? nearLng,
    double? nearLat,
    double? maxDistanceKm,
    bool? isAcceptingOrders,
    int? page,
    int? limit,
  }) async {
    final double lng = nearLng ?? 77.089;
    final double lat = nearLat ?? 28.490;

    final feed = await getDiscoveryFeed(
      lng: lng,
      lat: lat,
      category: category,
      search: search,
    );

    return feed.allStores;
  }

  /// Get single store public profile
  /// GET /stores/customer/{id}
  Future<ShopModel?> getStoreById(String idOrCode) async {
    final res = await _client.get(ApiConstants.storeDetails(idOrCode));
    if (res.data is Map<String, dynamic>) {
      return ShopModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid store response');
  }

  /// Fetch store active menu populated with items and unit pricing
  /// GET /stores/customer/{id}/menu
  Future<List<ItemModel>> getStoreMenu(
    String storeIdOrCode, {
    required String storeName,
    String? category,
    String? dietaryType,
    bool? isInStock,
    String? search,
    String? highlightItemId,
  }) async {
    final qp = <String, dynamic>{};
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (dietaryType != null && dietaryType.isNotEmpty) {
      qp['dietaryType'] = dietaryType;
    }
    if (isInStock != null) qp['isInStock'] = isInStock;
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (highlightItemId != null && highlightItemId.isNotEmpty) {
      qp['highlightItemId'] = highlightItemId;
    }

    final res = await _client.get(
      ApiConstants.storeMenu(storeIdOrCode),
      queryParams: qp.isNotEmpty ? qp : null,
    );

    List<dynamic> itemsList = [];
    if (res.data is List) {
      itemsList = res.data as List;
    } else if (res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      final possible = map['items'] ?? map['menu'] ?? map['data'];
      if (possible is List) itemsList = possible;
    }

    return itemsList
        .map(
          (e) => ItemModel.fromStoreMenuItemApi(
            e as Map<String, dynamic>,
            storeId: storeIdOrCode,
            storeName: storeName,
          ),
        )
        .toList();
  }

  /// Global dish search across stores (Shop-wise grouped)
  /// GET /stores/customer/search
  Future<List<ShopWiseSearchResult>> searchShopWiseDishes({
    required String query,
    double? lng,
    double? lat,
    String? category,
    String? dietaryType,
  }) async {
    final qp = <String, dynamic>{
      'query': query,
      'lng': lng ?? 77.089,
      'lat': lat ?? 28.490,
    };
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (dietaryType != null && dietaryType.isNotEmpty) {
      qp['dietaryType'] = dietaryType;
    }

    final res = await _client.get(
      ApiConstants.storesCustomerSearch,
      queryParams: qp,
    );
    if (res.data is List) {
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ShopWiseSearchResult.fromApi(e))
          .toList();
    }
    return const [];
  }

  /// Search dishes across stores
  Future<List<dynamic>> searchDishes({
    required String query,
    double? lat,
    double? lng,
  }) async {
    return await searchShopWiseDishes(query: query, lat: lat, lng: lng);
  }
}

final storeApiService = StoreApiService();
