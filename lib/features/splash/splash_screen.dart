import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/auth/providers/auth_provider.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

enum SplashState {
  normal,
  restoringSession,
  mandatoryUpdate,
  maintenance,
  initializationError,
  offline,
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  SplashState _currentState = SplashState.normal;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initApp();
  }

  void _initApp() async {
    try {
      await ref
          .read(authProvider.notifier)
          .initialization
          .timeout(const Duration(milliseconds: 2500), onTimeout: () {
            debugPrint('[Splash] Auth initialization timed out, proceeding.');
          });
      // Allow the brand splash & breathing animation to be visible smoothly
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (e) {
      debugPrint('[Splash] Init notice: $e');
    }

    if (!mounted) return;
    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    context.go(isAuthenticated ? '/home' : '/login');
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTint10,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/branding/mishraji_logo.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sweet moments, delivered with care.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Animated Breathing Dots or State Screen
              if (_currentState == SplashState.normal ||
                  _currentState == SplashState.restoringSession)
                _buildBreathingDots()
              else
                _buildEdgeCaseView(),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingDots() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final scale =
                (1.0 + 0.3 * (1.0 - (_breathingController.value - delay).abs()))
                    .clamp(0.8, 1.3);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10 * scale,
              height: 10 * scale,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEdgeCaseView() {
    String title = '';
    String message = '';
    IconData icon = Icons.info_outline;

    switch (_currentState) {
      case SplashState.mandatoryUpdate:
        title = 'Update Available';
        message =
            'Please update the app to continue enjoying your favorite sweets.';
        icon = Icons.system_update;
        break;
      case SplashState.maintenance:
        title = 'Short Maintenance';
        message =
            'We’re making a few kitchen improvements. Please check back shortly.';
        icon = Icons.construction;
        break;
      case SplashState.initializationError:
        title = 'Connection Trouble';
        message =
            'Something went wrong while starting the app. Please tap retry.';
        icon = Icons.error_outline;
        break;
      case SplashState.offline:
        title = 'You’re Offline';
        message =
            'Please check your internet connection to browse local sweet shops.';
        icon = Icons.wifi_off;
        break;
      default:
        break;
    }

    return Column(
      children: [
        Icon(icon, size: 40, color: AppColors.accent),
        const SizedBox(height: 12),
        Text(title, style: AppTypography.heading2),
        const SizedBox(height: 6),
        Text(
          message,
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: 'Retry',
          onPressed: () {
            setState(() => _currentState = SplashState.normal);
            _initApp();
          },
        ),
      ],
    );
  }
}
