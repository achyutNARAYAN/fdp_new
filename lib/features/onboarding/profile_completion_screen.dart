import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _termsAccepted = false;

  String? _nameError;
  String? _phoneError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.mobileNumber ?? '');
  }

  void _handleContinue() async {
    bool hasError = false;

    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(
        () =>
            _nameError = 'Please enter your full name (minimum 2 characters).',
      );
      hasError = true;
    } else {
      setState(() => _nameError = null);
    }

    final phone = _phoneController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (phone.length != 10 || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      setState(
        () =>
            _phoneError = 'Please enter a valid 10-digit Indian mobile number.',
      );
      hasError = true;
    } else {
      setState(() => _phoneError = null);
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept terms and conditions to proceed.'),
        ),
      );
      return;
    }

    if (!hasError) {
      setState(() => _isLoading = true);
      final authState = ref.read(authProvider);

      if (authState.status == AuthStatus.needsProfile) {
        await ref
            .read(authProvider.notifier)
            .completeRegistration(name: name, phone: phone);
      } else {
        await ref
            .read(authProvider.notifier)
            .updateProfile(name, null, null, null);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/delivery-location');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.p20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Mithai & More',
                      style: AppTypography.heading1,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Just a few details to personalize your sweet experience.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 24),

                    // Full Name (Required)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Full Name', style: AppTypography.itemName),
                        Text(
                          'Required',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'e.g. Aarav Sharma',
                      errorText: _nameError,
                      prefix: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mobile Number (Required for backend complete-registration)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mobile Number',
                          style: AppTypography.itemName,
                        ),
                        Text(
                          'Required',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: AppDimensions.heightInput,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusInput,
                        ),
                        border: Border.all(
                          color: _phoneError != null
                              ? AppColors.accent
                              : AppColors.neutralBorder,
                          width: _phoneError != null ? 2.0 : 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.neutralLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (_) {
                                if (_phoneError != null)
                                  setState(() => _phoneError = null);
                              },
                              decoration: const InputDecoration(
                                hintText: '10-digit mobile number',
                                hintStyle: AppTypography.bodySmall,
                                border: InputBorder.none,
                                counterText: '',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_phoneError != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _phoneError!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Terms checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.onPrimary,
                          onChanged: (val) =>
                              setState(() => _termsAccepted = val ?? true),
                        ),
                        Expanded(
                          child: Text(
                            'I accept the Terms & Conditions and Privacy Policy for sweets and perishable ordering.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom CTA
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.p16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: AppPrimaryButton(
                  label: 'Save & Choose Location',
                  isLoading: _isLoading,
                  onPressed: _handleContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
