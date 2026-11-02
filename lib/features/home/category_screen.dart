import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/catalog_provider.dart';
import '../../shared/widgets/cards/item_card.dart';

class CategoryScreen extends ConsumerWidget {
  final String categoryName;

  const CategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogProvider);
    final items = state.items
        .where(
          (item) => item.category.toLowerCase() == categoryName.toLowerCase(),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: AppColors.surface,
      ),
      body: state.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
              child: Text(
                state.errorMessage ?? 'No items available.',
                style: AppTypography.bodySmall,
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
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ItemCard(
                  item: item,
                  onTap: () => context.push('/item/${item.id}'),
                );
              },
            ),
    );
  }
}
