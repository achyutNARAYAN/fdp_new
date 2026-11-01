import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/badges/order_status_badge.dart';
import '../../shared/widgets/badges/payment_status_badge.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  static const List<Map<String, dynamic>> _allSteps = [
    {'status': OrderStatus.orderPlaced, 'title': 'Order Placed', 'time': '04:12 PM'},
    {'status': OrderStatus.confirmingOrder, 'title': 'Payment Confirmed & Transmitted', 'time': '04:13 PM'},
    {'status': OrderStatus.orderConfirmed, 'title': 'Shop Confirmed Order', 'time': '04:14 PM'},
    {'status': OrderStatus.preparing, 'title': 'Preparing Artisanal Sweets', 'time': '04:16 PM'},
    {'status': OrderStatus.readyForPickup, 'title': 'Packed in Cold Thermal Bag', 'time': '04:26 PM'},
    {'status': OrderStatus.driverAssigned, 'title': 'Delivery Partner Assigned', 'time': '04:28 PM'},
    {'status': OrderStatus.pickedUp, 'title': 'Picked Up by Vikram Singh', 'time': '04:32 PM'},
    {'status': OrderStatus.outForDelivery, 'title': 'Out for Delivery', 'time': '04:35 PM'},
    {'status': OrderStatus.delivered, 'title': 'Delivered to Doorstep', 'time': '04:48 PM'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;
    final currentStatus = order?.orderStatus ?? OrderStatus.preparing;

    // Find current step index
    int currentIndex = _allSteps.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex < 0) currentIndex = 3; // Default to Preparing for demo

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Track Order #$orderId'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Separate Badges Header (Section 5 requirement)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order?.shopName ?? 'Anand Sweets', style: AppTypography.heading2),
                            OrderStatusBadge(status: currentStatus),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Verification:', style: AppTypography.caption),
                            PaymentStatusBadge(status: order?.paymentStatus ?? PaymentStatus.paid),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Delivery', style: AppTypography.bodySmall),
                            Text(
                              'In 15–20 min (${Formatters.formatTime(DateTime.now().add(const Duration(minutes: 20)))})',
                              style: AppTypography.itemName.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Live Map Card Preview
                  GestureDetector(
                    onTap: () => context.push('/live-map/$orderId'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint20,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.primary, width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_outlined, color: AppColors.textPrimary, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Delivery Map', style: AppTypography.itemName),
                                SizedBox(height: 2),
                                Text(
                                  'Follow partner route on map in real time',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textPrimary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('Fulfillment Milestones', style: AppTypography.sectionTitle),
                  const SizedBox(height: 16),

                  // Section 23 Vertical Order Timeline
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allSteps.length,
                    itemBuilder: (context, index) {
                      final step = _allSteps[index];
                      final bool isDone = index < currentIndex;
                      final bool isCurrent = index == currentIndex;
                      final bool isUpcoming = index > currentIndex;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline indicator node (20px circle) & Connector line
                          Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone
                                      ? AppColors.primary
                                      : (isCurrent ? Colors.white : Colors.transparent),
                                  border: Border.all(
                                    color: isUpcoming ? AppColors.neutral : AppColors.primary,
                                    width: isCurrent ? 3.0 : 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isDone
                                    ? const Icon(Icons.check, size: 12, color: AppColors.onPrimary)
                                    : (isCurrent
                                        ? Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null),
                              ),
                              if (index < _allSteps.length - 1)
                                Container(
                                  width: 2,
                                  height: 40,
                                  color: isDone ? AppColors.primary : AppColors.divider,
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Step Label & Timestamp
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      step['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        color: isUpcoming ? AppColors.textSecondary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!isUpcoming)
                                    Text(
                                      step['time'] as String,
                                      style: AppTypography.caption,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Prototype State Switcher
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Column(
                      children: [
                        const Text('ADVANCE MILESTONE (PROTOTYPE)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            _stepBtn(ref, 'Preparing', OrderStatus.preparing),
                            _stepBtn(ref, 'Assigned', OrderStatus.driverAssigned),
                            _stepBtn(ref, 'Out for Delivery', OrderStatus.outForDelivery),
                            _stepBtn(ref, 'Delivered', OrderStatus.delivered),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Action
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
                ],
              ),
              child: AppPrimaryButton(
                label: 'View Live Delivery Map & Partner',
                onPressed: () => context.push('/live-map/$orderId'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(WidgetRef ref, String label, OrderStatus status) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        ref.read(orderProvider.notifier).setOrderStatus(status);
      },
    );
  }
}
