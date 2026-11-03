import '../../../core/services/catalog_api_service.dart';
import '../../../core/services/store_api_service.dart';
import '../models/item_model.dart';
import '../models/shop_model.dart';

abstract class CatalogRepository {
  Future<List<ItemModel>> getCatalogItems({String? category, String? search});
  Future<ItemModel?> getItemDetails(String id);
  Future<List<ShopModel>> getStores({String? category, String? search});
  Future<ShopModel?> getStoreDetails(String storeId);
}

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogApiService _catalogApi;
  final StoreApiService _storeApi;

  CatalogRepositoryImpl({
    CatalogApiService? catalogApi,
    StoreApiService? storeApi,
  })  : _catalogApi = catalogApi ?? catalogApiService,
        _storeApi = storeApi ?? storeApiService;

  @override
  Future<List<ItemModel>> getCatalogItems({String? category, String? search}) async {
    return await _catalogApi.getCatalogItems(category: category, search: search);
  }

  @override
  Future<ItemModel?> getItemDetails(String id) async {
    return await _catalogApi.getCatalogItemById(id);
  }

  @override
  Future<List<ShopModel>> getStores({String? category, String? search}) async {
    return await _storeApi.getStores(category: category, search: search);
  }

  @override
  Future<ShopModel?> getStoreDetails(String storeId) async {
    return await _storeApi.getStoreById(storeId);
  }
}

final catalogRepository = CatalogRepositoryImpl();
