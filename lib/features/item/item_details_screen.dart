import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/item/models/item_model.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/features/favorites/providers/favorites_provider.dart';
import 'package:fdp/features/item/providers/catalog_provider.dart';
import 'package:fdp/features/item/providers/store_provider.dart';
import 'package:fdp/core/widgets/badges/diet_marker.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'customise_sheet.dart';

class ItemDetailsScreen extends ConsumerStatefulWidget {
  final String itemId;
  final ItemModel? initialItem;

  const ItemDetailsScreen({super.key, required this.itemId, this.initialItem});

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  ItemVariant? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
  }

  ItemModel? _findItem() {
    if (widget.initialItem != null) return widget.initialItem;
    final catalogItems = ref.read(catalogProvider).items;
    final found = catalogItems.where((i) => i.id == widget.itemId).firstOrNull;
    if (found != null) return found;

    return null;
  }

  void _openCustomiseSheet(ItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          CustomiseSheet(item: item, initialVariant: _selectedVariant!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cachedItem = _findItem();
    final itemAsync = cachedItem == null
        ? ref.watch(catalogItemProvider(widget.itemId))
        : null;
    final item = cachedItem ?? itemAsync?.asData?.value;
    if (item == null) {
      return Scaffold(
        body: Center(
          child: itemAsync?.isLoading == true
              ? const CircularProgressIndicator()
              : const Text('Item not found.'),
        ),
      );
    }
    final defaultVariant = item.defaultVariant;
    if (defaultVariant == null) {
      return _buildCatalogDetails(item);
    }
    if (item.availability == ItemAvailability.unavailable) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('${item.name} is unavailable.')),
      );
    }
    _selectedVariant ??= defaultVariant;
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.favoriteItemIds.contains(item.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full Scrollable View
          CustomScrollView(
            slivers: [
              // Hero Image 4:3 Carousel
              SliverAppBar(
                expandedHeight: 280,
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
                          .toggleItemFavorite(item.id);
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: AppColors.primaryTint10),
                  ),
                ),
              ),

              // Overlapping White Sheet (Radius 28)
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radiusBottomSheet),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppDimensions.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Diet marker + Shop Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DietMarker(
                              dietType: item.dietType,
                              showLabel: true,
                            ),
                            GestureDetector(
                              onTap: () => context.push('/shop/${item.shopId}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.shopName,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Item Title
                        Text(item.name, style: AppTypography.heading1),
                        const SizedBox(height: 8),

                        // Price Row
                        Row(
                          children: [
                            Text(
                              Formatters.formatCurrency(
                                _selectedVariant!.price,
                              ),
                              style: AppTypography.price.copyWith(fontSize: 24),
                            ),
                            if (_selectedVariant!.mrp != null &&
                                _selectedVariant!.mrp! >
                                    _selectedVariant!.price) ...[
                              const SizedBox(width: 8),
                              Text(
                                Formatters.formatCurrency(
                                  _selectedVariant!.mrp!,
                                ),
                                style: AppTypography.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTint12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_selectedVariant!.discountPercent.toInt()}% OFF',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentPressed,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Perishable Cold-chain Notice
                        if (item.isPerishable)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.ac_unit,
                                  size: 20,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.storageNote ??
                                        'Packed for cold delivery. Refrigerate on arrival.',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Weight / Size Variant Selector Pills
                        const Text(
                          'Available Sizes / Weights',
                          style: AppTypography.itemName,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: item.variants.map((v) {
                            final isSelected = _selectedVariant!.id == v.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedVariant = v),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryTint20
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.neutralBorder,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      v.label,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.formatCurrency(v.price),
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Expandable Description Sections
                        _buildExpandableTile(
                          'About this delicacy',
                          item.description,
                          isInitialExpanded: true,
                        ),
                        if (item.ingredients.isNotEmpty)
                          _buildExpandableTile(
                            'Pristine Ingredients',
                            item.ingredients.join(', '),
                          ),
                        if (item.allergens.isNotEmpty)
                          _buildExpandableTile(
                            'Allergen Information',
                            item.allergens.join(', '),
                          ),
                        if (item.shelfLife != null)
                          _buildExpandableTile(
                            'Shelf Life & Storage',
                            '${item.shelfLife}\n${item.storageNote ?? ""}',
                          ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom CTA Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
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
                    // Stepper
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint20,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Text('$_quantity', style: AppTypography.itemName),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Add / Customise CTA
                    Expanded(
                      child: AppPrimaryButton(
                        label:
                            item.customizationGroups.isNotEmpty ||
                                item.allowsCakeMessage
                            ? 'Customise Options'
                            : 'Add • ${Formatters.formatCurrency(_selectedVariant!.price * _quantity)}',
                        onPressed: () {
                          if (item.customizationGroups.isNotEmpty ||
                              item.allowsCakeMessage) {
                            _openCustomiseSheet(item);
                          } else {
                            try {
                              ref
                                  .read(cartProvider.notifier)
                                  .addItem(
                                    item: item,
                                    variant: _selectedVariant!,
                                    quantity: _quantity,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart!'),
                                  backgroundColor: AppColors.textPrimary,
                                ),
                              );
                            } on CartConflictException catch (e) {
                              _showReplaceCartDialog(context, ref, e);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogDetails(ItemModel item) {
    final offersAsync = ref.watch(catalogOffersProvider(item.id));
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.favoriteItemIds.contains(item.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(item.category),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(favoritesProvider.notifier)
                .toggleItemFavorite(item.id),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppDimensions.p24),
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primaryTint10,
                child: const Icon(
                  Icons.bakery_dining,
                  size: 72,
                  color: AppColors.neutral,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DietMarker(dietType: item.dietType, showLabel: true),
                    const Spacer(),
                    if (item.approxPrepTimeMinutes != null)
                      Text(
                        '${item.approxPrepTimeMinutes} min prep',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item.name, style: AppTypography.heading1),
                if (item.hindiName?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(item.hindiName!, style: AppTypography.bodySmall),
                ],
                const SizedBox(height: 12),
                Text(item.description, style: AppTypography.body),
                if (item.allowedUnits.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Available sizes', style: AppTypography.itemName),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.allowedUnits
                        .map(
                          (unit) => Chip(
                            label: Text(ApiConfig.formatMeasurementUnit(unit)),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(
                              color: AppColors.neutralBorder,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (item.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Ingredients', style: AppTypography.itemName),
                  const SizedBox(height: 6),
                  Text(
                    item.ingredients.join(' · '),
                    style: AppTypography.bodySmall,
                  ),
                ],
                if (item.allergens.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contains: ${item.allergens.join(', ')}',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                Text('Order from a shop', style: AppTypography.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  'Prices and sizes vary by shop.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                offersAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => _buildOffersEmpty(
                    'Could not load shop menus. Pull to refresh or try again.',
                    onBrowse: () =>
                        ref.invalidate(catalogOffersProvider(item.id)),
                  ),
                  data: (offers) => offers.isEmpty
                      ? _buildOffersEmpty(
                          'No open shop currently lists this item.',
                          onBrowse: () => context.push('/search'),
                        )
                      : Column(
                          children: offers
                              .map((offer) => _buildShopOffer(context, offer))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersEmpty(String message, {required VoidCallback onBrowse}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Browse shops'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopOffer(BuildContext context, ItemModel offer) {
    final variant = offer.defaultVariant!;
    final cart = ref.watch(cartProvider);
    final cartItemIndex = cart.items.indexWhere(
      (ci) => ci.item.id == offer.id && ci.selectedVariant.id == variant.id,
    );
    final bool inCart = cartItemIndex >= 0;
    final int quantity = inCart ? cart.items[cartItemIndex].quantity : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.neutralLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            offer.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 60,
              height: 60,
              color: AppColors.primaryTint10,
              child: const Icon(Icons.storefront_outlined),
            ),
          ),
        ),
        title: Text(offer.shopName, style: AppTypography.itemName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${Formatters.formatCurrency(variant.price)} · ${variant.label}',
            style: AppTypography.price.copyWith(fontSize: 14),
          ),
        ),
        trailing: inCart
            ? Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 14, color: AppColors.onPrimary),
                      onPressed: () {
                        final currentCart = ref.read(cartProvider);
                        if (cartItemIndex >= 0 && cartItemIndex < currentCart.items.length) {
                          ref.read(cartProvider.notifier).updateQuantity(
                                currentCart.items[cartItemIndex].id,
                                quantity - 1,
                              );
                        }
                      },
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 14, color: AppColors.onPrimary),
                      onPressed: () {
                        final currentCart = ref.read(cartProvider);
                        if (cartItemIndex >= 0 && cartItemIndex < currentCart.items.length) {
                          ref.read(cartProvider.notifier).updateQuantity(
                                currentCart.items[cartItemIndex].id,
                                quantity + 1,
                              );
                        }
                      },
                    ),
                  ],
                ),
              )
            : SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    try {
                      ref.read(cartProvider.notifier).addItem(
                            item: offer,
                            variant: variant,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${offer.name} added to cart from ${offer.shopName}!'),
                          backgroundColor: AppColors.textPrimary,
                          duration: const Duration(milliseconds: 1400),
                        ),
                      );
                    } on CartConflictException catch (e) {
                      _showReplaceCartDialog(context, ref, e);
                    }
                  },
                  child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
        onTap: () => context.push('/shop/${offer.shopId}'),
      ),
    ),
  );
}

  Widget _buildExpandableTile(
    String title,
    String content, {
    bool isInitialExpanded = false,
  }) {
    return ExpansionTile(
      initiallyExpanded: isInitialExpanded,
      tilePadding: EdgeInsets.zero,
      title: Text(title, style: AppTypography.itemName),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            content,
            style: AppTypography.bodySmall.copyWith(height: 1.4),
          ),
        ),
      ],
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
                    quantity: _quantity,
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
