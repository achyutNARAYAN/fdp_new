import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DeliveryIssueScreen extends StatelessWidget {
  final String orderId;

  const DeliveryIssueScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Order #$orderId')),
      body: const Center(child: Text('No delivery issue data available.')),
    );
  }
}
