import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/item/providers/catalog_provider.dart';
import 'package:fdp/core/widgets/cards/shop_card.dart';

class CategoryScreen extends ConsumerWidget {
  final String categoryName;

  const CategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(categoryStoresProvider(categoryName));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: AppColors.surface,
      ),
      body: stores.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error.toString(), style: AppTypography.bodySmall),
        ),
        data: (shops) => shops.isEmpty
            ? const Center(child: Text('No nearby shops in this category.'))
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.p16),
                itemCount: shops.length,
                itemBuilder: (context, index) => ShopCard(
                  shop: shops[index],
                  onTap: () => context.push('/shop/${shops[index].id}'),
                ),
              ),
      ),
    );
  }
}
