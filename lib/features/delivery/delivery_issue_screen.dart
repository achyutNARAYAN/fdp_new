import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';
import '../../shared/widgets/buttons/app_secondary_button.dart';

class DeliveryIssueScreen extends ConsumerWidget {
  final String orderId;

  const DeliveryIssueScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Issue Notice'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error-style Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentTint12,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.accent),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.report_problem, size: 28, color: AppColors.accent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('We couldn’t deliver your order yet.', style: AppTypography.heading2),
                          SizedBox(height: 4),
                          Text(
                            'Your delivery partner is at your building gate but unable to reach your phone.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Perishable Cold-chain Policy Reminder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.ac_unit, size: 16, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text('Perishable Confectionery Notice', style: AppTypography.itemName),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Because sweets and ice cream lose thermal stability, the partner can wait for a maximum of 10 minutes at your address.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Partner Waiting Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vikram Singh (Waiting outside gate)', style: AppTypography.itemName),
                          Text('Attempted 2 calls • 4 minutes ago', style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Stack
              AppPrimaryButton(
                label: 'Call Delivery Partner Now',
                icon: Icons.phone,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing partner via masked connection...')),
                  );
                },
              ),
              const SizedBox(height: 10),

              AppSecondaryButton(
                label: 'Update Gate / Delivery Note',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gate note sent to partner app.')),
                  );
                },
              ),
              const SizedBox(height: 10),

              AppSecondaryButton(
                label: 'Contact Support Helpdesk',
                onPressed: () => context.push('/support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
