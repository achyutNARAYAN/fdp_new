
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

  /// Fetch stores with proximity or category filter via discovery feed,
  /// with robust fallback to /stores catalog endpoint
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
    // 1. If coordinates are provided, try Hyperlocal discovery feed first
    if (nearLng != null && nearLat != null) {
      try {
        final feed = await getDiscoveryFeed(
          lng: nearLng,
          lat: nearLat,
          category: category,
          search: search,
        );
        if (feed.allStores.isNotEmpty) {
          return feed.allStores;
        }
      } catch (_) {}
    }

    // 2. Query all catalog stores from /stores
    final qp = <String, dynamic>{};
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (nearLng != null) qp['nearLng'] = nearLng;
    if (nearLat != null) qp['nearLat'] = nearLat;
    if (maxDistanceKm != null) qp['maxDistanceKm'] = maxDistanceKm;
    if (isAcceptingOrders != null) qp['isAcceptingOrders'] = isAcceptingOrders;

    try {
      final res = await _client.get(
        '/stores',
        queryParams: qp.isNotEmpty ? qp : null,
      );

      List<dynamic> list = [];
      if (res.data is List) {
        list = res.data as List;
      } else if (res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        final possible = map['stores'] ?? map['data'] ?? map['results'];
        if (possible is List) list = possible;
      }

      if (list.isNotEmpty) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => ShopModel.fromApiJson(e))
            .toList();
      }

      // If geo-filtered query returned nothing, retry without location
      // so the user always sees the full catalog of stores.
      if (nearLng != null || nearLat != null) {
        final fallbackQp = Map<String, dynamic>.of(qp)
          ..remove('nearLng')
          ..remove('nearLat')
          ..remove('maxDistanceKm');
        final fbRes = await _client.get(
          '/stores',
          queryParams: fallbackQp.isNotEmpty ? fallbackQp : null,
        );
        List<dynamic> fbList = [];
        if (fbRes.data is List) {
          fbList = fbRes.data as List;
        } else if (fbRes.data is Map<String, dynamic>) {
          final map = fbRes.data as Map<String, dynamic>;
          final possible = map['stores'] ?? map['data'] ?? map['results'];
          if (possible is List) fbList = possible;
        }
        if (fbList.isNotEmpty) {
          return fbList
              .whereType<Map<String, dynamic>>()
              .map((e) => ShopModel.fromApiJson(e))
              .toList();
        }
      }
    } catch (_) {}

    return <ShopModel>[];
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
      'lng': lng ?? 77.088,
      'lat': lat ?? 28.489,
    };
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (dietaryType != null && dietaryType.isNotEmpty) {
      qp['dietaryType'] = dietaryType;
    }

    try {
      final res = await _client.get(
        ApiConstants.storesCustomerSearch,
        queryParams: qp,
      );

      List<dynamic> resultsList = [];
      if (res.data is List) {
        resultsList = res.data as List;
      } else if (res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        final possible = map['results'] ?? map['data'];
        if (possible is List) resultsList = possible;
      }

      return resultsList
          .whereType<Map<String, dynamic>>()
          .map((e) => ShopWiseSearchResult.fromApi(e))
          .toList();
    } catch (_) {
      return const [];
    }
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
