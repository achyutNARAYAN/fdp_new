import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../data/mock_data.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItemModel>> {
  NotificationNotifier() : super(MockData.getInitialNotifications());

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationItemModel>>((ref) {
  return NotificationNotifier();
});

