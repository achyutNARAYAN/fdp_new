import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import '../../../core/services/store_api_service.dart';

class StoresState {
  final bool isLoading;
  final List<ShopModel> stores;
  final String? errorMessage;

  const StoresState({
    this.isLoading = false,
    this.stores = const [],
    this.errorMessage,
  });

  StoresState copyWith({
    bool? isLoading,
    List<ShopModel>? stores,
    String? errorMessage,
  }) {
    return StoresState(
      isLoading: isLoading ?? this.isLoading,
      stores: stores ?? this.stores,
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

  Future<void> loadStores({String? category, String? search}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final stores = await _apiService.getStores(
        category: category,
        search: search,
      );
      state = state.copyWith(isLoading: false, stores: stores);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleStoreAcceptingOrders(
    String storeId,
    bool isAccepting,
  ) async {
    final updated = await _apiService.toggleStoreOrders(storeId, isAccepting);
    if (updated != null) {
      state = state.copyWith(
        stores: state.stores.map((s) => s.id == storeId ? updated : s).toList(),
      );
    }
  }
}

final storesProvider = StateNotifierProvider<StoresNotifier, StoresState>((
  ref,
) {
  return StoresNotifier();
});

/// Fetches store menu items dynamically for a specific shop
final storeMenuProvider = FutureProvider.family<List<ItemModel>, String>((
  ref,
  storeId,
) async {
  final storeName =
      ref
          .watch(storesProvider)
          .stores
          .where((store) => store.id == storeId)
          .firstOrNull
          ?.name ??
      '';
  return await storeApiService.getStoreMenu(storeId, storeName: storeName);
});

/// Finds orderable offers for one catalog product across currently open shops.
final catalogOffersProvider = FutureProvider.family<List<ItemModel>, String>((
  ref,
  catalogItemId,
) async {
  final stores = ref
      .watch(storesProvider)
      .stores
      .where((store) => store.isOpen)
      .toList();
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
            item.id == catalogItemId &&
            item.availability == ItemAvailability.available &&
            item.variants.isNotEmpty,
      )
      .toList();
});
