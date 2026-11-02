import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class LiveDeliveryMapScreen extends StatelessWidget {
  final String orderId;

  const LiveDeliveryMapScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Order #$orderId')),
      body: const Center(
        child: Text(
          'Live tracking data is unavailable.',
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
