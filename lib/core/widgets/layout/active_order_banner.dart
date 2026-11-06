import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/orders/providers/order_provider.dart';
import '../../../features/orders/models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_dimensions.dart';

class ActiveOrderBanner extends ConsumerWidget {
  const ActiveOrderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final active = orderState.activeOrder;

    // Show only when order is in active fulfillment
    if (active == null ||
        active.orderStatus == OrderStatus.delivered ||
        active.orderStatus == OrderStatus.cancelled ||
        active.orderStatus == OrderStatus.declined) {
      return const SizedBox.shrink();
    }

    // Build human-readable item summary (e.g. "Sohan Papdi" or "Sohan Papdi +1 more")
    final String itemSummaryText;
    if (active.items.isNotEmpty) {
      final firstItem = active.items.first;
      final firstName = firstItem.item.name.trim();
      final quantityPrefix = firstItem.quantity > 1 ? '${firstItem.quantity}x ' : '';
      if (active.items.length == 1) {
        itemSummaryText = '$quantityPrefix$firstName';
      } else {
        itemSummaryText = '$quantityPrefix$firstName +${active.items.length - 1} more';
      }
    } else if (active.orderNumber != null && active.orderNumber!.isNotEmpty) {
      itemSummaryText = active.orderNumber!;
    } else {
      itemSummaryText = 'Order #${active.orderId.length > 8 ? active.orderId.substring(active.orderId.length - 6).toUpperCase() : active.orderId}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryTint20,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.primary, width: 1.2),
        boxShadow: AppDimensions.elevationLevel1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          onTap: () {
            context.push('/order-tracking/${active.orderId}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Animated pulse indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),

                // Order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              itemSummaryText,
                              style: AppTypography.itemName.copyWith(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              active.orderStatus.label,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active.shopName.isNotEmpty && active.shopName != 'Store'
                            ? '${active.shopName} • Delivery in 20-25 min'
                            : 'Estimated delivery in 20-25 min',
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),

                // Track CTA
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Track',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textPrimary),
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

