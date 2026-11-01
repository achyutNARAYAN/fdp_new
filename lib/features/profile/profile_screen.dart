import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          children: [
            // Header card with Initials Avatar & Completion bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
                boxShadow: AppDimensions.elevationLevel1,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Sage Green circle initials avatar with color.on-primary text (Section 24)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user?.initials ?? 'AS',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.fullName ?? 'Aarav Sharma', style: AppTypography.heading2),
                            const SizedBox(height: 2),
                            Text(user?.mobileNumber ?? '+91 98765 43210', style: AppTypography.caption),
                            if (user?.email != null)
                              Text(user!.email!, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
                        onPressed: () => context.push('/edit-profile'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Profile Completion Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Profile Completion', style: AppTypography.caption),
                          Text(
                            '${user?.profileCompletionPercentage ?? 85}%',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (user?.profileCompletionPercentage ?? 85) / 100.0,
                          minHeight: 6,
                          backgroundColor: AppColors.neutralLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Grouped 56 high List Rows with 24px icons
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                children: [
                  _profileRow(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Orders & Reorder Hub',
                    route: '/orders',
                  ),
                  const Divider(height: 1),
                  _profileRow(
                    context,
                    icon: Icons.place_outlined,
                    title: 'Saved Delivery Addresses',
                    route: '/saved-addresses',
                  ),
                  const Divider(height: 1),
                  _profileRow(
                    context,
                    icon: Icons.favorite_border,
                    title: 'Favorites & Frequents',
                    route: '/favorites',
                  ),
                  const Divider(height: 1),
                  _profileRow(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Notifications Hub',
                    route: '/notifications',
                  ),
                  const Divider(height: 1),
                  _profileRow(
                    context,
                    icon: Icons.support_agent_outlined,
                    title: 'Support & Help Center',
                    route: '/support',
                  ),
                  const Divider(height: 1),
                  _profileRow(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'App Settings & Language',
                    route: '/settings',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            TextButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.accent, size: 20),
              label: const Text('Log Out of Account', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, size: 24, color: AppColors.textPrimary),
      title: Text(title, style: AppTypography.itemName.copyWith(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
      onTap: () => context.push(route),
    );
  }
}

