import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/item/models/item_model.dart';
import 'package:fdp/features/item/models/shop_model.dart';
import 'package:fdp/features/item/models/diet_type.dart';
import 'package:fdp/features/item/providers/store_provider.dart';
import 'package:fdp/core/widgets/cards/item_card.dart';
import 'package:fdp/core/widgets/cards/shop_card.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _filterVegOnly = false;
  bool _filterFastDelivery = false;
  bool _filterTopRated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ItemModel> _getFilteredItems(List<ItemModel> sourceItems) {
    final q = widget.query.toLowerCase().trim();
    return sourceItems.where((item) {
      if (q.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesCategory = item.category.toLowerCase().contains(q);
        final matchesShop = item.shopName.toLowerCase().contains(q);
        final matchesIngredients = item.ingredients.any(
          (t) => t.toLowerCase().contains(q),
        );
        if (!matchesName &&
            !matchesCategory &&
            !matchesShop &&
            !matchesIngredients) {
          return false;
        }
      }
      if (_filterVegOnly && item.dietType != DietType.veg) return false;
      return true;
    }).toList();
  }

  List<ShopModel> _getFilteredShops(List<ShopModel> sourceShops) {
    final q = widget.query.toLowerCase().trim();
    return sourceShops.where((shop) {
      if (q.isNotEmpty) {
        final matchesName = shop.name.toLowerCase().contains(q);
        final matchesTags = shop.tags.any((c) => c.toLowerCase().contains(q));
        final matchesAddress = shop.address.toLowerCase().contains(q);
        if (!matchesName && !matchesTags && !matchesAddress) {
          return false;
        }
      }
      if (_filterTopRated && shop.rating < 4.7) return false;
      if (_filterFastDelivery && !shop.prepTimeMinutes.contains('15'))
        return false;
      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _filterVegOnly = false;
      _filterFastDelivery = false;
      _filterTopRated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(shopWiseSearchProvider(widget.query));
    if (searchAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (searchAsync.hasError) {
      return Scaffold(body: Center(child: Text(searchAsync.error.toString())));
    }
    final grouped = searchAsync.value ?? const [];
    final rawItems = grouped.expand((result) => result.matchingItems).toList();
    final rawShops = grouped.map((result) => result.store).toList();

    final items = _getFilteredItems(rawItems);
    final shops = _getFilteredShops(rawShops);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Search: "${widget.query.isNotEmpty ? widget.query : 'All Treats'}"',
        ),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3.0,
          labelColor: AppColors.textPrimary,
          labelStyle: AppTypography.itemName,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Items (${items.length})'),
            Tab(text: 'Shops (${shops.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'Pure Veg',
                  isSelected: _filterVegOnly,
                  onSelected: (val) => setState(() => _filterVegOnly = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Fast (< 25 min)',
                  isSelected: _filterFastDelivery,
                  onSelected: (val) =>
                      setState(() => _filterFastDelivery = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Rating 4.7+',
                  isSelected: _filterTopRated,
                  onSelected: (val) => setState(() => _filterTopRated = val),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.neutralBorder),
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 14, color: AppColors.textPrimary),
                      SizedBox(width: 4),
                      Text('Sort: Relevance', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Items View (2-column responsive grid)
                items.isEmpty
                    ? _buildEmptyState(
                        'No sweet items found matching your filters.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppDimensions.p16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.52,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ItemCard(
                            item: item,
                            onTap: () => context.push('/item/${item.id}'),
                          );
                        },
                      ),

                // 2. Shops View
                shops.isEmpty
                    ? _buildEmptyState(
                        'No confectionery shops found matching your filters.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.p16),
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return ShopCard(
                            shop: shop,
                            onTap: () => context.push('/shop/${shop.id}'),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryTint20,
      backgroundColor: AppColors.surface,
      checkmarkColor: AppColors.onPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.neutralBorder,
        width: 1.2,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 54, color: AppColors.neutral),
            const SizedBox(height: 16),
            const Text('No Results Found', style: AppTypography.heading2),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
