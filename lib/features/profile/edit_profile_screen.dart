import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  String _gender = '';
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _dobController = TextEditingController(
      text: user?.dateOfBirth != null
          ? '${user!.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
          : '',
    );
    _gender = user?.gender ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ref
        .read(authProvider.notifier)
        .updateProfile(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _dob,
          _gender,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    context.pop();
  }

  void _promptMobileChange() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        title: const Text(
          'Change Verified Mobile?',
          style: AppTypography.heading2,
        ),
        content: const Text(
          'Changing your registered Indian mobile number requires fresh OTP verification.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('Verify New Number'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    hint: 'Your Name',
                  ),
                  const SizedBox(height: 16),

                  // Read-only Verified Mobile
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusInput,
                      ),
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verified Mobile Number',
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.mobileNumber ?? '+91 98765 43210',
                              style: AppTypography.itemName,
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _promptMobileChange,
                          child: const Text(
                            'Change',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _emailController,
                    label: 'Email (for GST Invoices)',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _dobController,
                    label: 'Date of Birth',
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _dob ??
                            ref.read(authProvider).user?.dateOfBirth ??
                            DateTime.now(),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _dob = picked;
                          _dobController.text =
                              '${picked.day}/${picked.month}/${picked.year}';
                        });
                      }
                    },
                    suffix: const Icon(Icons.calendar_today, size: 18),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Gender (Optional)',
                    style: AppTypography.itemName,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Male', 'Female', 'Prefer not to say'].map((g) {
                      final isSelected = _gender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = g),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryTint20
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.neutralBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              g,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA (with SafeArea for mobile home bar)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14171A14),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: AppPrimaryButton(
                label: 'Save Profile Changes',
                onPressed: _saveProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
