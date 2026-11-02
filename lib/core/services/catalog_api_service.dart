import '../network/api_client.dart';
import '../../shared/models/item_model.dart';

class CatalogApiService {
  final ApiClient _client;

  CatalogApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  /// Fetch list of catalog items with search and filters
  Future<List<ItemModel>> getCatalogItems({
    String? category,
    String? dietaryType,
    String? search,
    bool? isFeatured,
    int? page,
    int? limit,
  }) async {
    final qp = <String, dynamic>{};
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (dietaryType != null && dietaryType.isNotEmpty)
      qp['dietaryType'] = dietaryType;
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (isFeatured != null) qp['isFeatured'] = isFeatured;

    final res = await _client.get(
      '/catalog',
      queryParams: qp.isNotEmpty ? qp : null,
    );

    if (res.data is List) {
      final list = res.data as List;
      return list
          .map((e) => ItemModel.fromCatalogApi(e as Map<String, dynamic>))
          .toList();
    }
    throw FormatException('Invalid catalog response');
  }

  /// Get single catalog item by ID or Code
  Future<ItemModel?> getCatalogItemById(String idOrCode) async {
    final res = await _client.get('/catalog/$idOrCode');
    if (res.data is Map<String, dynamic>) {
      return ItemModel.fromCatalogApi(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid catalog item response');
  }

  /// Get master taxonomy metadata (categories, units, dietary types)
  Future<Map<String, dynamic>> getCatalogMetadata() async {
    try {
      final res = await _client.get('/catalog/meta/categories');
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }
}

final catalogApiService = CatalogApiService();
