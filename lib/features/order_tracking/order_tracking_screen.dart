import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/badges/order_status_badge.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = (orderState.activeOrder?.orderId == orderId
            ? orderState.activeOrder
            : orderState.pastOrders
                .where((order) => order.orderId == orderId)
                .firstOrNull) ??
        orderState.activeOrder;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Track Order #$orderId')),
      body: order == null
          ? const Center(child: Text('No order data available.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.shopName, style: AppTypography.heading2),
                  const SizedBox(height: 12),
                  OrderStatusBadge(status: order.orderStatus),
                  const SizedBox(height: 12),
                  Text(order.deliveryAddress, style: AppTypography.bodySmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            ),
    );
  }
}
