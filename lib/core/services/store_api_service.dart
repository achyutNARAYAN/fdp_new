import '../network/api_client.dart';
import 'package:fdp/features/item/models/shop_model.dart';
import 'package:fdp/features/item/models/item_model.dart';

class StoreApiService {
  final ApiClient _client;

  StoreApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  /// Fetch stores with proximity or category filter
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

    dynamic responseData;
    try {
      final res = await _client.get(
        '/stores/customer',
        queryParams: qp.isNotEmpty ? qp : null,
      );
      responseData = res.data;
    } catch (_) {
      final res = await _client.get(
        '/stores',
        queryParams: qp.isNotEmpty ? qp : null,
      );
      responseData = res.data;
    }

    if (responseData is List) {
      return responseData
          .map((e) => ShopModel.fromApiJson(e as Map<String, dynamic>))
          .toList();
    }
    if (responseData is Map<String, dynamic>) {
      final list = responseData['stores'] ??
          responseData['data'] ??
          responseData['results'];
      if (list is List) {
        return list
            .map((e) => ShopModel.fromApiJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return <ShopModel>[];
  }

  /// Get single store by ID or code (e.g. STR-2026-0001)
  Future<ShopModel?> getStoreById(String idOrCode) async {
    final res = await _client.get('/stores/$idOrCode');
    if (res.data is Map<String, dynamic>) {
      return ShopModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid store response');
  }

  /// Fetch store active menu populated with catalog items and unit pricing
  Future<List<ItemModel>> getStoreMenu(
    String storeIdOrCode, {
    required String storeName,
  }) async {
    dynamic responseData;
    try {
      final res = await _client.get('/stores/customer/$storeIdOrCode/menu');
      responseData = res.data;
    } catch (_) {
      final res = await _client.get('/stores/$storeIdOrCode/menu');
      responseData = res.data;
    }

    List<dynamic> itemsList = [];
    if (responseData is List) {
      itemsList = responseData;
    } else if (responseData is Map<String, dynamic>) {
      final possible = responseData['menu'] ??
          responseData['items'] ??
          responseData['data'];
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

  /// Global dish search across stores with optional coordinates
  Future<List<dynamic>> searchDishes({
    required String query,
    double? lat,
    double? lng,
  }) async {
    final qp = <String, dynamic>{'q': query};
    if (lat != null) qp['lat'] = lat;
    if (lng != null) qp['lng'] = lng;

    try {
      final res =
          await _client.get('/stores/customer/search', queryParams: qp);
      if (res.data is List) return res.data as List<dynamic>;
      if (res.data is Map<String, dynamic>) {
        final list = res.data['results'] ?? res.data['dishes'] ?? res.data['data'];
        if (list is List) return list;
      }
    } catch (_) {}
    return <dynamic>[];
  }

  /// 1-Tap Toggle: Open / Closed (isAcceptingOrders)
  Future<ShopModel?> toggleStoreOrders(
    String storeId,
    bool isAcceptingOrders,
  ) async {
    try {
      final res = await _client.patch(
        '/stores/$storeId/toggle-orders',
        body: {'isAcceptingOrders': isAcceptingOrders},
      );
      if (res.data is Map<String, dynamic>) {
        return ShopModel.fromApiJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// 1-Tap Toggle: In Stock / Out of Stock for individual menu item
  Future<bool> toggleMenuItemStock(
    String storeId,
    String menuItemId,
    bool isInStock,
  ) async {
    try {
      await _client.patch(
        '/stores/$storeId/menu/$menuItemId',
        body: {'isInStock': isInStock},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final storeApiService = StoreApiService();
