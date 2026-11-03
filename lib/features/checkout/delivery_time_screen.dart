import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class DeliveryTimeScreen extends StatefulWidget {
  const DeliveryTimeScreen({super.key});

  @override
  State<DeliveryTimeScreen> createState() => _DeliveryTimeScreenState();
}

class _DeliveryTimeScreenState extends State<DeliveryTimeScreen> {
  int _selectedSlot = 0;

  final List<Map<String, String>> _slots = [
    {
      'title': 'Standard Delivery (30-45 mins)',
      'subtitle': 'Fastest fresh delivery from the sweet shop kitchen',
      'tag': 'RECOMMENDED',
    },
    {
      'title': 'Evening Slot (5:00 PM - 7:00 PM)',
      'subtitle': 'Perfect for evening tea & snacks',
      'tag': 'TODAY',
    },
    {
      'title': 'Night Slot (8:00 PM - 10:00 PM)',
      'subtitle': 'After-dinner sweet cravings & desserts',
      'tag': 'TODAY',
    },
    {
      'title': 'Tomorrow Morning (10:00 AM - 12:00 PM)',
      'subtitle': 'Freshly prepared morning batch',
      'tag': 'TOMORROW',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Delivery Time'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Delivery Slot',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose when you would like your sweets & desserts delivered.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.separated(
                  itemCount: _slots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final slot = _slots[index];
                    final isSelected = _selectedSlot == index;

                    return InkWell(
                      onTap: () => setState(() => _selectedSlot = index),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.p16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryTint10 : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.neutralLight,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: AppDimensions.elevationLevel1,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.neutral,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          slot['title']!,
                                          style: AppTypography.itemName.copyWith(fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primaryTint20 : AppColors.neutralLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          slot['tag']!,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? AppColors.primaryPressed : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    slot['subtitle']!,
                                    style: AppTypography.caption,
                                  ),
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

              AppPrimaryButton(
                label: 'Confirm Delivery Time',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
