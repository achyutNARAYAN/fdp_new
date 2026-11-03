import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure Storage Service for sensitive customer credentials and JWT tokens
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> saveCustomerId(String id) async {
    await _storage.write(key: AppConstants.keyCustomerId, value: id);
  }

  Future<String?> getCustomerId() async {
    return await _storage.read(key: AppConstants.keyCustomerId);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyCustomerId);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final secureStorageService = SecureStorageService();
