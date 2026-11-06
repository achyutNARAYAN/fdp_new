import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/services/store_api_service.dart';
import '../../core/providers/location_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/badges/diet_marker.dart';
import '../../core/widgets/skeleton.dart';
import '../item/models/item_model.dart';
import '../item/models/shop_model.dart';
import '../item/providers/catalog_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  int _searchSeq = 0;
  String _query = '';
  bool _isLoading = false;

  List<ItemModel> _suggestedItems = [];
  List<ShopModel> _suggestedShops = [];
  List<String> _recentSearches = [];

  static const List<String> _popularKeywords = [
    'Motichoor Laddu',
    'Kaju Katli',
    'Gulab Jamun',
    'Rasgulla',
    'Sohan Papdi',
    'Peda',
    'Besan Laddu',
    'Champaran Sweets',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final list = LocalStorageService.getStringList('recent_searches') ?? [];
    if (mounted) {
      setState(() => _recentSearches = list);
    }
  }

  Future<void> _saveRecentSearch(String term) async {
    final clean = term.trim();
    if (clean.length < 2) return;
    final updated = [
      clean,
      ..._recentSearches.where((s) => s.toLowerCase() != clean.toLowerCase()),
    ].take(8).toList();

    if (mounted) {
      setState(() => _recentSearches = updated);
    }
    await LocalStorageService.setStringList('recent_searches', updated);
  }

  Future<void> _clearRecentSearches() async {
    if (mounted) {
      setState(() => _recentSearches = []);
    }
    await LocalStorageService.remove('recent_searches');
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    setState(() {
      _query = trimmed;
    });

    _debounceTimer?.cancel();

    if (trimmed.length < 2) {
      setState(() {
        _isLoading = false;
        _suggestedItems = [];
        _suggestedShops = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 350ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(trimmed);
    });
  }

  Future<void> _executeSearch(String query) async {
    final currentSeq = ++_searchSeq;
    final loc = ref.read(locationProvider);
    final coords = loc.selectedAddress?.coordinates ?? loc.currentCoordinates;

    try {
      final storesFuture = storeApiService
          .searchShopWiseDishes(
            query: query,
            lng: coords?.longitude,
            lat: coords?.latitude,
          )
          .catchError((_) => []);

      final groupedResults = await storesFuture;
      if (currentSeq != _searchSeq || !mounted) return;

      final apiStores = groupedResults.map((result) => result.store).toList();
      final matchingItems = groupedResults
          .expand((result) => result.matchingItems)
          .toList();

      final itemsMap = <String, ItemModel>{};
      for (final it in matchingItems) {
        if (it.id.isNotEmpty) itemsMap[it.id] = it;
      }

      final storesMap = <String, ShopModel>{};
      for (final s in apiStores) {
        if (s.id.isNotEmpty) storesMap[s.id] = s;
      }

      setState(() {
        _suggestedItems = itemsMap.values.toList();
        _suggestedShops = storesMap.values.toList();
        _isLoading = false;
      });

      if (itemsMap.isNotEmpty || storesMap.isNotEmpty) {
        _saveRecentSearch(query);
      }
    } catch (_) {
      if (currentSeq != _searchSeq || !mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performFullSearch(String query) {
    final clean = query.trim();
    if (clean.isNotEmpty) {
      _saveRecentSearch(clean);
      context.push('/search-results?q=${Uri.encodeComponent(clean)}');
    }
  }

  void _applyKeyword(String keyword) {
    _searchController.text = keyword;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _onSearchChanged(keyword);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.neutralBorder.withValues(alpha: 0.25),
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            cursorColor: AppColors.primary,
            textInputAction: TextInputAction.search,
            onSubmitted: _performFullSearch,
            onChanged: _onSearchChanged,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: 'Search sweets, snacks, or shops...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SearchSkeletonLoading();
    }

    if (_query.isNotEmpty) {
      return _buildSearchResults();
    }

    return _buildDefaultLanding();
  }

  Widget _buildSearchResults() {
    final hasItems = _suggestedItems.isNotEmpty;
    final hasShops = _suggestedShops.isNotEmpty;

    if (!hasItems && !hasShops) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // "See all results" quick banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _performFullSearch(_query),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryTint20,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.manage_search,
                    size: 20,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'See all results for ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: '"$_query"',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Section 1: Sweets & Treats
        if (hasItems) ...[
          _buildSectionHeader(
            title: 'SWEETS & TREATS',
            count: _suggestedItems.length,
            icon: Icons.bakery_dining_outlined,
          ),
          ..._suggestedItems.map((item) => _buildItemSuggestionTile(item)),
        ],

        // Section 2: Shops & Halwais
        if (hasShops) ...[
          const SizedBox(height: 12),
          _buildSectionHeader(
            title: 'SHOPS & HALWAIS',
            count: _suggestedShops.length,
            icon: Icons.storefront_outlined,
          ),
          ..._suggestedShops.map((shop) => _buildShopSuggestionTile(shop)),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildItemSuggestionTile(ItemModel item) {
    final defaultVariant =
        item.variants.isNotEmpty ? item.variants.first : null;
    final price = defaultVariant != null && defaultVariant.price > 0
        ? defaultVariant.price
        : item.price;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _saveRecentSearch(item.name);
          context.push('/item/${item.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildItemThumbnailFallback(),
                        )
                      : _buildItemThumbnailFallback(),
                ),
              ),
              const SizedBox(width: 12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        DietMarker(dietType: item.dietType),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTypography.itemName.copyWith(
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.shopName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.shopName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      price > 0
                          ? Formatters.formatCurrency(price)
                          : 'Explore options',
                      style: price > 0
                          ? AppTypography.price.copyWith(fontSize: 13)
                          : AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // View pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: const Text(
                  'VIEW',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopSuggestionTile(ShopModel shop) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _saveRecentSearch(shop.name);
          context.push('/shop/${shop.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shop thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: shop.imageUrl.isNotEmpty
                      ? Image.network(
                          shop.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildShopThumbnailFallback(shop.name),
                        )
                      : _buildShopThumbnailFallback(shop.name),
                ),
              ),
              const SizedBox(width: 12),

              // Shop info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shop.name,
                      style: AppTypography.itemName.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (shop.rating > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.vegGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.star,
                                  size: 9,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (shop.prepTimeMinutes.isNotEmpty) ...[
                          Text(
                            shop.prepTimeMinutes,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: AppColors.neutral,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (shop.distanceKm > 0)
                          Text(
                            '${shop.distanceKm.toStringAsFixed(1)} km',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    if (shop.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        shop.address,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: AppColors.neutral,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLanding() {
    final localCatalog = ref.watch(catalogProvider).items;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Recent Searches
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: AppTypography.heading2),
              TextButton(
                onPressed: _clearRecentSearches,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return ActionChip(
                avatar: const Icon(
                  Icons.history,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(term),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: AppColors.neutralBorder.withValues(alpha: 0.3),
                ),
                onPressed: () => _applyKeyword(term),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Popular Cravings
        const Text('Popular Cravings', style: AppTypography.heading2),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularKeywords.map((keyword) {
            return ActionChip(
              avatar: const Icon(
                Icons.trending_up,
                size: 15,
                color: AppColors.primary,
              ),
              label: Text(keyword),
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: AppColors.neutralBorder.withValues(alpha: 0.3),
              ),
              onPressed: () => _applyKeyword(keyword),
            );
          }).toList(),
        ),

        // Explore Sweets
        if (localCatalog.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Explore Popular Sweets', style: AppTypography.heading2),
          const SizedBox(height: 8),
          ...localCatalog.take(5).map((item) => _buildItemSuggestionTile(item)),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryTint20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: AppTypography.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any sweets or shops matching your query. Try checking spelling or explore popular cravings.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _popularKeywords.take(4).map((term) {
                return ActionChip(
                  label: Text(term),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _applyKeyword(term),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.background,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.neutralBorder.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemThumbnailFallback() {
    return Container(
      color: AppColors.primaryTint10,
      alignment: Alignment.center,
      child: const Icon(
        Icons.bakery_dining_outlined,
        size: 26,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildShopThumbnailFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    return Container(
      color: AppColors.primaryTint20,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
