import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class RateReviewScreen extends ConsumerStatefulWidget {
  final String orderId;

  const RateReviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends ConsumerState<RateReviewScreen> {
  int _foodRating = 0;
  int _partnerRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  static const List<String> _tags = [
    'Fresh & Pure',
    'Perfect Sweetness',
    'Cold Preserved',
    'Hygienic Packaging',
    'Quick Delivery',
    'Polite Partner',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review API is unavailable.')));
  }

  @override
  Widget build(BuildContext context) {
    final hasOrder = ref
        .watch(orderProvider)
        .pastOrders
        .any((order) => order.orderId == widget.orderId);
    if (!hasOrder) return const NoOrderData();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Rate Shop & Sweets
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                children: [
                  const Text(
                    'How were the sweets & packaging?',
                    style: AppTypography.itemName,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        iconSize: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          star <= _foodRating ? Icons.star : Icons.star_border,
                          color: star <= _foodRating
                              ? AppColors.accent
                              : AppColors.neutral,
                        ),
                        onPressed: () => setState(() => _foodRating = star),
                      );
                    }),
                  ),
                  if (_foodRating <= 2) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Was something wrong with the taste, freshness or temperature?',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => context.push(
                              '/raise-ticket?orderId=${widget.orderId}',
                            ),
                            child: const Text(
                              'Report Issue',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Rate Delivery Partner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rate Delivery Partner',
                    style: AppTypography.itemName,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        iconSize: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          star <= _partnerRating
                              ? Icons.star
                              : Icons.star_border,
                          color: star <= _partnerRating
                              ? AppColors.accent
                              : AppColors.neutral,
                        ),
                        onPressed: () => setState(() => _partnerRating = star),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Tags
            const Text('What stood out?', style: AppTypography.itemName),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((t) {
                final isChosen = _selectedTags.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: isChosen,
                  selectedColor: AppColors.primaryTint20,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isChosen
                        ? AppColors.primary
                        : AppColors.neutralBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedTags.add(t);
                      } else {
                        _selectedTags.remove(t);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Optional Comment Box
            const Text(
              'Comments or Notes for Kitchen',
              style: AppTypography.itemName,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Share what you loved about this artisanal sweet order...',
                hintStyle: AppTypography.bodySmall,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusInput,
                  ),
                  borderSide: const BorderSide(color: AppColors.neutralBorder),
                ),
              ),
            ),

            const SizedBox(height: 24),

            AppPrimaryButton(label: 'Submit Review', onPressed: _submitReview),
          ],
        ),
      ),
    );
  }
}
