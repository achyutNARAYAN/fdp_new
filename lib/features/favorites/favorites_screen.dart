import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/item/providers/catalog_provider.dart';
import 'package:fdp/features/item/providers/store_provider.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/favorites/providers/favorites_provider.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/core/widgets/cards/item_card.dart';
import 'package:fdp/core/widgets/cards/shop_card.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleReorder(OrderModel order) {
    // Check if items are from a different shop than existing cart
    final cart = ref.read(cartProvider);
    if (!cart.isEmpty && cart.shopId != order.shopId) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
          ),
          title: const Text(
            'Replace existing cart?',
            style: AppTypography.heading2,
          ),
          content: Text(
            'Reordering from ${order.shopName} will replace items currently in your cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _applyReorder(order);
              },
              child: const Text('Replace & Reorder'),
            ),
          ],
        ),
      );
    } else {
      _applyReorder(order);
    }
  }

  void _applyReorder(OrderModel order) {
    if (order.items.isNotEmpty) {
      final first = order.items.first;
      ref
          .read(cartProvider.notifier)
          .replaceCartWithItem(
            item: first.item,
            variant: first.selectedVariant,
            quantity: first.quantity,
          );
      context.push('/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoritesProvider);
    final orderState = ref.watch(orderProvider);

    final favItems = ref
        .watch(catalogProvider)
        .items
        .where((i) => favState.favoriteItemIds.contains(i.id))
        .toList();
    final favShops = ref
        .watch(storesProvider)
        .stores
        .where((s) => favState.favoriteShopIds.contains(s.id))
        .toList();
    final pastOrders = orderState.pastOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites & Reorder Hub'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3.0,
          labelColor: AppColors.textPrimary,
          labelStyle: AppTypography.itemName,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Items (${favItems.length})'),
            Tab(text: 'Shops (${favShops.length})'),
            Tab(text: 'Past Orders (${pastOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Favorite Items Tab
          favItems.isEmpty
              ? _buildEmptyState(
                  'No favorite sweets yet',
                  'Heart any item while browsing to save it here.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: favItems.length,
                  itemBuilder: (context, index) {
                    final item = favItems[index];
                    return ItemCard(
                      item: item,
                      onTap: () => context.push('/item/${item.id}'),
                    );
                  },
                ),

          // 2. Favorite Shops Tab
          favShops.isEmpty
              ? _buildEmptyState(
                  'No favorite sweet shops yet',
                  'Save sweet parlours and patisseries you love.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  itemCount: favShops.length,
                  itemBuilder: (context, index) {
                    final shop = favShops[index];
                    return ShopCard(
                      shop: shop,
                      onTap: () => context.push('/shop/${shop.id}'),
                    );
                  },
                ),

          // 3. Past Orders & 1-Tap Reorder
          pastOrders.isEmpty
              ? _buildEmptyState(
                  'No previous orders',
                  'Place an order to quickly reorder your favourites here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  itemCount: pastOrders.length,
                  itemBuilder: (context, index) {
                    final order = pastOrders[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.p16),
                      padding: const EdgeInsets.all(AppDimensions.p16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCard,
                        ),
                        border: Border.all(
                          color: AppColors.neutralLight,
                          width: 1,
                        ),
                        boxShadow: AppDimensions.elevationLevel1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.shopName,
                                style: AppTypography.heading2.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(order.totalAmount),
                                style: AppTypography.price.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order.orderId} • ${Formatters.formatDate(order.createdAt)}',
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.items
                                .map(
                                  (i) =>
                                      '${i.quantity}x ${i.item.name} (${i.selectedVariant.label})',
                                )
                                .join(', '),
                            style: AppTypography.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Reorder Past Items',
                                  icon: Icons.refresh,
                                  onPressed: () => _handleReorder(order),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => context.push(
                                  '/order-details/${order.orderId}',
                                ),
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 54,
              color: AppColors.neutral,
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.heading2),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () => context.go('/home'),
              child: const Text('Browse Treats'),
            ),
          ],
        ),
      ),
    );
  }
}
