import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/order_model.dart';
import 'floating_cart_pill.dart';
import 'active_order_banner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final hasActionNeeded = orderState.activeOrder?.orderStatus == OrderStatus.changesProposed;
    final activeOrder = orderState.activeOrder;
    final hasActiveOrder = (currentIndex == 0 || currentIndex == 2) &&
        activeOrder != null &&
        activeOrder.orderStatus != OrderStatus.delivered &&
        activeOrder.orderStatus != OrderStatus.cancelled &&
        activeOrder.orderStatus != OrderStatus.declined;
    final hasCart = !ref.watch(cartProvider).isEmpty;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final overlayHeight = (hasActiveOrder ? 86.0 : 0.0) + (hasCart ? 68.0 : 0.0);
    final navBarHeight = AppDimensions.heightBottomNav + bottomInset;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Body content with dynamic bottom padding so it doesn't get obscured
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16 + overlayHeight),
              child: child,
            ),
          ),

          // Floating Cart Pill & Active Order Banner (rides above bottom nav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentIndex == 0 || currentIndex == 2)
                  const ActiveOrderBanner(),
                const SizedBox(height: 6),
                const FloatingCartPill(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: navBarHeight,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              index: 0,
              route: '/home',
              label: 'Home',
              outlineIcon: Icons.home_outlined,
              filledIcon: Icons.home,
            ),
            _buildNavItem(
              context,
              index: 1,
              route: '/search',
              label: 'Search',
              outlineIcon: Icons.search_outlined,
              filledIcon: Icons.search,
            ),
            _buildNavItem(
              context,
              index: 2,
              route: '/orders',
              label: 'Orders',
              outlineIcon: Icons.receipt_long_outlined,
              filledIcon: Icons.receipt_long,
              hasBadge: hasActionNeeded,
            ),
            _buildNavItem(
              context,
              index: 3,
              route: '/favorites',
              label: 'Favorites',
              outlineIcon: Icons.favorite_border,
              filledIcon: Icons.favorite,
            ),
            _buildNavItem(
              context,
              index: 4,
              route: '/profile',
              label: 'Profile',
              outlineIcon: Icons.person_outline,
              filledIcon: Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required String route,
    required String label,
    required IconData outlineIcon,
    required IconData filledIcon,
    bool hasBadge = false,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint20 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  size: 22,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
