import 'package:flutter/material.dart';
import '../../models/shop_model.dart';
import '../badges/status_chip.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback? onTap;

  const ShopCard({super.key, required this.shop, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isClosed = shop.isClosed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.p16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(color: AppColors.neutralLight, width: 1),
          boxShadow: AppDimensions.elevationLevel1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 image with status chip on top left
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusImage),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColorFiltered(
                      colorFilter: isClosed
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Image.network(
                        shop.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.primaryTint10,
                          child: const Icon(
                            Icons.storefront,
                            size: 48,
                            color: AppColors.neutral,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Status chip top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: shop.status == ShopStatus.unknown
                      ? const SizedBox.shrink()
                      : _buildShopStatusChip(shop.status),
                ),

                // Sponsored tag if applicable
                if (shop.isSponsored)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Shop Information
            Padding(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name & Verified Icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: AppTypography.heading2.copyWith(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (shop.rating > 0 ||
                      shop.distanceKm > 0 ||
                      shop.prepTimeMinutes.isNotEmpty)
                    Row(
                      children: [
                        if (shop.rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint20,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (shop.ratingCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${shop.ratingCount}+)',
                            style: AppTypography.caption,
                          ),
                        ],
                        if (shop.distanceKm > 0) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: AppColors.neutral),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${shop.distanceKm} km',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        if (shop.prepTimeMinutes.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: AppColors.neutral),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            shop.prepTimeMinutes,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: shop.tags.map((t) {
                      return Text(
                        t,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopStatusChip(ShopStatus status) {
    switch (status) {
      case ShopStatus.open:
        return const StatusChip(
          label: 'Open Now',
          type: StatusChipType.success,
        );
      case ShopStatus.busy:
        return const StatusChip(
          label: 'Busy • Longer wait',
          type: StatusChipType.pending,
        );
      case ShopStatus.closed:
        return const StatusChip(
          label: 'Closed for now',
          type: StatusChipType.info,
        );
      case ShopStatus.temporarilyUnavailable:
        return const StatusChip(
          label: 'Unavailable',
          type: StatusChipType.error,
        );
      case ShopStatus.unknown:
        return const SizedBox.shrink();
    }
  }
}
