import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Section 23: Primary button. 52 high, radius 16, Sage Green fill, label 16/20 semibold in color.on-primary.
/// Pressed: color.primary.pressed with scale 0.98.
/// Disabled: Concrete Grey 20% fill with color.text.secondary label.
/// Loading: 20px spinner.
class AppPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;
  final double? width;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.width,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled
                  ? AppColors.neutralLight
                  : (_isPressed ? AppColors.primaryPressed : AppColors.primary),
              foregroundColor: isDisabled ? AppColors.textSecondary : AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
            ),
            onPressed: isDisabled ? null : widget.onPressed,
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                    ),
                  )
                : widget.isSuccess
                    ? const Icon(Icons.check, color: AppColors.onPrimary, size: 22)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: AppColors.onPrimary),
                            const SizedBox(width: AppDimensions.p8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              style: AppTypography.itemName.copyWith(
                                color: isDisabled ? AppColors.textSecondary : AppColors.onPrimary,
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

