import 'package:flutter/material.dart';
import '../../../features/orders/models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Section 23: Payment status is a fully rounded pill with a rupee icon.
/// Distinct shape (pill) vs order status (radius 8 rectangle).
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case PaymentStatus.paid:
      case PaymentStatus.codCollected:
      case PaymentStatus.refundCompleted:
        bg = AppColors.primaryTint20;
        border = AppColors.primary;
        text = AppColors.textPrimary;
        break;
      case PaymentStatus.processing:
      case PaymentStatus.pending:
      case PaymentStatus.codPending:
        bg = Colors.white;
        border = AppColors.accent;
        text = AppColors.accentPressed;
        break;
      case PaymentStatus.failed:
        bg = AppColors.accentTint12;
        border = AppColors.accent;
        text = AppColors.accentPressed;
        break;
      case PaymentStatus.refundInitiated:
        bg = AppColors.primaryTint10;
        border = AppColors.neutralBorder;
        text = AppColors.textPrimary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999), // Fully rounded pill
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.currency_rupee, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.caption.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

