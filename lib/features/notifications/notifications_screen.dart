import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);

    final filtered = notifications.where((n) {
      if (_selectedCategory == NotificationCategory.all) return true;
      return n.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications Hub'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            child: const Text('Mark all read', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: NotificationCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: AppColors.primaryTint20,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.neutralBorder),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Notification Cards List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No notifications in this category', style: AppTypography.bodySmall))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.p16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(notificationProvider.notifier).markAsRead(notif.id);
                          if (notif.deepLinkRoute != null) {
                            context.push(notif.deepLinkRoute!);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                            border: Border.all(
                              color: !notif.isRead ? AppColors.primary : AppColors.neutralLight,
                              width: !notif.isRead ? 1.5 : 1.0,
                            ),
                            boxShadow: AppDimensions.elevationLevel1,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category icon in color.primary.tint20 circle (Section 24)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryTint20,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(notif.icon, color: AppColors.textPrimary, size: 22),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: !notif.isRead ? FontWeight.bold : FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!notif.isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(notif.message, style: AppTypography.bodySmall),
                                    const SizedBox(height: 6),
                                    Text(Formatters.formatDate(notif.timestamp), style: AppTypography.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

