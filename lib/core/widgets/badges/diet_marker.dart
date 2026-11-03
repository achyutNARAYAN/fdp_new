import 'package:flutter/material.dart';
import '../../../features/item/models/diet_type.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';

/// Section 23: Diet marker. 16px rounded square with 1.5px border and centered 8px dot,
/// standard regulatory colors. Accompanied by visible text label.
class DietMarker extends StatelessWidget {
  final DietType dietType;
  final bool showLabel;

  const DietMarker({
    super.key,
    required this.dietType,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: dietType.color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: dietType.color,
          shape: BoxShape.circle,
        ),
      ),
    );

    if (!showLabel) return symbol;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        symbol,
        const SizedBox(width: 6),
        Text(
          dietType.label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

