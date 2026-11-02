import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';

class DeliveryTimeScreen extends StatelessWidget {
  const DeliveryTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choose Delivery Time')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.p24),
          child: Text(
            'No delivery slots were returned by the API.',
            style: AppTypography.bodySmall,
          ),
        ),
      ),
    );
  }
}
