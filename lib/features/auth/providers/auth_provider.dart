import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_api_service.dart';
import '../../../core/services/customer_api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/errors/api_exception.dart';

export '../models/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;
  final CustomerApiService _customerService;
  late final Future<void> initialization;

  AuthNotifier({
    AuthApiService? authService,
    CustomerApiService? customerService,
  }) : _authService = authService ?? authApiService,
       _customerService = customerService ?? customerApiService,
       super(const AuthState(status: AuthStatus.restoringSession)) {
    initialization = _restoreSavedSession();
  }

  Future<void> _restoreSavedSession() async {
    try {
      final savedUser = await _authService.restoreSession();
      if (!_authService.hasSession) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      try {
        final user = await _customerService.getProfile();
        await _authService.saveSession(
          token: _authService.currentToken!,
          user: user,
        );
        _setRestoredSession(user);
      } on ApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await _authService.clearSession();
          state = const AuthState(status: AuthStatus.unauthenticated);
        } else {
          _setRestoredSession(savedUser);
        }
      } catch (_) {
        _setRestoredSession(savedUser);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void _setRestoredSession(UserModel? user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      identifier: user?.email ?? user?.mobileNumber,
    );
    PushNotificationService.syncTokenWithBackend();
  }

  Future<bool> sendOtp(String email) async {
    final cleanEmail = email.trim();
    if (!cleanEmail.contains('@')) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    state = state.copyWith(
      status: AuthStatus.authenticating,
      identifier: cleanEmail,
      errorMessage: null,
    );

    try {
      await _authService.requestOtp(cleanEmail);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        identifier: cleanEmail,
        resendAvailableAt: DateTime.now().add(const Duration(seconds: 30)),
        remainingOtpAttempts: 3,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        identifier: cleanEmail,
        errorMessage: 'Could not send the verification code. Please try again.',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final email = state.identifier;
    if (email == null) return false;

    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    try {
      final result = await _authService.verifyOtp(email: email, otp: otp);

      if (result.isNewCustomer) {
        state = state.copyWith(
          status: AuthStatus.needsProfile,
          registrationToken: result.registrationToken,
          customerId: result.customerId,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.customer,
          errorMessage: null,
        );
        PushNotificationService.syncTokenWithBackend();
        return true;
      }
    } on ApiException catch (e) {
      if (e.statusCode != 400 && e.statusCode != 401 && e.statusCode != 422) {
        state = state.copyWith(
          status: AuthStatus.otpSent,
          errorMessage: e.message,
        );
        return false;
      }
      final remaining = state.remainingOtpAttempts - 1;
      state = state.copyWith(
        status: AuthStatus.otpSent,
        errorMessage: remaining > 0
            ? "That code isn't right. $remaining attempts left."
            : 'Too many incorrect attempts. Please request a new OTP.',
        remainingOtpAttempts: remaining > 0 ? remaining : 0,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.otpSent,
        errorMessage:
            'Sign-in could not be completed (${error.runtimeType}). Fully rebuild the app and try again.',
      );
      return false;
    }
  }

  Future<bool> completeRegistration({
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    try {
      final regToken = state.registrationToken;
      final custId = state.customerId;
      if (regToken == null || custId == null) {
        state = state.copyWith(
          status: AuthStatus.needsProfile,
          errorMessage:
              'Registration session expired. Please verify your email again.',
        );
        return false;
      }

      final user = await _authService.completeRegistration(
        registrationToken: regToken,
        customerId: custId,
        name: name,
        phone: phone,
      );

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      PushNotificationService.syncTokenWithBackend();
      return true;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.needsProfile,
        errorMessage: 'Could not complete registration. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle(String idToken) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );
    try {
      final result = await _authService.signInWithGoogle(idToken);
      if (result.isNewCustomer) {
        state = state.copyWith(
          status: AuthStatus.needsProfile,
          registrationToken: result.registrationToken,
          customerId: result.customerId,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.customer,
          errorMessage: null,
        );
        PushNotificationService.syncTokenWithBackend();
      }
      return true;
    } catch (e, stack) {
      debugPrint('[Auth] signInWithGoogle exception: $e\n$stack');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> updateProfile(
    String fullName,
    String? email,
    DateTime? dob,
    String? gender,
  ) async {
    if (state.user != null) {
      final updated = state.user!.copyWith(
        fullName: fullName,
        email: email,
        dateOfBirth: dob,
        gender: gender,
      );
      state = state.copyWith(user: updated);

      try {
        await _customerService.updateProfile(
          name: fullName,
          phone: updated.mobileNumber,
        );
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.unregisterOnLogout();
      await _authService.logout();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
