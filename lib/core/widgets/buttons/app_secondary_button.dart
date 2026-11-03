import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Section 23: Secondary button. 52 high, transparent, 1.5px color.neutral.border,
/// label in color.text.primary. Pressed: color.primary.tint10 fill.
class AppSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final Color? borderColor;
  final Color? textColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.borderColor,
    this.textColor,
  });

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final Color border = widget.borderColor ?? AppColors.neutralBorder;
    final Color text = widget.textColor ?? AppColors.textPrimary;

    return AnimatedScale(
      scale: _isPressed && !isDisabled ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: AppDimensions.heightButton,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: _isPressed ? AppColors.primaryTint10 : Colors.transparent,
              side: BorderSide(
                color: isDisabled ? AppColors.neutralLight : border,
                width: 1.5,
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
            ),
            onPressed: widget.onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: text),
                  const SizedBox(width: AppDimensions.p8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: AppTypography.itemName.copyWith(
                      color: isDisabled ? AppColors.textSecondary : text,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

