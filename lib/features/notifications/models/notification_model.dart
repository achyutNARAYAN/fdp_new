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
}

