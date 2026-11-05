import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
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
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  bool get hasSession => _client.authToken?.isNotEmpty == true;
  String? get currentToken => _client.authToken;

  /// Request 6-digit OTP to customer email address
  /// POST /customers/auth/request-otp
  Future<Map<String, dynamic>> requestOtp(String email) async {
    final res = await _client.post(
      ApiConstants.authRequestOtp,
      body: {'email': email.trim()},
    );
    return res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : {};
  }

  /// Verify 6-digit OTP
  /// POST /customers/auth/verify-otp
  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.post(
      ApiConstants.authVerifyOtp,
      body: {'email': email.trim(), 'otp': otp.trim()},
    );

    final raw = res.raw ??
        (res.data is Map<String, dynamic>
            ? res.data as Map<String, dynamic>
            : <String, dynamic>{});
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : raw;

    final bool isNew = data['isNewUser'] == true ||
        data['isNewCustomer'] == true ||
        raw['isNewUser'] == true ||
        raw['isNewCustomer'] == true;

    final String? token = data['token']?.toString() ??
        raw['token']?.toString() ??
        data['accessToken']?.toString() ??
        raw['accessToken']?.toString();

    final String? regToken = data['registrationToken']?.toString() ??
        raw['registrationToken']?.toString();

    final String? custId = data['customerId']?.toString() ??
        raw['customerId']?.toString() ??
        data['_id']?.toString() ??
        raw['_id']?.toString() ??
        data['id']?.toString() ??
        raw['id']?.toString();

    if (!isNew && (token == null || token.isEmpty)) {
      throw Exception('Sign-in response did not include an access token.');
    }

    UserModel? user;
    final customerData = data['customer'] ??
        raw['customer'] ??
        data['user'] ??
        raw['user'] ??
        (data.containsKey('_id') || data.containsKey('phone') || data.containsKey('email')
            ? data
            : null);

    if (customerData is Map<String, dynamic>) {
      user = UserModel.fromApiJson(customerData);
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
  /// POST /customers/auth/complete-registration
  Future<UserModel> completeRegistration({
    required String registrationToken,
    required String customerId,
    required String name,
    required String phone,
  }) async {
    final res = await _client.post(
      ApiConstants.authCompleteRegistration,
      body: {
        'registrationToken': registrationToken,
        'customerId': customerId,
        'name': name.trim(),
        'phone': phone.replaceAll(RegExp(r'[^0-9]'), ''),
      },
    );

    final raw = res.raw ??
        (res.data is Map<String, dynamic>
            ? res.data as Map<String, dynamic>
            : <String, dynamic>{});
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : raw;

    final String? token = data['token']?.toString() ??
        raw['token']?.toString() ??
        data['accessToken']?.toString() ??
        raw['accessToken']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Registration response did not include an access token.');
    }

    UserModel user;
    final customerData = data['customer'] ??
        raw['customer'] ??
        data['user'] ??
        raw['user'] ??
        (data.containsKey('_id') || data.containsKey('phone') || data.containsKey('email')
            ? data
            : null);

    if (customerData is Map<String, dynamic>) {
      user = UserModel.fromApiJson(customerData);
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

  /// Safely writes to FlutterSecureStorage, handling iOS Keychain -25299 duplicate key errors gracefully
  Future<void> _safeSecureWrite(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      try {
        // Resolve iOS Keychain errSecDuplicateItem (-25299)
        await _secureStorage.delete(key: key);
        await _secureStorage.write(key: key, value: value);
      } catch (_) {
        // Fallback to SharedPreferences if Keychain is locked or inaccessible
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      }
    }
  }

  /// Persist credentials securely and update ApiClient.
  Future<void> saveSession({required String token, UserModel? user}) async {
    await _safeSecureWrite(_tokenPrefKey, token);
    if (user != null) {
      final userJson = jsonEncode({
        '_id': user.id,
        'customerId': user.customerId,
        'name': user.fullName,
        'phone': user.mobileNumber,
        'email': user.email,
        'isEmailVerified': user.isEmailVerified,
        'avatarUrl': user.avatarUrl,
      });
      await _safeSecureWrite(_userPrefKey, userJson);
    }
    _client.setAuthToken(token);
  }

  /// Restore saved session on app launch
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token;
    try {
      token = await _secureStorage
          .read(key: _tokenPrefKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {}

    if (token == null || token.isEmpty) {
      token = prefs.getString(_tokenPrefKey);
      if (token != null && token.isNotEmpty) {
        try {
          await _secureStorage
              .write(key: _tokenPrefKey, value: token)
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
        await prefs.remove(_tokenPrefKey);
      }
    }
    if (token != null && token.isNotEmpty) {
      _client.setAuthToken(token);
      String? userJsonStr;
      try {
        userJsonStr = await _secureStorage
            .read(key: _userPrefKey)
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
      } catch (_) {}
      if (userJsonStr == null) {
        userJsonStr = prefs.getString(_userPrefKey);
        if (userJsonStr != null) {
          try {
            await _secureStorage
                .write(key: _userPrefKey, value: userJsonStr)
                .timeout(const Duration(seconds: 2));
          } catch (_) {}
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
  /// POST /customers/auth/google
  Future<OtpVerificationResult> signInWithGoogle(String idToken) async {
    final res = await _client.post(
      ApiConstants.authGoogle,
      body: {'idToken': idToken},
    );

    final raw = res.raw ??
        (res.data is Map<String, dynamic>
            ? res.data as Map<String, dynamic>
            : <String, dynamic>{});
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : raw;

    final bool isNew = data['isNewUser'] == true ||
        data['isNewCustomer'] == true ||
        raw['isNewUser'] == true ||
        raw['isNewCustomer'] == true;

    final String? token = data['token']?.toString() ??
        raw['token']?.toString() ??
        data['accessToken']?.toString() ??
        raw['accessToken']?.toString();

    final String? custId = data['customerId']?.toString() ??
        raw['customerId']?.toString() ??
        data['_id']?.toString() ??
        raw['_id']?.toString() ??
        data['id']?.toString() ??
        raw['id']?.toString();

    final String? regToken = data['registrationToken']?.toString() ??
        raw['registrationToken']?.toString();

    if (!isNew && (token == null || token.isEmpty)) {
      throw Exception(
        'Google sign-in response did not include an access token.',
      );
    }

    UserModel? user;
    final customerData = data['customer'] ??
        raw['customer'] ??
        data['user'] ??
        raw['user'] ??
        (data.containsKey('_id') || data.containsKey('phone') || data.containsKey('email')
            ? data
            : null);

    if (customerData is Map<String, dynamic>) {
      user = UserModel.fromApiJson(customerData);
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
  /// POST /customers/auth/logout
  Future<void> logout() async {
    if (hasSession) {
      try {
        await _client.post(ApiConstants.authLogout);
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
