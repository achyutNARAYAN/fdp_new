import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import '../models/discovery_feed_model.dart';
import '../../../core/services/store_api_service.dart';
import '../../../core/providers/location_provider.dart';

class StoresState {
  final bool isLoading;
  final List<ShopModel> stores;
  final DiscoveryFeedModel? discoveryFeed;
  final String? errorMessage;

  const StoresState({
    this.isLoading = false,
    this.stores = const [],
    this.discoveryFeed,
    this.errorMessage,
  });

  StoresState copyWith({
    bool? isLoading,
    List<ShopModel>? stores,
    DiscoveryFeedModel? discoveryFeed,
    String? errorMessage,
  }) {
    return StoresState(
      isLoading: isLoading ?? this.isLoading,
      stores: stores ?? this.stores,
      discoveryFeed: discoveryFeed ?? this.discoveryFeed,
      errorMessage: errorMessage,
    );
  }
}

class StoresNotifier extends StateNotifier<StoresState> {
  final StoreApiService _apiService;

  StoresNotifier({StoreApiService? apiService})
      : _apiService = apiService ?? storeApiService,
        super(const StoresState()) {
    loadStores();
  }

  Future<void> loadStores({
    String? category,
    String? search,
    double? nearLng,
    double? nearLat,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      DiscoveryFeedModel? feed;
      List<ShopModel> stores = [];

      if (nearLng != null && nearLat != null) {
        try {
          feed = await _apiService.getDiscoveryFeed(
            lng: nearLng,
            lat: nearLat,
            category: category,
            search: search,
          );
          if (feed.allStores.isNotEmpty) {
            stores = feed.allStores;
          }
        } catch (_) {}
      }

      if (stores.isEmpty) {
        stores = await _apiService.getStores(
          category: category,
          search: search,
          nearLng: nearLng,
          nearLat: nearLat,
        );
      }

      // If geo-filtered query returned nothing, fetch all stores without
      // location filter so the user always sees something.
      if (stores.isEmpty && (nearLng != null || nearLat != null)) {
        stores = await _apiService.getStores(
          category: category,
          search: search,
        );
      }

      state = state.copyWith(
        isLoading: false,
        stores: stores,
        discoveryFeed: feed,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final storesProvider = StateNotifierProvider<StoresNotifier, StoresState>((
  ref,
) {
  return StoresNotifier();
});

final shopWiseSearchProvider = FutureProvider.family<List<ShopWiseSearchResult>, String>((ref, query) async {
  final location = ref.watch(locationProvider);
  final coordinates = location.selectedAddress?.coordinates ?? location.currentCoordinates;
  return storeApiService.searchShopWiseDishes(
    query: query,
    lng: coordinates?.longitude,
    lat: coordinates?.latitude,
  );
});

final storeDetailsProvider = FutureProvider.family<ShopModel, String>((ref, storeId) async {
  final cached = ref
      .watch(storesProvider)
      .stores
      .where((store) => store.id == storeId)
      .firstOrNull;
  if (cached != null) return cached;
  final store = await storeApiService.getStoreById(storeId);
  if (store == null) throw FormatException('Store not found');
  return store;
});

/// Fetches store menu items dynamically for a specific shop
final storeMenuProvider = FutureProvider.family<List<ItemModel>, String>((
  ref,
  storeId,
) async {
  final store = await ref.watch(storeDetailsProvider(storeId).future);
  final storeName = store.name;
  return await storeApiService.getStoreMenu(storeId, storeName: storeName);
});

/// Finds orderable offers for one catalog product across currently open shops.
final catalogOffersProvider = FutureProvider.family<List<ItemModel>, String>((
  ref,
  catalogItemId,
) async {
  final allStores = ref.watch(storesProvider).stores;
  final openStores = allStores.where((store) => store.isOpen).toList();
  final stores = openStores.isNotEmpty ? openStores : allStores;

  final menus = await Future.wait(
    stores.map((store) async {
      try {
        return await storeApiService.getStoreMenu(
          store.id,
          storeName: store.name,
        );
      } catch (_) {
        return <ItemModel>[];
      }
    }),
  );
  return menus
      .expand((items) => items)
      .where(
        (item) =>
            (item.id == catalogItemId ||
                item.menuItemId == catalogItemId ||
                item.catalogItemId == catalogItemId) &&
            item.variants.isNotEmpty,
      )
      .toList();
});
