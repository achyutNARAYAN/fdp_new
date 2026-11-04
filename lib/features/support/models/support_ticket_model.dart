enum TicketCategory {
  missingItem('Missing item', false),
  wrongItem('Wrong item', true),
  qualityOrTaste('Quality or taste issue', true),
  meltedOrSpoiled('Melted or spoiled', true),
  damagedPackaging('Damaged packaging', true),
  lateDelivery('Late delivery', false),
  notReceived('Order marked delivered but not received', false),
  paymentIssue('Payment issue', false),
  refundInquiry('Refund inquiry', false),
  other('Other inquiry', false);

  final String label;
  final bool requiresPhoto;
  const TicketCategory(this.label, this.requiresPhoto);
}

enum TicketStatus {
  open('Open'),
  inProgress('In Progress'),
  resolved('Resolved');

  final String label;
  const TicketStatus(this.label);
}

class TicketMessage {
  final String sender; // 'You' or 'Support Agent'
  final String message;
  final DateTime timestamp;
  final bool isAgent;

  const TicketMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isAgent,
  });
}

class SupportTicketModel {
  final String ticketId;
  final String orderId;
  final TicketCategory category;
  final String description;
  final TicketStatus status;
  final DateTime createdAt;
  final List<String> attachmentUrls;
  final List<TicketMessage> messages;
  final String? refundStatusId;

  const SupportTicketModel({
    required this.ticketId,
    required this.orderId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.attachmentUrls = const [],
    this.messages = const [],
    this.refundStatusId,
  });

  SupportTicketModel copyWith({
    TicketStatus? status,
    List<TicketMessage>? messages,
  }) {
    return SupportTicketModel(
      ticketId: ticketId,
      orderId: orderId,
      category: category,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      attachmentUrls: attachmentUrls,
      messages: messages ?? this.messages,
      refundStatusId: refundStatusId,
    );
  }
}

