import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'package:fdp/core/models/user_model.dart';

class OtpVerificationResult {
  final bool isNewCustomer;
  final String? token;
  final String? registrationToken;
  final String? customerId;
  final UserModel? customer;

  const OtpVerificationResult({
    required this.isNewCustomer,
    this.token,
    this.registrationToken,
    this.customerId,
    this.customer,
  });
}

class AuthApiService {
  final ApiClient _client;
  static const String _tokenPrefKey = 'fdp_jwt_token';
  static const String _userPrefKey = 'fdp_user_profile';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  AuthApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  bool get hasSession => _client.authToken?.isNotEmpty == true;
  String? get currentToken => _client.authToken;

  /// Request 6-digit OTP to customer email address
  Future<Map<String, dynamic>> requestOtp(String email) async {
    final res = await _client.post(
      '/customers/auth/request-otp',
      body: {'email': email.trim()},
    );
    return res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : {};
  }

  /// Verify 6-digit OTP
  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.post(
      '/customers/auth/verify-otp',
      body: {'email': email.trim(), 'otp': otp.trim()},
    );

    final data = res.data as Map<String, dynamic>;
    final bool isNew =
        data['isNewUser'] == true || data['isNewCustomer'] == true;
    final String? token = data['token']?.toString();
    final String? regToken = data['registrationToken']?.toString();
    final String? custId = data['customerId']?.toString();

    if (!isNew && (token == null || token.isEmpty)) {
      throw Exception('Sign-in response did not include an access token.');
    }

    UserModel? user;
    if (data['customer'] is Map<String, dynamic>) {
      user = UserModel.fromApiJson(data['customer'] as Map<String, dynamic>);
    }

    if (token != null && token.isNotEmpty) {
      await saveSession(token: token, user: user);
    }

    return OtpVerificationResult(
      isNewCustomer: isNew,
      token: token,
      registrationToken: regToken,
      customerId: custId,
      customer: user,
    );
  }

  /// Complete registration for new customer
  Future<UserModel> completeRegistration({
    required String registrationToken,
    required String customerId,
    required String name,
    required String phone,
  }) async {
    final res = await _client.post(
      '/customers/auth/complete-registration',
      body: {
        'registrationToken': registrationToken,
        'customerId': customerId,
        'name': name.trim(),
        'phone': phone.replaceAll(RegExp(r'[^0-9]'), ''),
      },
    );

    final data = res.data as Map<String, dynamic>;
    final String? token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Registration response did not include an access token.');
    }
    UserModel user;
    if (data['customer'] is Map<String, dynamic>) {
      user = UserModel.fromApiJson(data['customer'] as Map<String, dynamic>);
    } else {
      user = UserModel(
        id: customerId,
        customerId: customerId,
        fullName: name,
        mobileNumber: phone,
      );
    }

    if (token.isNotEmpty) {
      await saveSession(token: token, user: user);
    }

    return user;
  }

  /// Persist credentials securely and update ApiClient.
  Future<void> saveSession({required String token, UserModel? user}) async {
    await _secureStorage.write(key: _tokenPrefKey, value: token);
    if (user != null) {
      await _secureStorage.write(
        key: _userPrefKey,
        value: jsonEncode({
          '_id': user.id,
          'customerId': user.customerId,
          'name': user.fullName,
          'phone': user.mobileNumber,
          'email': user.email,
          'isEmailVerified': user.isEmailVerified,
          'avatarUrl': user.avatarUrl,
        }),
      );
    }
    _client.setAuthToken(token);
  }

  /// Restore saved session on app launch
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    var token = await _secureStorage.read(key: _tokenPrefKey);
    if (token == null || token.isEmpty) {
      token = prefs.getString(_tokenPrefKey);
      if (token != null && token.isNotEmpty) {
        await _secureStorage.write(key: _tokenPrefKey, value: token);
        await prefs.remove(_tokenPrefKey);
      }
    }
    if (token != null && token.isNotEmpty) {
      _client.setAuthToken(token);
      var userJsonStr = await _secureStorage.read(key: _userPrefKey);
      if (userJsonStr == null) {
        userJsonStr = prefs.getString(_userPrefKey);
        if (userJsonStr != null) {
          await _secureStorage.write(key: _userPrefKey, value: userJsonStr);
          await prefs.remove(_userPrefKey);
        }
      }
      if (userJsonStr != null) {
        try {
          final decoded = jsonDecode(userJsonStr) as Map<String, dynamic>;
          return UserModel.fromApiJson(decoded);
        } catch (_) {}
      }
    }
    return null;
  }

  /// Google OAuth sign-in with verified Google ID token
  Future<OtpVerificationResult> signInWithGoogle(String idToken) async {
    final res = await _client.post(
      '/customers/auth/google',
      body: {'idToken': idToken},
    );

    final data = res.data as Map<String, dynamic>;
    final bool isNew =
        data['isNewUser'] == true || data['isNewCustomer'] == true;
    final String? token = data['token']?.toString();
    final String? custId = data['customerId']?.toString();
    final String? regToken = data['registrationToken']?.toString();

    if (!isNew && (token == null || token.isEmpty)) {
      throw Exception(
        'Google sign-in response did not include an access token.',
      );
    }

    UserModel? user;
    if (data['customer'] is Map<String, dynamic>) {
      user = UserModel.fromApiJson(data['customer'] as Map<String, dynamic>);
    }

    if (token != null && token.isNotEmpty) {
      await saveSession(token: token, user: user);
    }

    return OtpVerificationResult(
      isNewCustomer: isNew,
      token: token,
      registrationToken: regToken,
      customerId: custId,
      customer: user,
    );
  }

  /// Revoke the server session, then clear local credentials regardless.
  Future<void> logout() async {
    if (hasSession) {
      try {
        await _client.post('/customers/auth/logout');
      } catch (_) {
        // Local logout must still complete if the server cannot be reached.
      }
    }

    await clearSession();
  }

  Future<void> clearSession() async {
    _client.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
    await prefs.remove(_userPrefKey);
    await _secureStorage.delete(key: _tokenPrefKey);
    await _secureStorage.delete(key: _userPrefKey);
  }
}

final authApiService = AuthApiService();
