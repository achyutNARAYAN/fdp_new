import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/customer_api_service.dart';

enum AuthStatus {
  unauthenticated,
  otpSent,
  authenticating,
  authenticated,
  needsProfile,
  blocked,
}

class AuthState {
  final AuthStatus status;
  final String? identifier; // email or phone
  final String? registrationToken;
  final String? customerId;
  final UserModel? user;
  final String? errorMessage;
  final int remainingOtpAttempts;
  final DateTime? resendAvailableAt;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.identifier,
    this.registrationToken,
    this.customerId,
    this.user,
    this.errorMessage,
    this.remainingOtpAttempts = 3,
    this.resendAvailableAt,
  });

  String? get phoneNumber => user?.mobileNumber ?? identifier;

  AuthState copyWith({
    AuthStatus? status,
    String? identifier,
    String? registrationToken,
    String? customerId,
    UserModel? user,
    String? errorMessage,
    int? remainingOtpAttempts,
    DateTime? resendAvailableAt,
  }) {
    return AuthState(
      status: status ?? this.status,
      identifier: identifier ?? this.identifier,
      registrationToken: registrationToken ?? this.registrationToken,
      customerId: customerId ?? this.customerId,
      user: user ?? this.user,
      errorMessage: errorMessage,
      remainingOtpAttempts: remainingOtpAttempts ?? this.remainingOtpAttempts,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;
  final CustomerApiService _customerService;

  AuthNotifier({
    AuthApiService? authService,
    CustomerApiService? customerService,
  }) : _authService = authService ?? authApiService,
       _customerService = customerService ?? customerApiService,
       super(const AuthState()) {
    _restoreSavedSession();
  }

  Future<void> _restoreSavedSession() async {
    try {
      final savedUser = await _authService.restoreSession();
      if (_authService.hasSession) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: savedUser,
          identifier: savedUser?.email ?? savedUser?.mobileNumber,
        );
      }
    } catch (_) {}
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
        return true;
      }
    } catch (e) {
      final remaining = state.remainingOtpAttempts - 1;
      state = state.copyWith(
        status: AuthStatus.otpSent,
        errorMessage: remaining > 0
            ? "That code isn't right. $remaining attempts left."
            : 'Too many incorrect attempts. Please request a new OTP.',
        remainingOtpAttempts: remaining > 0 ? remaining : 0,
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
      }
      return true;
    } catch (e) {
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
    await _authService.logout();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      identifier: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
