import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/badges/status_chip.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class RefundStatusScreen extends ConsumerWidget {
  final String orderId;

  const RefundStatusScreen({
    super.key,
    required this.orderId,
  });

  static const List<Map<String, dynamic>> _refundSteps = [
    {
      'title': 'Refund Initiated by Confectionery Platform',
      'desc': 'Reversal request dispatched to banking partner gateway.',
      'time': 'Yesterday, 04:30 PM',
      'isDone': true,
    },
    {
      'title': 'Bank Clearing House Processing (NPCI / Visa)',
      'desc': 'Bank authorization reference ARN: 489201948201 generated.',
      'time': 'Today, 10:15 AM',
      'isDone': true,
    },
    {
      'title': 'Credited to Source Account',
      'desc': 'Funds expected to reflect in your bank statement within 24–48 hours.',
      'time': 'Estimated by Tomorrow',
      'isDone': false,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.pastOrders.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => orderState.activeOrder ?? orderState.pastOrders.first,
    );

    final refundAmount = order.refundAmount ?? order.totalAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refund Tracking Status'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.p20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
                boxShadow: AppDimensions.elevationLevel1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Refund Amount', style: AppTypography.caption),
                      StatusChip(label: 'In Progress', type: StatusChipType.pending),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatCurrency(refundAmount),
                    style: AppTypography.display.copyWith(fontSize: 32),
                  ),
                  const Divider(height: 24),
                  _row('Destination', 'Original UPI ID (****@okaxis)'),
                  _row('Bank ARN Reference', 'ARN 489201948201'),
                  _row('Linked Order', '#$orderId'),
                  _row('Expected Credit Time', 'Within 2 business days'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Automated Reversal Timeline', style: AppTypography.sectionTitle),
            const SizedBox(height: 16),

            // Stepper
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _refundSteps.length,
              itemBuilder: (context, index) {
                final step = _refundSteps[index];
                final isDone = step['isDone'] as bool;
                final isCurrent = index == 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? AppColors.primary : Colors.white,
                            border: Border.all(
                              color: isDone ? AppColors.primary : AppColors.neutralBorder,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isDone
                              ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                              : null,
                        ),
                        if (index < _refundSteps.length - 1)
                          Container(
                            width: 2,
                            height: 54,
                            color: isDone ? AppColors.primary : AppColors.divider,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: AppTypography.itemName.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(step['desc'] as String, style: AppTypography.caption),
                            const SizedBox(height: 2),
                            Text(
                              step['time'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isCurrent ? AppColors.accentPressed : AppColors.textSecondary,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            AppPrimaryButton(
              label: 'Need Help with this Refund?',
              onPressed: () => context.push('/support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
