import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Section 23: Order status is a rounded rectangle (radius 8) with a package/order icon.
/// Never combine with payment status badge.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon = status.icon;

    switch (status) {
      case OrderStatus.delivered:
      case OrderStatus.orderConfirmed:
        bg = AppColors.primaryTint20;
        border = AppColors.primary;
        text = AppColors.textPrimary;
        break;
      case OrderStatus.confirmingOrder:
      case OrderStatus.changesProposed:
      case OrderStatus.scheduled:
        bg = AppColors.accentTint12;
        border = AppColors.accent;
        text = AppColors.accentPressed;
        break;
      case OrderStatus.declined:
      case OrderStatus.deliveryFailed:
      case OrderStatus.cancelled:
        bg = AppColors.accentTint12;
        border = AppColors.accent;
        text = AppColors.accentPressed;
        break;
      default:
        bg = AppColors.primaryTint10;
        border = AppColors.neutralBorder;
        text = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8), // Explicit 8px rounded rectangle
        border: Border.all(color: border.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 5),
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

