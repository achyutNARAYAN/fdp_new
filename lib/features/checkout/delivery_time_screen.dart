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
  bool _isSchedule = false;
  int _selectedDateIndex = 0;
  String _selectedSlot = '04:00 PM - 05:00 PM';

  static const List<String> _dates = ['Today, 29 Oct', 'Tomorrow, 30 Oct', 'Fri, 31 Oct'];

  static const List<Map<String, dynamic>> _slots = [
    {'time': '02:00 PM - 03:00 PM', 'isFull': true},
    {'time': '03:00 PM - 04:00 PM', 'isFull': false},
    {'time': '04:00 PM - 05:00 PM', 'isFull': false},
    {'time': '05:00 PM - 06:00 PM', 'isFull': false},
    {'time': '06:00 PM - 07:00 PM', 'isFull': false},
    {'time': '07:00 PM - 08:00 PM', 'isFull': false},
    {'time': '08:00 PM - 09:00 PM', 'isFull': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Delivery Time'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Segmented Control: Deliver Now vs Schedule
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSchedule = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !_isSchedule ? AppColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isSchedule ? AppDimensions.elevationLevel1 : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Deliver Now (30 min)',
                                style: TextStyle(
                                  fontWeight: !_isSchedule ? FontWeight.bold : FontWeight.normal,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSchedule = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isSchedule ? AppColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isSchedule ? AppDimensions.elevationLevel1 : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Schedule for Later',
                                style: TextStyle(
                                  fontWeight: _isSchedule ? FontWeight.bold : FontWeight.normal,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_isSchedule) ...[
                    // Deliver Now Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, size: 28, color: AppColors.accent),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Instant Confectionery Dispatch', style: AppTypography.itemName),
                                SizedBox(height: 2),
                                Text(
                                  'Estimated delivery in 25–35 min once confirmed by shop.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Date Strip
                    const Text('Select Date', style: AppTypography.itemName),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(_dates.length, (index) {
                        final isSelected = _selectedDateIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDateIndex = index),
                            child: Container(
                              margin: EdgeInsets.only(right: index < _dates.length - 1 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryTint20 : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _dates[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Lead Time Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Speciality cakes & custom batches require at least 3 hours preparation lead time.',
                              style: AppTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3-Column Slot Chips
                    const Text('Select Time Slot', style: AppTypography.itemName),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots.map((slot) {
                        final time = slot['time'] as String;
                        final isFull = slot['isFull'] as bool;
                        final isSelected = _selectedSlot == time;

                        return ChoiceChip(
                          label: Text(isFull ? '$time (Full)' : time),
                          selected: isSelected && !isFull,
                          selectedColor: AppColors.primaryTint20,
                          backgroundColor: isFull ? AppColors.neutralLight : AppColors.surface,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isFull ? AppColors.textSecondary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: isFull
                              ? null
                              : (val) {
                                  if (val) setState(() => _selectedSlot = time);
                                },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(AppDimensions.p16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
              ],
            ),
            child: AppPrimaryButton(
              label: 'Confirm Delivery Time',
              onPressed: () {
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

