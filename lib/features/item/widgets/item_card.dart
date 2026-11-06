import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/item_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/widgets/badges/diet_marker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';

class ItemCard extends ConsumerWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onCustomiseTap;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onCustomiseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItemIndex = cart.items.indexWhere((ci) => ci.item.id == item.id);
    final inCart = cartItemIndex >= 0;
    final quantity = inCart ? cart.items[cartItemIndex].quantity : 0;
    final defaultVariant = item.defaultVariant ??
        (item.variants.isNotEmpty
            ? item.variants.first
            : (item.price > 0
                ? ItemVariant(
                    id: item.id.isNotEmpty ? item.id : 'var_default',
                    unit: 'PORTION',
                    label: 'Standard',
                    price: item.price,
                    isDefault: true,
                  )
                : const ItemVariant(
                    id: 'var_default',
                    unit: 'PORTION',
                    label: 'From shops',
                    price: 0.0,
                    isDefault: true,
                  )));
    if (item.availability == ItemAvailability.unavailable) {
      return Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: const Text('Unavailable'),
          enabled: false,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isBounded = constraints.hasBoundedHeight;

        Widget detailsWidget = Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Diet marker + Item Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: DietMarker(dietType: item.dietType),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppTypography.itemName.copyWith(
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Shop Name
              Text(
                item.shopName,
                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Variant unit line
              Text(
                defaultVariant.label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Price with MRP Strikethrough
              Row(
                children: [
                  Text(
                    defaultVariant.price > 0
                        ? Formatters.formatCurrency(defaultVariant.price)
                        : 'Explore options',
                    style: defaultVariant.price > 0
                        ? AppTypography.price.copyWith(fontSize: 15)
                        : AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                  ),
                  if (defaultVariant.price > 0 &&
                      defaultVariant.mrp != null &&
                      defaultVariant.mrp! > defaultVariant.price) ...[
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatCurrency(defaultVariant.mrp!),
                      style: AppTypography.caption.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
              border: Border.all(color: AppColors.neutralLight, width: 1),
              boxShadow: AppDimensions.elevationLevel1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Image with 1.25 ratio and 16 radius
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radiusImage),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.25,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.primaryTint10,
                            child: const Icon(
                              Icons.bakery_dining,
                              size: 40,
                              color: AppColors.neutral,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Discount Badge
                    if (defaultVariant.discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentTint12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${defaultVariant.discountPercent.toInt()}% OFF',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentPressed,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    // Perishable handling tag
                    if (item.isPerishable)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ac_unit,
                                size: 10,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Cold-chain',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // ADD Button / Stepper (Bottom right of image)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _buildAddButtonOrStepper(
                        context,
                        ref,
                        inCart,
                        quantity,
                        cartItemIndex,
                        defaultVariant,
                      ),
                    ),
                  ],
                ),

                // Item Details
                if (isBounded)
                  Expanded(child: detailsWidget)
                else
                  detailsWidget,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButtonOrStepper(
    BuildContext context,
    WidgetRef ref,
    bool inCart,
    int quantity,
    int cartItemIndex,
    ItemVariant variant,
  ) {
    if (!inCart || quantity == 0) {
      return SizedBox(
        width: 76,
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 2,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (item.shopId.isEmpty ||
                variant.price <= 0 ||
                item.customizationGroups.isNotEmpty ||
                item.allowsCakeMessage ||
                onCustomiseTap != null) {
              if (onCustomiseTap != null) {
                onCustomiseTap!();
              } else if (onTap != null) {
                onTap!();
              }
            } else {
              try {
                ref
                    .read(cartProvider.notifier)
                    .addItem(item: item, variant: variant);
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Added "${item.name}" to cart'),
                    duration: const Duration(milliseconds: 2000),
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: AppColors.primaryTint20,
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        router.push('/cart');
                      },
                    ),
                  ),
                );
              } on CartConflictException catch (e) {
                _showReplaceCartDialog(context, ref, e);
              }
            }
          },
          child: const Text(
            'ADD',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    // Interactive Quantity Stepper (+ -)
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.remove,
              size: 14,
              color: AppColors.onPrimary,
            ),
            onPressed: () {
              final currentCart = ref.read(cartProvider);
              if (cartItemIndex >= 0 &&
                  cartItemIndex < currentCart.items.length) {
                final cartItemId = currentCart.items[cartItemIndex].id;
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(cartItemId, quantity - 1);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, size: 14, color: AppColors.onPrimary),
            onPressed: () {
              final currentCart = ref.read(cartProvider);
              if (cartItemIndex >= 0 &&
                  cartItemIndex < currentCart.items.length) {
                final cartItemId = currentCart.items[cartItemIndex].id;
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(cartItemId, quantity + 1);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReplaceCartDialog(
    BuildContext context,
    WidgetRef ref,
    CartConflictException conflict,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        title: const Text('Replace cart items?', style: AppTypography.heading2),
        content: Text(
          'Your cart has items from ${conflict.currentShopName}. Start a new cart with ${conflict.newShopName}?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Current Cart',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              ref
                  .read(cartProvider.notifier)
                  .replaceCartWithItem(
                    item: conflict.newItem,
                    variant: conflict.variant,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }
}
