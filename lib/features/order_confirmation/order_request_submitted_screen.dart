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

class OrderRequestSubmittedScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderRequestSubmittedScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderRequestSubmittedScreen> createState() => _OrderRequestSubmittedScreenState();
}

class _OrderRequestSubmittedScreenState extends ConsumerState<OrderRequestSubmittedScreen> {
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _startTransition();
  }

  void _startTransition() async {
    // Fill 2px progress bar over 1.8 seconds then automatically transition to Waiting screen
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) {
        setState(() => _progressValue = i / 10.0);
      }
    }
    if (mounted) {
      context.go('/waiting-confirmation/${widget.orderId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;

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
                'We have pinged ${order?.shopName ?? "the sweet shop"}’s live kitchen terminal. Connecting to shop confirmation desk...',
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
                    _row('Confectioner', order?.shopName ?? 'Anand Sweets'),
                    _row('Items', '${order?.items.length ?? 2} items'),
                    _row('Total', Formatters.formatCurrency(order?.totalAmount ?? 824.5)),
                    _row(
                      'Payment Status',
                      order?.paymentMethod == PaymentMethodType.cod ? 'COD Pending' : 'Paid Online',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Progress Bar animating to Waiting Experience
              LinearProgressIndicator(
                value: _progressValue,
                minHeight: 3,
                backgroundColor: AppColors.neutralLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

              const Spacer(),

              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/waiting-confirmation/${widget.orderId}');
                  },
                  child: const Text('Proceed to Live Confirmation Screen →', style: TextStyle(color: AppColors.textPrimary)),
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

