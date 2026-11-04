import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class RefundStatusScreen extends ConsumerWidget {
  final String orderId;

  const RefundStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order =
        orderState.pastOrders.where((o) => o.orderId == orderId).firstOrNull ??
        (orderState.activeOrder?.orderId == orderId
            ? orderState.activeOrder
            : null);
    final refundAmount = order?.refundAmount;
    if (order == null || refundAmount == null) return const NoOrderData();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refund Status'),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Refund Amount'),
            const SizedBox(height: 8),
            Text(Formatters.formatCurrency(refundAmount)),
            const SizedBox(height: 8),
            Text('Order #$orderId'),
          ],
        ),
      ),
    );
  }
}
