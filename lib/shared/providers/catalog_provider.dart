import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import '../../core/services/catalog_api_service.dart';

class CatalogState {
  final bool isLoading;
  final List<ItemModel> items;
  final String? errorMessage;

  const CatalogState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });

  CatalogState copyWith({
    bool? isLoading,
    List<ItemModel>? items,
    String? errorMessage,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogApiService _apiService;

  CatalogNotifier({CatalogApiService? apiService})
      : _apiService = apiService ?? catalogApiService,
        super(const CatalogState()) {
    loadCatalog();
  }

  Future<void> loadCatalog({String? category, String? search, String? dietaryType}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _apiService.getCatalogItems(
        category: category,
        search: search,
        dietaryType: dietaryType,
      );
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  return CatalogNotifier();
});

final catalogItemProvider = FutureProvider.family<ItemModel?, String>((ref, idOrCode) async {
  return await catalogApiService.getCatalogItemById(idOrCode);
});

