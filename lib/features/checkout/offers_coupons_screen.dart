import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';

class OffersCouponsScreen extends StatelessWidget {
  const OffersCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Coupons'),
        backgroundColor: AppColors.surface,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.p24),
          child: Text('No offers available.', style: AppTypography.bodySmall),
        ),
      ),
    );
  }
}
