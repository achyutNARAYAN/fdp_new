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
                          Text(
                            'Order #${active.orderId}',
                            style: AppTypography.itemName.copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          Text(
                            active.orderStatus.label,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estimated delivery in 20-25 min',
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
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

