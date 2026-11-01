import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLanguageSheet(BuildContext context, WidgetRef ref, String currentLang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusBottomSheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose App Language', style: AppTypography.heading2),
            const SizedBox(height: 12),
            ...['English', 'हिन्दी (Hindi)', 'ಕನ್ನಡ (Kannada)'].map((lang) {
              final isChosen = currentLang == lang;
              return ListTile(
                title: Text(lang, style: AppTypography.body),
                trailing: isChosen ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLanguage(lang);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDeactivationDialog(BuildContext context, WidgetRef ref) {
    final orderState = ref.read(orderProvider);
    final active = orderState.activeOrder;
    final bool hasActiveOrder = active != null &&
        active.orderStatus != OrderStatus.delivered &&
        active.orderStatus != OrderStatus.cancelled &&
        active.orderStatus != OrderStatus.declined;

    if (hasActiveOrder) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusDialog)),
          title: const Text('Cannot Deactivate Account', style: AppTypography.heading2),
          content: Text(
            'You currently have an active confectionery order (#${active.orderId}).\nPlease complete or cancel active orders before deactivating your profile.',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/order-tracking/${active.orderId}');
              },
              child: const Text('View Active Order'),
            ),
          ],
        ),
      );
      return;
    }

    // Deactivation Confirmation Flow
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusDialog)),
        title: const Text('Deactivate Your Account?', style: AppTypography.heading2),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deactivating your account will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Clear your saved delivery addresses and preferences.'),
            Text('• Disable active loyalty reward benefits.'),
            Text('• In accordance with Indian GST regulations, tax invoices will be securely retained for statutory compliance.'),
            SizedBox(height: 12),
            Text(
              'A verification code will be sent to your mobile before deactivation.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep My Account'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account has been deactivated.')),
              );
            },
            child: const Text('Confirm Deactivation', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferences Group
            const Text('App Preferences', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.textPrimary),
                    title: const Text('App Language', style: AppTypography.itemName),
                    subtitle: Text(settings.selectedLanguage, style: AppTypography.caption),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageSheet(context, ref, settings.selectedLanguage),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.textPrimary),
                    title: const Text('Order Status Updates', style: AppTypography.itemName),
                    subtitle: const Text('Essential updates on preparation and driver arrival', style: AppTypography.caption),
                    value: settings.orderNotificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) => ref.read(settingsProvider.notifier).toggleOrderNotifications(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.campaign_outlined, color: AppColors.textPrimary),
                    title: const Text('Offers & Festive Treats', style: AppTypography.itemName),
                    subtitle: const Text('Respects quiet hours (no night notifications)', style: AppTypography.caption),
                    value: settings.promotionalNotificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) => ref.read(settingsProvider.notifier).togglePromotionalNotifications(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration, color: AppColors.textPrimary),
                    title: const Text('Gentle Haptics', style: AppTypography.itemName),
                    subtitle: const Text('Soft feedback on cart and confirmation', style: AppTypography.caption),
                    value: settings.hapticsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) => ref.read(settingsProvider.notifier).toggleHaptics(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal & About
            const Text('Legal & Compliance', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Terms of Food Delivery & Confectionery Service', style: AppTypography.body),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Privacy Policy & Data Security', style: AppTypography.body),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('FSSAI Compliance Standards', style: AppTypography.body),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Danger Zone (Deactivate Account)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Deactivate Account',
                        style: AppTypography.itemName.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Permanently remove personal addresses and profile preferences. Statutory tax records will be retained.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showDeactivationDialog(context, ref),
                    child: const Text('Deactivate My Account', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // App Version
            const Center(
              child: Text(
                'Mithai & More v1.0.0 (Build 2026.10)\nCrafted with care in Bengaluru, India',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
