import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/item/models/item_model.dart';
import 'package:fdp/features/item/models/diet_type.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/core/widgets/badges/diet_marker.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class CustomiseSheet extends ConsumerStatefulWidget {
  final ItemModel item;
  final ItemVariant? initialVariant;

  const CustomiseSheet({super.key, required this.item, this.initialVariant});

  @override
  ConsumerState<CustomiseSheet> createState() => _CustomiseSheetState();
}

class _CustomiseSheetState extends ConsumerState<CustomiseSheet> {
  late ItemVariant _selectedVariant;
  bool _isEggless = false;
  final TextEditingController _cakeMessageController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final List<ItemCustomizationOption> _selectedOptions = [];
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.initialVariant ?? widget.item.defaultVariant!;
  }

  @override
  void dispose() {
    _cakeMessageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double addOns = _selectedOptions.fold(0.0, (sum, opt) => sum + opt.price);
    return (_selectedVariant.price + addOns) * _quantity;
  }

  void _handleAddToCart() {
    try {
      ref
          .read(cartProvider.notifier)
          .addItem(
            item: widget.item,
            variant: _selectedVariant,
            quantity: _quantity,
            isEggless: _isEggless,
            cakeMessage: _cakeMessageController.text.trim().isNotEmpty
                ? _cakeMessageController.text.trim()
                : null,
            specialInstructions: _instructionsController.text.trim().isNotEmpty
                ? _instructionsController.text.trim()
                : null,
            customizations: _selectedOptions,
          );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.name} added to cart!'),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
    } on CartConflictException catch (e) {
      Navigator.pop(context);
      _showReplaceCartDialog(context, ref, e);
    }
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
                    isEggless: _isEggless,
                    cakeMessage: _cakeMessageController.text.trim().isNotEmpty
                        ? _cakeMessageController.text.trim()
                        : null,
                    customizations: _selectedOptions,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusBottomSheet),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.p20,
              vertical: 8,
            ),
            child: Row(
              children: [
                DietMarker(dietType: widget.item.dietType),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customise ${widget.item.name}',
                    style: AppTypography.heading2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scrollable options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.p20),
              children: [
                // 1. Variant / Size / Weight Selector
                const Text(
                  'Choose Size / Portion',
                  style: AppTypography.itemName,
                ),
                const SizedBox(height: 12),
                Column(
                  children: widget.item.variants.map((v) {
                    final isSelected = _selectedVariant.id == v.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? AppColors.primaryTint20
                            : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.neutralBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: RadioListTile<ItemVariant>(
                        value: v,
                        groupValue: _selectedVariant,
                        activeColor: AppColors.primary,
                        title: Text(v.label, style: AppTypography.itemName),
                        secondary: Text(
                          Formatters.formatCurrency(v.price),
                          style: AppTypography.price.copyWith(fontSize: 16),
                        ),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedVariant = val);
                        },
                      ),
                    ),
                  );
                }).toList(),
                ),

                const SizedBox(height: 20),

                // 2. Eggless Toggle (for Cakes/Pastries)
                if (widget.item.allowsEgglessToggle) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            DietMarker(dietType: DietType.veg, showLabel: true),
                            SizedBox(width: 8),
                            Text(
                              'Make 100% Eggless',
                              style: AppTypography.itemName,
                            ),
                          ],
                        ),
                        Switch(
                          value: _isEggless,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isEggless = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Cake Message (if enabled)
                if (widget.item.allowsCakeMessage) ...[
                  const Text(
                    'Custom Message on Cake',
                    style: AppTypography.itemName,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cakeMessageController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      hintText: 'e.g. Happy Birthday Aarav!',
                      hintStyle: AppTypography.bodySmall,
                      filled: true,
                      fillColor: AppColors.primaryTint10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.neutralBorder,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Customization Groups (Toppings, Add-ons)
                ...widget.item.customizationGroups.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.title, style: AppTypography.itemName),
                      const SizedBox(height: 8),
                      ...group.options.map((opt) {
                        final isChosen = _selectedOptions.any(
                          (o) => o.id == opt.id,
                        );
                        return CheckboxListTile(
                          value: isChosen,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.onPrimary,
                          title: Text(opt.name, style: AppTypography.body),
                          secondary: opt.price > 0
                              ? Text(
                                  '+${Formatters.formatCurrency(opt.price)}',
                                  style: AppTypography.caption,
                                )
                              : null,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedOptions.add(opt);
                              } else {
                                _selectedOptions.removeWhere(
                                  (o) => o.id == opt.id,
                                );
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                }),

                // 5. Special Instructions
                const Text(
                  'Special Instructions',
                  style: AppTypography.itemName,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Less sweet, extra napkins...',
                    hintStyle: AppTypography.bodySmall,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.neutralBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The shop will try to follow these, but they cannot be guaranteed.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),

          // Sticky Footer with Stepper & Add CTA
          Container(
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
                const SizedBox(width: 16),

                // Add Button with Animated Total
                Expanded(
                  child: AppPrimaryButton(
                    label:
                        'Add to Cart • ${Formatters.formatCurrency(_totalPrice)}',
                    onPressed: _handleAddToCart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
