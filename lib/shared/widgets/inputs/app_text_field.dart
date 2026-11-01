import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.prefix,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: maxLines == 1 ? AppDimensions.heightInput : null,
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.neutralLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            border: Border.all(
              color: hasError
                  ? AppColors.accent
                  : (enabled ? AppColors.neutralBorder : AppColors.neutralLight),
              width: hasError ? 2.0 : 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            readOnly: readOnly,
            onChanged: onChanged,
            onTap: onTap,
            maxLines: maxLines,
            style: AppTypography.body.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: AppTypography.caption.copyWith(
                color: hasError ? AppColors.accent : AppColors.textSecondary,
              ),
              hintText: hint,
              hintStyle: AppTypography.bodySmall,
              border: InputBorder.none,
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              suffixIcon: hasError
                  ? const Icon(Icons.error, color: AppColors.accent, size: 20)
                  : suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary, // Never amber text according to spec
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

