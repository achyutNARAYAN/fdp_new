import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/item/models/shop_model.dart';
import 'package:fdp/features/item/models/item_model.dart';
import 'package:fdp/features/item/models/diet_type.dart';
import 'package:fdp/features/favorites/providers/favorites_provider.dart';
import 'package:fdp/features/item/providers/store_provider.dart';
import 'package:fdp/core/widgets/badges/status_chip.dart';
import 'package:fdp/core/widgets/cards/item_card.dart';

class ShopPageScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopPageScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopPageScreen> createState() => _ShopPageScreenState();
}

class _ShopPageScreenState extends ConsumerState<ShopPageScreen> {
  bool _vegOnly = false;

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(storeDetailsProvider(widget.shopId));
    final shop = shopAsync.value;
    if (shop == null) {
      return Scaffold(
        body: Center(
          child: shopAsync.hasError
              ? Text('Could not load store: ${shopAsync.error}')
              : const CircularProgressIndicator(),
        ),
      );
    }

    final favs = ref.watch(favoritesProvider);
    final isFav = favs.favoriteShopIds.contains(shop.id);

    final menuAsync = ref.watch(storeMenuProvider(widget.shopId));

    final allMenuItems = menuAsync.maybeWhen(
      data: (items) => items,
      orElse: () => <ItemModel>[],
    );

    final filteredItems = allMenuItems.where((i) {
      if (_vegOnly && i.dietType != DietType.veg) return false;
      return true;
    }).toList();
    final menuGroups = <String, List<ItemModel>>{};
    for (final item in filteredItems) {
      menuGroups.putIfAbsent(
        item.category.isEmpty ? 'Other' : item.category,
        () => <ItemModel>[],
      ).add(item);
    }
    final menuSections = <Widget>[];
    if (menuAsync.hasError) {
      menuSections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p16),
            child: Text('Could not load this menu: ${menuAsync.error}'),
          ),
        ),
      );
    } else if (menuGroups.isEmpty) {
      menuSections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p32),
            child: Center(
              child: Text(
                menuAsync.isLoading ? 'Loading menu…' : 'No menu items available.',
                style: AppTypography.bodySmall,
              ),
            ),
          ),
        ),
      );
    } else {
      for (final group in menuGroups.entries) {
        menuSections.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.p16,
                AppDimensions.p16,
                AppDimensions.p16,
                0,
              ),
              child: Text(group.key, style: AppTypography.sectionTitle),
            ),
          ),
        );
        menuSections.add(
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.p16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.52,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = group.value[index];
                return ItemCard(
                  item: item,
                  onTap: () => context.push('/item/${item.id}', extra: item),
                );
              }, childCount: group.value.length),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(storeMenuProvider(widget.shopId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sliver AppBar with Hero Image (200 high)
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.surface,
              leading: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.accent : AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(favoritesProvider.notifier)
                        .toggleShopFavorite(shop.id);
                  },
                ),
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.share_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  shop.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.primaryTint10),
                ),
              ),
            ),

            // Overlapping Info Card (Overlaps hero by 24)
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.p20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusCard,
                    ),
                    boxShadow: AppDimensions.elevationLevel2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        shop.name,
                                        style: AppTypography.heading1.copyWith(
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                    if (shop.isVerified) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.verified,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  shop.address,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (shop.status != ShopStatus.unknown)
                            _buildShopStatusBadge(shop.status),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rating, Prep time, Distance
                      if (shop.rating > 0 ||
                          shop.prepTimeMinutes.isNotEmpty ||
                          shop.distanceKm > 0)
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (shop.rating > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${shop.rating} (${shop.ratingCount}+)',
                                    style: AppTypography.itemName.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            if (shop.prepTimeMinutes.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    shop.prepTimeMinutes,
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            if (shop.distanceKm > 0)
                              Text(
                                '${shop.distanceKm} km away',
                                style: AppTypography.bodySmall,
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // Closed or Busy inline note
            if (shop.isClosed)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This shop is currently closed. You can browse their menu or schedule for tomorrow.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Veg Only Toggle & Search Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Menu Items',
                          style: AppTypography.sectionTitle,
                        ),
                        if (menuAsync.isLoading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Veg Only', style: AppTypography.bodySmall),
                        const SizedBox(width: 6),
                        Switch(
                          value: _vegOnly,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primaryTint20,
                          onChanged: (val) => setState(() => _vegOnly = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            ...menuSections,

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopStatusBadge(ShopStatus status) {
    switch (status) {
      case ShopStatus.open:
        return const StatusChip(
          label: 'Open Now',
          type: StatusChipType.success,
        );
      case ShopStatus.busy:
        return const StatusChip(label: 'Busy', type: StatusChipType.pending);
      case ShopStatus.closed:
        return const StatusChip(label: 'Closed', type: StatusChipType.info);
      case ShopStatus.temporarilyUnavailable:
        return const StatusChip(
          label: 'Unavailable',
          type: StatusChipType.error,
        );
      case ShopStatus.unknown:
        return const SizedBox.shrink();
    }
  }
}
