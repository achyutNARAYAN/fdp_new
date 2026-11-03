import '../network/api_client.dart';
import '../../shared/models/shop_model.dart';
import '../../shared/models/item_model.dart';

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

    final res = await _client.get(
      '/stores',
      queryParams: qp.isNotEmpty ? qp : null,
    );

    if (res.data is List) {
      final list = res.data as List;
      return list
          .map((e) => ShopModel.fromApiJson(e as Map<String, dynamic>))
          .toList();
    }
    throw FormatException('Invalid stores response');
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
    final res = await _client.get('/stores/$storeIdOrCode/menu');
    if (res.data is List) {
      final list = res.data as List;
      return list
          .map(
            (e) => ItemModel.fromStoreMenuItemApi(
              e as Map<String, dynamic>,
              storeId: storeIdOrCode,
              storeName: storeName,
            ),
          )
          .toList();
    }
    throw FormatException('Invalid store menu response');
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
