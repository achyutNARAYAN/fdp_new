import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/providers/notification_provider.dart';
import '../../shared/providers/store_provider.dart';
import '../../shared/providers/catalog_provider.dart';
import '../../shared/widgets/cards/shop_card.dart';
import '../../shared/widgets/cards/item_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final unreadNotifs = ref.watch(notificationProvider.notifier).unreadCount;
    final storesState = ref.watch(storesProvider);
    final catalogState = ref.watch(catalogProvider);

    final displayShops = storesState.stores;
    final displayItems = catalogState.items;
    final categories = catalogState.items
        .map((item) => item.category)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              ref.read(storesProvider.notifier).loadStores(),
              ref.read(catalogProvider.notifier).loadCatalog(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Bar (56 high)
              SliverToBoxAdapter(
                child: Container(
                  height: AppDimensions.heightTopBar,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16,
                  ),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/delivery-location'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deliver to',
                                style: AppTypography.caption,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      locationState.selectedAddress?.title ??
                                          'Choose address',
                                      style: AppTypography.itemName.copyWith(
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Notification bell with touch target & badge
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.minTouchTarget,
                          minHeight: AppDimensions.minTouchTarget,
                        ),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              size: 24,
                              color: AppColors.textPrimary,
                            ),
                            if (unreadNotifs > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () => context.push('/notifications'),
                      ),

                      // Cart Icon (touch target)
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.minTouchTarget,
                          minHeight: AppDimensions.minTouchTarget,
                        ),
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => context.push('/cart'),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusInput,
                        ),
                        border: Border.all(
                          color: AppColors.neutralBorder,
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Search items and stores...',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category Carousel (72px circular photo/icon tiles)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.p16,
                      ),
                      child: Text(
                        'Explore Categories',
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.p16,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final name = categories[index];
                          return GestureDetector(
                            onTap: () => context.push('/category/${name}'),
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint10,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.neutralLight,
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.category_outlined,
                                    size: 32,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.p24),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.p24),
              ),

              // Popular Near You (Live Catalog Sweets & Treats)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.p16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Popular Near You',
                                style: AppTypography.sectionTitle,
                              ),
                              if (catalogState.isLoading) ...[
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
                          TextButton(
                            onPressed: categories.isEmpty
                                ? null
                                : () => context.push(
                                    '/category/${categories.first}',
                                  ),
                            child: const Text(
                              'See all',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 310,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.p16,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: displayItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return SizedBox(
                            width: 180,
                            child: ItemCard(
                              item: item,
                              onTap: () => context.push('/item/${item.id}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.p24),
              ),

              // Shops Near You (Live Stores List)
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
                            'Shops Near You',
                            style: AppTypography.sectionTitle,
                          ),
                          if (storesState.isLoading) ...[
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
                      TextButton(
                        onPressed: () => context.push('/search'),
                        child: const Text(
                          'Filters',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p16,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final shop = displayShops[index];
                    return ShopCard(
                      shop: shop,
                      onTap: () => context.push('/shop/${shop.id}'),
                    );
                  }, childCount: displayShops.length),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
