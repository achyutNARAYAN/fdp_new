import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/auth/providers/auth_provider.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: ApiConfig.googleServerClientId,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleEmailContinue() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _emailError = null;
      _isLoading = true;
    });

    final sent = await ref.read(authProvider.notifier).sendOtp(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authProvider).errorMessage ??
                  'Could not send the verification code.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification code sent.')));
      context.push('/otp-verification');
    }
  }

  void _showGoogleSetupDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(child: Text(title, style: AppTypography.heading2)),
          ],
        ),
        content: Text(message, style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        setState(() => _isGoogleLoading = false);
        if (mounted) {
          _showGoogleSetupDialog(
            context,
            'Server ID Token Required',
            'Google Sign-In authenticated locally on this device, but did not return an OpenID idToken required by the backend.\n\n'
                'To link with your live backend, specify your Web Client ID in `ApiConfig.googleServerClientId`.\n\n'
                'Use Email OTP to sign in with your account.',
          );
        }
        return;
      }

      final success = await ref
          .read(authProvider.notifier)
          .signInWithGoogle(idToken);
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        if (success) {
          final authState = ref.read(authProvider);
          if (authState.status == AuthStatus.needsProfile) {
            context.go('/profile-completion');
          } else {
            context.go('/home');
          }
        } else {
          final err =
              ref.read(authProvider).errorMessage ?? 'Google sign-in failed.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        final errStr = e.toString();
        if (defaultTargetPlatform == TargetPlatform.android &&
            (errStr.contains('10') || errStr.contains('ApiException'))) {
          _showGoogleSetupDialog(
            context,
            'Google Cloud Setup Needed',
            'Android ApiException 10 (DEVELOPER_ERROR):\n\n'
                'Google Play Services could not verify the app configuration.\n\n'
                'Required steps for real Google Sign-In on Android:\n'
                '1. Create an OAuth 2.0 Client ID for package `com.example.fdp` in Google Cloud Console.\n'
                '2. Add your debug SHA-1 keystore fingerprint.\n'
                '3. Set your Web Client ID in `ApiConfig.googleServerClientId`.\n\n'
                'Check that the app package name and signing SHA-1 are registered in Google Cloud Console, and that this Web Client ID is configured as the backend audience.',
          );
        } else {
          final message = defaultTargetPlatform == TargetPlatform.iOS
              ? 'Google Sign-In: $errStr\nCheck the iOS client ID and reversed client ID URL scheme in Google Cloud and Xcode.'
              : 'Google Sign-In: $errStr';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTint10,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Brand illustration
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.p24,
                        vertical: 32,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/branding/mishraji_logo.png',
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome to Mishra Ji',
                            style: AppTypography.heading1,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Fresh artisanal sweets & desserts at your door',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Bottom Sheet
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.p24),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusBottomSheet),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14171A14),
                            offset: Offset(0, -4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Login or Register',
                            style: AppTypography.heading2,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'We will send a 6-digit OTP code to your email address.',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 20),

                          // Email Input
                          Container(
                            height: AppDimensions.heightInput,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusInput,
                              ),
                              border: Border.all(
                                color: _emailError != null
                                    ? AppColors.accent
                                    : AppColors.neutralBorder,
                                width: _emailError != null ? 2.0 : 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onChanged: (val) {
                                      if (_emailError != null) {
                                        setState(() => _emailError = null);
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'your@email.com',
                                      hintStyle: AppTypography.bodySmall,
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_emailError != null) ...[
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
                                    _emailError!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          AppPrimaryButton(
                            label: 'Continue with Email OTP',
                            isLoading: _isLoading,
                            onPressed: _handleEmailContinue,
                          ),

                          const SizedBox(height: 16),

                          // Divider with OR
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'OR',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            height: AppDimensions.heightInput,
                            child: OutlinedButton(
                              onPressed: _isGoogleLoading
                                  ? null
                                  : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.neutralBorder,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusInput,
                                  ),
                                ),
                                backgroundColor: AppColors.surface,
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Google G icon
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.g_mobiledata,
                                            size: 24,
                                            color: Color(0xFF4285F4),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Terms
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing, you agree to our ',
                                style: AppTypography.caption,
                                children: const [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
