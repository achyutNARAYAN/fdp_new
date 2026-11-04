import 'package:fdp/core/models/user_model.dart';

enum AuthStatus {
  restoringSession,
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
