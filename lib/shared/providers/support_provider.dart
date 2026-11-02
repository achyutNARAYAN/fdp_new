import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket_model.dart';

final supportTicketsProvider = StateProvider<List<SupportTicketModel>>(
  (ref) => const [],
);
