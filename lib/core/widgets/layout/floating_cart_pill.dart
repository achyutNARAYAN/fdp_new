import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_dimensions.dart';
import '../../utils/formatters.dart';

/// Section 3 & 23: Floating cart pill.
/// 56 high, radius 28, fill color.text.primary (the one inverted element in the app),
/// white label 15 semibold, Sage Green chevron, small Burnt Amber dot for the item count.
/// Elevation level 3. It rides 12 above the bottom nav and never overlaps it.
/// Hidden on Cart, Checkout, Payment and Confirmation screens.
class FloatingCartPill extends ConsumerWidget {
  const FloatingCartPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return const SizedBox.shrink();
    }

    final String itemText = '${cart.totalItemCount} ${cart.totalItemCount == 1 ? 'Item' : 'Items'}';
    final String amountText = Formatters.formatCurrency(cart.grandTotal);

    return Container(
      height: AppDimensions.heightFloatingCart,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.primary, // Sage Green
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        boxShadow: AppDimensions.elevationLevel3,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          onTap: () {
            context.push('/cart');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20),
            child: Row(
              children: [
                // Burnt Amber item badge dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDimensions.p12),

                // Item count & Total
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemText • $amountText',
                        style: AppTypography.itemName.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (cart.shopName != null &&
                          cart.shopName!.trim().isNotEmpty)
                        Text(
                          'From ${cart.shopName!.trim()}',
                          style: TextStyle(
                            color: AppColors.onPrimary.withOpacity(0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // View Cart + Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View Cart',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

