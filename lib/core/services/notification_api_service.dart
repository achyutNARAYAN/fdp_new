import 'dart:io';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'package:fdp/features/notifications/models/notification_model.dart';

class NotificationApiService {
  final ApiClient _client;

  NotificationApiService({ApiClient? client})
      : _client = client ?? globalApiClient;

  /// Register FCM Device Push Token
  /// POST /notifications/device-token
  Future<bool> registerDeviceToken({
    required String token,
    String? platform,
    String? deviceModel,
    String? appVersion,
  }) async {
    String detectedPlatform = platform ?? 'ANDROID';
    if (platform == null) {
      if (Platform.isIOS) {
        detectedPlatform = 'IOS';
      } else if (Platform.isAndroid) {
        detectedPlatform = 'ANDROID';
      } else {
        detectedPlatform = 'WEB';
      }
    }

    try {
      final res = await _client.post(
        ApiConstants.notificationsDeviceToken,
        body: {
          'token': token,
          'platform': detectedPlatform,
          if (deviceModel != null) 'deviceModel': deviceModel,
          if (appVersion != null) 'appVersion': appVersion,
        },
      );
      return res.success;
    } catch (_) {
      return false;
    }
  }

  /// Unregister FCM Device Push Token on logout
  /// DELETE /notifications/device-token
  Future<bool> unregisterDeviceToken(String token) async {
    try {
      final res = await _client.delete(
        ApiConstants.notificationsDeviceToken,
        body: {'token': token},
      );
      return res.success;
    } catch (_) {
      return false;
    }
  }

  /// Get In-App Notifications Inbox
  /// GET /notifications/inbox
  Future<List<NotificationItemModel>> getInbox({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'limit': limit,
      'unreadOnly': unreadOnly,
    };

    final res = await _client.get(ApiConstants.notificationsInbox, queryParams: qp);
    if (res.data is List) {
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationItemModel.fromApi(e))
          .toList();
    }
    return const [];
  }

  /// Get lightweight unread count for badges
  /// GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final res = await _client.get(ApiConstants.notificationsUnreadCount);
      if (res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        return (map['unreadCount'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Mark all notifications as read
  /// PATCH /notifications/read-all
  Future<bool> markAllAsRead() async {
    try {
      final res = await _client.patch(ApiConstants.notificationsReadAll);
      return res.success;
    } catch (_) {
      return false;
    }
  }

  /// Mark single notification as read
  /// PATCH /notifications/{id}/read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final res = await _client.patch(ApiConstants.notificationRead(notificationId));
      return res.success;
    } catch (_) {
      return false;
    }
  }
}

final notificationApiService = NotificationApiService();

