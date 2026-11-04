import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesState {
  final Set<String> favoriteItemIds;
  final Set<String> favoriteShopIds;

  const FavoritesState({
    this.favoriteItemIds = const {},
    this.favoriteShopIds = const {},
  });

  FavoritesState copyWith({
    Set<String>? favoriteItemIds,
    Set<String>? favoriteShopIds,
  }) {
    return FavoritesState(
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
      favoriteShopIds: favoriteShopIds ?? this.favoriteShopIds,
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState());

  void toggleItemFavorite(String itemId) {
    final updated = Set<String>.from(state.favoriteItemIds);
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }
    state = state.copyWith(favoriteItemIds: updated);
  }

  void toggleShopFavorite(String shopId) {
    final updated = Set<String>.from(state.favoriteShopIds);
    if (updated.contains(shopId)) {
      updated.remove(shopId);
    } else {
      updated.add(shopId);
    }
    state = state.copyWith(favoriteShopIds: updated);
  }

  bool isItemFavorite(String itemId) => state.favoriteItemIds.contains(itemId);
  bool isShopFavorite(String shopId) => state.favoriteShopIds.contains(shopId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      return FavoritesNotifier();
    });
