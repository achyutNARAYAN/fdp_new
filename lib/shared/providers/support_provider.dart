import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket_model.dart';

class SupportTicketNotifier extends StateNotifier<List<SupportTicketModel>> {
  SupportTicketNotifier()
      : super([
          SupportTicketModel(
            ticketId: 'TCK-8812',
            orderId: 'FD10198',
            category: TicketCategory.meltedOrSpoiled,
            description: 'The gelato arrived partially melted due to traffic delay.',
            status: TicketStatus.resolved,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            attachmentUrls: ['https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400'],
            refundStatusId: 'REF_9921',
            messages: [
              TicketMessage(
                sender: 'You',
                message: 'Hello, the gelato tub was melted when delivered.',
                timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
                isAgent: false,
              ),
              TicketMessage(
                sender: 'Support Agent (Pooja)',
                message: 'We are truly sorry for the cold-chain issue. A full refund of ₹451 has been initiated to your original payment method.',
                timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
                isAgent: true,
              ),
            ],
          )
        ]);

  String createTicket({
    required String orderId,
    required TicketCategory category,
    required String description,
    List<String> attachments = const [],
  }) {
    final ticketId = 'TCK-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final ticket = SupportTicketModel(
      ticketId: ticketId,
      orderId: orderId,
      category: category,
      description: description,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      attachmentUrls: attachments,
      messages: [
        TicketMessage(
          sender: 'You',
          message: description,
          timestamp: DateTime.now(),
          isAgent: false,
        ),
        TicketMessage(
          sender: 'Support Assistant',
          message: 'Thank you for reporting this. Our food care specialist is reviewing your order details.',
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          isAgent: true,
        ),
      ],
    );
    state = [ticket, ...state];
    return ticketId;
  }

  void addMessage(String ticketId, String messageText) {
    state = state.map((t) {
      if (t.ticketId == ticketId) {
        final msgs = List<TicketMessage>.from(t.messages);
        msgs.add(TicketMessage(
          sender: 'You',
          message: messageText,
          timestamp: DateTime.now(),
          isAgent: false,
        ));
        return t.copyWith(messages: msgs);
      }
      return t;
    }).toList();
  }
}

final supportTicketsProvider = StateNotifierProvider<SupportTicketNotifier, List<SupportTicketModel>>((ref) {
  return SupportTicketNotifier();
});

