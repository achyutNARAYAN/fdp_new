import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/badges/order_status_badge.dart';
import 'package:fdp/core/widgets/badges/payment_status_badge.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class OrderConfirmedScreen extends ConsumerWidget {
  final String orderId;

  const OrderConfirmedScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = (orderState.activeOrder?.orderId == orderId
            ? orderState.activeOrder
            : orderState.pastOrders
                .where((o) => o.orderId == orderId)
                .firstOrNull) ??
        orderState.activeOrder;
    if (order == null) return const NoOrderData();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            children: [
              const Spacer(),

              // 96px Sage Green Circle with Check & Soft Ripple (No confetti!)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  size: 54,
                  color: AppColors.onPrimary,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Your order is confirmed!',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                order.shopName ?? '',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Separate Order Status & Payment Status Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OrderStatusBadge(status: OrderStatus.orderConfirmed),
                  const SizedBox(width: 8),
                  PaymentStatusBadge(
                    status: order.paymentMethod == PaymentMethodType.cod
                        ? PaymentStatus.codPending
                        : PaymentStatus.paid,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                  boxShadow: AppDimensions.elevationLevel1,
                ),
                child: Column(
                  children: [
                    _row('Order ID', '#$orderId'),
                    _row('Confectionery Shop', order.shopName ?? ''),
                    _row(
                      'Estimated Delivery',
                      order.estimatedDeliveryTime == null
                          ? ''
                          : Formatters.formatTime(
                              order!.estimatedDeliveryTime!,
                            ),
                    ),
                    _row(
                      'Item Total',
                      order == null
                          ? ''
                          : Formatters.formatCurrency(order.totalAmount),
                    ),
                    _row('Delivery Address', order.deliveryAddress ?? ''),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Policy Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Cancellation policy: Orders can be cancelled freely until preparation begins. Custom cakes cannot be cancelled once baking starts.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Primary: Track Order, Secondary: View Order Details
              AppPrimaryButton(
                label: 'Track Order Live',
                onPressed: () {
                  context.go('/order-tracking/$orderId');
                },
              ),
              const SizedBox(height: 12),

              AppSecondaryButton(
                label: 'View Order Details',
                onPressed: () {
                  context.push('/order-details/$orderId');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Flexible(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
