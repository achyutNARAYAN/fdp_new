import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isSuccessMorph = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  void _verifyOtp() async {
    final code = _enteredCode;
    if (code.length < 6) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(code);
    if (success) {
      setState(() {
        _isSuccessMorph = true;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.needsProfile) {
          context.go('/profile-completion');
        } else {
          context.go('/home');
        }
      }
    } else {
      setState(() {
        _errorMessage =
            ref.read(authProvider).errorMessage ??
            'That code isn’t right. Please try again.';
      });
    }
  }

  void _resendOtp() {
    _startTimer();
    final id = ref.read(authProvider).identifier;
    if (id == null) return;
    ref.read(authProvider.notifier).sendOtp(id);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Verification Code',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${authState.identifier ?? "your email"}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),

              // Responsive OTP Boxes or Success Morph
              if (!_isSuccessMorph)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    final double calculatedWidth = ((availableWidth - 30) / 6)
                        .clamp(36.0, 48.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final hasValue = _controllers[index].text.isNotEmpty;
                        return SizedBox(
                          width: calculatedWidth,
                          height: 56,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: hasValue
                                  ? AppColors.primaryTint20
                                  : AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusInput,
                                ),
                                borderSide: BorderSide(
                                  color: _errorMessage != null
                                      ? AppColors.accent
                                      : (hasValue
                                            ? AppColors.primary
                                            : AppColors.neutralBorder),
                                  width: _errorMessage != null ? 2.0 : 1.5,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                              if (val.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              if (_enteredCode.length == 6) {
                                _verifyOtp();
                              }
                            },
                          ),
                        );
                      }),
                    );
                  },
                )
              else
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 36,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Resend and Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                    child: Text(
                      _secondsRemaining == 0
                          ? 'Resend OTP'
                          : 'Resend in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _secondsRemaining == 0
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Change email',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              AppPrimaryButton(
                label: 'Verify & Proceed',
                onPressed: _enteredCode.length == 6 ? _verifyOtp : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
