import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/support_provider.dart';
import '../../shared/widgets/badges/status_chip.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class SupportCenterScreen extends ConsumerWidget {
  const SupportCenterScreen({super.key});

  static const List<Map<String, dynamic>> _supportCategories = [
    {'title': 'Active Orders', 'icon': Icons.local_shipping_outlined},
    {'title': 'Payment & UPI', 'icon': Icons.account_balance_wallet_outlined},
    {'title': 'Cold-Chain Delivery', 'icon': Icons.ac_unit_outlined},
    {'title': 'Taste & Freshness', 'icon': Icons.restaurant_outlined},
    {'title': 'Refunds & Reversals', 'icon': Icons.currency_exchange_outlined},
    {'title': 'Account & Privacy', 'icon': Icons.person_outline},
  ];

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How does the 3-minute shop confirmation work?',
      'a': 'When you place an order, our live kitchen terminal notifies the shop confectioner. They verify fresh batches and kitchen inventory within 3 minutes (03:00). If accepted, preparation begins immediately.'
    },
    {
      'q': 'What happens if ice cream or gelato melts?',
      'a': 'All ice creams and desserts are packed in insulated thermal pouches. If an item arrives melted due to traffic delays, you can report it within 2 hours with a photo for an immediate reversal.'
    },
    {
      'q': 'Can I cancel an order once placed?',
      'a': 'Cancellation is 100% free while the order is waiting for confirmation. Once preparation starts, cancellation may not be possible, especially for custom engraved cakes.'
    },
    {
      'q': 'When will my refund reflect in my account?',
      'a': 'UPI refunds typically credit back within 2–4 hours. Card and Net Banking refunds take 2–4 business days depending on your bank clearing cycle.'
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final activeOrder = orderState.activeOrder;
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Help & Support'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Action Card for Active Order
            if (activeOrder != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint20,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Need help with your current order?', style: AppTypography.itemName),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${activeOrder.orderId} from ${activeOrder.shopName}',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => context.push('/order-tracking/${activeOrder.orderId}'),
                            child: const Text('Track Order Status', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => context.push('/raise-ticket?orderId=${activeOrder.orderId}'),
                            child: const Text('Report Issue', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Active Support Tickets Card
            if (tickets.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Support Tickets', style: AppTypography.sectionTitle),
                  Text('${tickets.length} total', style: AppTypography.caption),
                ],
              ),
              const SizedBox(height: 8),
              ...tickets.map((t) {
                return GestureDetector(
                  onTap: () => context.push('/ticket-details/${t.ticketId}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: AppColors.accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ticket #${t.ticketId} • ${t.category.label}', style: AppTypography.itemName.copyWith(fontSize: 13)),
                              Text(t.description, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        StatusChip(label: t.status.label, type: t.status.name == 'resolved' ? StatusChipType.success : StatusChipType.pending),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // 2x3 Category Grid (Section 24 visual spec)
            const Text('Browse Help Topics', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _supportCategories.map((cat) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutralLight),
                  ),
                  child: Row(
                    children: [
                      Icon(cat['icon'] as IconData, size: 22, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat['title'] as String,
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // FAQs
            const Text('Frequently Asked Questions', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                children: _faqs.map((faq) {
                  return ExpansionTile(
                    title: Text(faq['q']!, style: AppTypography.itemName.copyWith(fontSize: 14)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(faq['a']!, style: AppTypography.bodySmall.copyWith(height: 1.4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Raise ticket CTA
            AppPrimaryButton(
              label: 'Raise a Support Ticket',
              icon: Icons.add_comment_outlined,
              onPressed: () => context.push('/raise-ticket'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

