import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../../../core/services/notification_api_service.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItemModel>> {
  final NotificationApiService _api;
  int _remoteUnreadCount = 0;

  NotificationNotifier({NotificationApiService? api})
      : _api = api ?? notificationApiService,
        super(const []) {
    loadInbox();
  }

  int get unreadCount =>
      state.isNotEmpty ? state.where((n) => !n.isRead).length : _remoteUnreadCount;

  Future<void> loadInbox() async {
    try {
      final list = await _api.getInbox();
      if (list.isNotEmpty) {
        state = list;
      }
      _remoteUnreadCount = await _api.getUnreadCount();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _api.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _remoteUnreadCount = 0;
    await _api.markAllAsRead();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItemModel>>((
      ref,
    ) {
      return NotificationNotifier();
    });
