import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/badges/status_chip.dart';
import '../../shared/widgets/layout/no_order_data.dart';

class OrderRequestSubmittedScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderRequestSubmittedScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderRequestSubmittedScreen> createState() =>
      _OrderRequestSubmittedScreenState();
}

class _OrderRequestSubmittedScreenState
    extends ConsumerState<OrderRequestSubmittedScreen> {
  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    if (order == null) return const NoOrderData();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Pending Status Chip
              const StatusChip(
                label: 'Waiting for Shop Confirmation',
                type: StatusChipType.pending,
              ),
              const SizedBox(height: 16),

              const Text(
                'Order Request Transmitted',
                style: AppTypography.display,
              ),
              const SizedBox(height: 8),
              Text(
                'We have pinged ${order.shopName ?? "the sweet shop"}’s live kitchen terminal. Connecting to shop confirmation desk...',
                style: AppTypography.body,
              ),
              const SizedBox(height: 32),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                  boxShadow: AppDimensions.elevationLevel1,
                ),
                child: Column(
                  children: [
                    _row('Order ID', '#${widget.orderId}'),
                    _row('Confectioner', order.shopName ?? ''),
                    _row('Items', '${order.items.length ?? 0} items'),
                    _row(
                      'Total',
                      order == null
                          ? ''
                          : Formatters.formatCurrency(order.totalAmount),
                    ),
                    _row(
                      'Payment Status',
                      order.paymentMethod == PaymentMethodType.cod
                          ? 'COD Pending'
                          : 'Paid Online',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/waiting-confirmation/${widget.orderId}');
                  },
                  child: const Text(
                    'Proceed to Live Confirmation Screen →',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
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
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.itemName.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
