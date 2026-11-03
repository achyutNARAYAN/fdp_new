import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum StatusChipType {
  success,
  pending,
  error,
  info,
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;
  final IconData? customIcon;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;

    switch (type) {
      case StatusChipType.success:
        bg = AppColors.primaryTint20;
        border = AppColors.primary;
        textColor = AppColors.textPrimary;
        icon = customIcon ?? Icons.check_circle_outline;
        break;
      case StatusChipType.pending:
        bg = Colors.white;
        border = AppColors.accent;
        textColor = AppColors.accent;
        icon = customIcon ?? Icons.schedule;
        break;
      case StatusChipType.error:
        bg = AppColors.accentTint12;
        border = AppColors.accent;
        textColor = AppColors.textPrimary;
        icon = customIcon ?? Icons.error_outline;
        break;
      case StatusChipType.info:
        bg = AppColors.neutralLight;
        border = Colors.transparent;
        textColor = AppColors.textSecondary;
        icon = customIcon ?? Icons.info_outline;
        break;
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != Colors.transparent ? Border.all(color: border, width: 1.2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

