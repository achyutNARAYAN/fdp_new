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
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabs = ['All', 'Active', 'Delivered', 'Cancelled', 'Returned'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final pastOrders = orderState.pastOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Confectionery Orders'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3.0,
          labelColor: AppColors.textPrimary,
          labelStyle: AppTypography.itemName,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          final filtered = pastOrders.where((o) {
            if (tab == 'Active') {
              return o.orderStatus != OrderStatus.delivered &&
                  o.orderStatus != OrderStatus.cancelled &&
                  o.orderStatus != OrderStatus.declined &&
                  o.orderStatus != OrderStatus.returned;
            } else if (tab == 'Delivered') {
              return o.orderStatus == OrderStatus.delivered;
            } else if (tab == 'Cancelled') {
              return o.orderStatus == OrderStatus.cancelled || o.orderStatus == OrderStatus.declined;
            } else if (tab == 'Returned') {
              return o.orderStatus == OrderStatus.returned;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.p32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.neutral),
                    const SizedBox(height: 16),
                    Text('No $tab Orders', style: AppTypography.heading2),
                    const SizedBox(height: 8),
                    const Text('Your past sweet treat requests will appear here.', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(orderProvider.notifier).loadOrders(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.p16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
              final order = filtered[index];
              final bool needsAction = order.orderStatus == OrderStatus.changesProposed;
              final bool hasRefund = order.refundAmount != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(
                    color: needsAction ? AppColors.accent : AppColors.neutralLight,
                    width: needsAction ? 1.5 : 1.0,
                  ),
                  boxShadow: AppDimensions.elevationLevel1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop, Total & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.shopName, style: AppTypography.heading2.copyWith(fontSize: 16)),
                        Text(
                          Formatters.formatCurrency(order.totalAmount),
                          style: AppTypography.price.copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.orderId} • ${Formatters.formatDate(order.createdAt)}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 12),

                    // Separate Order & Payment Badges (Section 5)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OrderStatusBadge(status: order.orderStatus),
                        PaymentStatusBadge(status: order.paymentStatus),
                        if (order.deliveryOtp != null &&
                            order.deliveryOtp!.isNotEmpty &&
                            order.orderStatus != OrderStatus.delivered &&
                            order.orderStatus != OrderStatus.cancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint20,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              'OTP: ${order.deliveryOtp}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPressed,
                              ),
                            ),
                          ),
                        if (hasRefund)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint20,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Refund Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Item names
                    Text(
                      order.items.map((i) => '${i.quantity}x ${i.item.name}').join(', '),
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 14),

                    // Actions
                    Row(
                      children: [
                        if (order.orderStatus != OrderStatus.delivered &&
                            order.orderStatus != OrderStatus.cancelled &&
                            order.orderStatus != OrderStatus.declined) ...[
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => context.push('/order-tracking/${order.orderId}'),
                              child: const Text('Track Order'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Details',
                            onPressed: () => context.push('/order-details/${order.orderId}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
      ),
    );
  }
}

