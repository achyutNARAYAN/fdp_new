import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/core/widgets/badges/diet_marker.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Your Cart'),
          backgroundColor: AppColors.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.p32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: AppColors.neutral,
                ),
                const SizedBox(height: 16),
                const Text('Your cart is empty', style: AppTypography.heading2),
                const SizedBox(height: 8),
                const Text(
                  'Explore nearby sweet shops and gelato parlours to add delicious treats.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Browse Sweets & Gelato',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Shop Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCard,
                      ),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint20,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cart.shopName ?? '',
                                style: AppTypography.itemName,
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (cart.shopId != null)
                              context.push('/shop/${cart.shopId}');
                          },
                          child: const Text(
                            'View Shop',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Needs Attention Section (if any item price changed or out of stock)
                  if (cart.hasIssues) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint12,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'One or more items in your cart need review before checkout.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Ready Items List
                  const Text(
                    'Items in Cart',
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  ...cart.items.map((cartItem) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutralLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              cartItem.item.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.primaryTint10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    DietMarker(
                                      dietType: cartItem.item.dietType,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cartItem.item.name,
                                        style: AppTypography.itemName.copyWith(
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cartItem.selectedVariant.label,
                                  style: AppTypography.caption,
                                ),
                                if (cartItem.cakeMessage != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Message: "${cartItem.cakeMessage}"',
                                    style: AppTypography.caption.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  Formatters.formatCurrency(
                                    cartItem.totalPrice,
                                  ),
                                  style: AppTypography.price.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Stepper
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint20,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 36,
                                  ),
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                          cartItem.id,
                                          cartItem.quantity - 1,
                                        );
                                  },
                                ),
                                Text(
                                  '${cartItem.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 36,
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                          cartItem.id,
                                          cartItem.quantity + 1,
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // 5. Cold Item Handling Note
                  if (cart.containsPerishable)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.ac_unit,
                            size: 20,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Contains perishable items (Gelato / Fresh Cream). Handled in thermal cold bags. Refrigerate on arrival.',
                              style: AppTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 6. Offers & Coupon Row
                  GestureDetector(
                    onTap: () => context.push('/offers'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCard,
                        ),
                        border: Border.all(color: AppColors.neutralLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cart.appliedCouponCode != null
                                  ? 'Coupon "${cart.appliedCouponCode}" Applied'
                                  : 'Apply Coupons & Offers',
                              style: AppTypography.itemName.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (cart.appliedCouponCode != null)
                            TextButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .removeCoupon(),
                              child: const Text(
                                'Remove',
                                style: TextStyle(color: AppColors.accent),
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 7. Bill Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCard,
                      ),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Summary',
                          style: AppTypography.itemName,
                        ),
                        const SizedBox(height: 12),
                        _buildBillRow(
                          'Item Total',
                          Formatters.formatCurrency(cart.subtotal),
                        ),
                        if (cart.discountAmount > 0)
                          _buildBillRow(
                            'Coupon Discount',
                            '-${Formatters.formatCurrency(cart.discountAmount)}',
                            textColor: AppColors.accentPressed,
                          ),
                        if (cart.deliveryFee != null)
                          _buildBillRow(
                            'Delivery Partner Fee',
                            Formatters.formatCurrency(cart.deliveryFee!),
                          ),
                        if (cart.packagingFee != null)
                          _buildBillRow(
                            'Confectionery Packaging',
                            Formatters.formatCurrency(cart.packagingFee!),
                          ),
                        if (cart.platformFee != null)
                          _buildBillRow(
                            'Platform Fee',
                            Formatters.formatCurrency(cart.platformFee!),
                          ),
                        if (cart.taxes != null)
                          _buildBillRow(
                            'Taxes',
                            Formatters.formatCurrency(cart.taxes!),
                          ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: AppTypography.heading2,
                            ),
                            Text(
                              Formatters.formatCurrency(cart.grandTotal),
                              style: AppTypography.price.copyWith(fontSize: 22),
                            ),
                          ],
                        ),
                        if (cart.discountAmount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint20,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'You saved ${Formatters.formatCurrency(cart.discountAmount)} on this order!',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Sticky Bottom Checkout Bar (Section 24: Total on left, Checkout on right)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14171A14),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TO PAY', style: AppTypography.caption),
                      Text(
                        Formatters.formatCurrency(cart.grandTotal),
                        style: AppTypography.price.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Proceed to Checkout',
                      onPressed: () => context.push('/checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
