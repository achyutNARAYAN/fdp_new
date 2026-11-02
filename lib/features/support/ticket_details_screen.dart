import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/support_ticket_model.dart';
import '../../shared/providers/support_provider.dart';
import '../../shared/widgets/badges/status_chip.dart';

class TicketDetailsScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailsScreen> createState() =>
      _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends ConsumerState<TicketDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support messaging API is unavailable.')),
    );
    _replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);
    final ticket = tickets
        .where((t) => t.ticketId == widget.ticketId)
        .firstOrNull;
    if (ticket == null) {
      return const Scaffold(
        body: Center(child: Text('No ticket data available.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ticket #${ticket.ticketId}'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ticket.category.label, style: AppTypography.heading2),
                    StatusChip(
                      label: ticket.status.label,
                      type: ticket.status == TicketStatus.resolved
                          ? StatusChipType.success
                          : StatusChipType.pending,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Order: #${ticket.orderId} • Opened ${Formatters.formatDate(ticket.createdAt)}',
                  style: AppTypography.caption,
                ),
                if (ticket.refundStatusId != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        context.push('/refund-status/${ticket.orderId}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint20,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Linked Refund Active • Tap to View Bank Status',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Conversation chat bubbles (Section 24 spec: customer in color.primary.tint20 on right, agent in white with border on left)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.p16),
              itemCount: ticket.messages.length,
              itemBuilder: (context, index) {
                final msg = ticket.messages[index];
                final isCustomer = !msg.isAgent;

                return Align(
                  alignment: isCustomer
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isCustomer
                          ? AppColors.primaryTint20
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: !isCustomer
                          ? Border.all(color: AppColors.neutralBorder, width: 1)
                          : null,
                      boxShadow: AppDimensions.elevationLevel1,
                    ),
                    child: Column(
                      crossAxisAlignment: isCustomer
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.sender,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCustomer
                                ? AppColors.textPrimary
                                : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.message,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatTime(msg.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Reply Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Type your message to support...',
                      hintStyle: AppTypography.bodySmall,
                      filled: true,
                      fillColor: AppColors.primaryTint10,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
