import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import 'package:fdp/core/services/catalog_api_service.dart';
import 'package:fdp/core/providers/location_provider.dart';
import 'package:fdp/core/services/store_api_service.dart';
import '../models/shop_model.dart';

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
  int _loadGeneration = 0;

  CatalogNotifier({CatalogApiService? apiService})
      : _apiService = apiService ?? catalogApiService,
        super(const CatalogState()) {
    loadCatalog();
  }

  Future<void> loadCatalog({String? category, String? search, String? dietaryType}) async {
    final generation = ++_loadGeneration;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _apiService.getCatalogItems(
        category: category,
        search: search,
        dietaryType: dietaryType,
      );
      if (generation != _loadGeneration) return;
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      if (generation != _loadGeneration) return;
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

final catalogCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final metadata = await catalogApiService.getCatalogMetadata();
  final raw = metadata['categories'] ?? metadata['data'];
  if (raw is! List) return const [];
  return raw.map((entry) {
    if (entry is String) return entry;
    if (entry is Map<String, dynamic>) {
      return entry['code']?.toString() ?? entry['name']?.toString() ?? '';
    }
    return '';
  }).where((category) => category.isNotEmpty).toList();
});

final categoryStoresProvider = FutureProvider.family<List<ShopModel>, String>((ref, category) async {
  final location = ref.watch(locationProvider);
  final coordinates = location.selectedAddress?.coordinates ?? location.currentCoordinates;
  final categoryName = category.replaceAll('_', ' ');
  final storeCategory = switch (category.toUpperCase()) {
    final value when value.contains('ICE_CREAM') || value.contains('KULFI') => 'ICE_CREAM_PARLOUR',
    final value when value.contains('BAKERY') || value.contains('CAKE') || value.contains('DESSERT') => 'BAKERY_DESSERTS',
    final value when value.contains('NAMKEEN') || value.contains('SNACK') => 'SNACKS_NAMKEEN',
    final value when value.contains('BEVERAGE') || value.contains('CAFE') => 'BEVERAGES_CAFE',
    _ => 'SWEET_SHOP',
  };
  final results = await storeApiService.searchShopWiseDishes(
    query: categoryName,
    category: storeCategory,
    lng: coordinates?.longitude,
    lat: coordinates?.latitude,
  );
  return results.map((result) => result.store).toList();
});

