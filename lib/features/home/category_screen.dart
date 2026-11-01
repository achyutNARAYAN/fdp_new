import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/providers/catalog_provider.dart';
import '../../shared/widgets/cards/item_card.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String _selectedSubcategory = 'All';

  List<String> get _subcategories {
    switch (widget.categoryName) {
      case 'Ice Cream':
        return ['All', 'Cups', 'Gelato Tubs', 'Kulfi', 'Sundaes'];
      case 'Sweets':
        return ['All', 'Kaju Katli', 'Ladoo', 'Ghee Sweets', 'Dry Fruit'];
      case 'Cakes':
        return ['All', 'Chocolate', 'Cheesecake', 'Fruit Cakes', 'Custom'];
      default:
        return ['All', 'Artisanal', 'Bestsellers', 'Festive Special'];
    }
  }

  bool get _isPerishableCategory {
    return widget.categoryName == 'Ice Cream' ||
        widget.categoryName == 'Cakes' ||
        widget.categoryName == 'Desserts';
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final allItems = catalogState.items.isNotEmpty ? catalogState.items : MockData.allItems;

    final filteredItems = allItems.where((i) {
      if (widget.categoryName == 'Sweets') return i.category == 'Sweets' || i.category == 'Desserts';
      return i.category.toLowerCase() == widget.categoryName.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: AppTypography.heading1,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Handcrafted with pristine ingredients by certified confectioners.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          // Perishable Handling Notice Strip if applicable
          if (_isPerishableCategory)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryTint10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.ac_unit, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Packed in temperature-controlled insulated pouches. Please refrigerate or freeze immediately on arrival.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Subcategories Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _subcategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sub = _subcategories[index];
                final isSelected = _selectedSubcategory == sub;
                return ChoiceChip(
                  label: Text(sub),
                  selected: isSelected,
                  selectedColor: AppColors.primaryTint20,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedSubcategory = sub);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Grid of Items
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No items in this category currently available.', style: AppTypography.bodySmall),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppDimensions.p16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ItemCard(
                        item: item,
                        onTap: () => context.push('/item/${item.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
