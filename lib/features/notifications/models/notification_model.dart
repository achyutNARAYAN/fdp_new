import 'package:flutter/material.dart';

enum NotificationCategory {
  all('All'),
  orders('Orders'),
  payments('Payments'),
  delivery('Delivery'),
  refunds('Refunds'),
  offers('Offers');

  final String label;
  const NotificationCategory(this.label);

  static NotificationCategory fromApiType(String? type) {
    final t = type?.toUpperCase() ?? '';
    if (t.contains('ORDER') || t.contains('STATUS')) {
      return NotificationCategory.orders;
    } else if (t.contains('PAYMENT')) {
      return NotificationCategory.payments;
    } else if (t.contains('DELIVERY') || t.contains('DRIVER')) {
      return NotificationCategory.delivery;
    } else if (t.contains('REFUND')) {
      return NotificationCategory.refunds;
    } else if (t.contains('OFFER') || t.contains('PROMO') || t.contains('COUPON')) {
      return NotificationCategory.offers;
    }
    return NotificationCategory.orders;
  }
}

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final IconData icon;
  final bool isRead;
  final String? deepLinkRoute;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    required this.icon,
    this.isRead = false,
    this.deepLinkRoute,
  });

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      category: category,
      icon: icon,
      isRead: isRead ?? this.isRead,
      deepLinkRoute: deepLinkRoute,
    );
  }

  factory NotificationItemModel.fromApi(Map<String, dynamic> json) {
    final category = NotificationCategory.fromApiType(json['type']?.toString());
    final dataMap = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;

    final String? orderId = dataMap?['orderId']?.toString();
    final String? route = orderId != null && orderId.isNotEmpty
        ? '/order-tracking/$orderId'
        : null;

    final dateStr = json['createdAt']?.toString();
    final dt = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

    IconData icon;
    switch (category) {
      case NotificationCategory.orders:
        icon = Icons.receipt_long;
        break;
      case NotificationCategory.payments:
        icon = Icons.payment;
        break;
      case NotificationCategory.delivery:
        icon = Icons.delivery_dining;
        break;
      case NotificationCategory.refunds:
        icon = Icons.currency_rupee;
        break;
      case NotificationCategory.offers:
        icon = Icons.local_offer;
        break;
      default:
        icon = Icons.notifications;
    }

    return NotificationItemModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['body']?.toString() ?? json['message']?.toString() ?? '',
      timestamp: dt,
      category: category,
      icon: icon,
      isRead: json['isRead'] == true,
      deepLinkRoute: route,
    );
  }
}
