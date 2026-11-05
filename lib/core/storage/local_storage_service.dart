import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Local Preferences Service for UI state, flags, and non-sensitive cache
class LocalStorageService {
  LocalStorageService._();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> setOnboardingCompleted(bool value) async {
    await init();
    return await _prefs!.setBool(AppConstants.keyOnboardingComplete, value);
  }

  static bool isOnboardingCompleted() {
    return _prefs?.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  static Future<bool> setString(String key, String value) async {
    await init();
    return await _prefs!.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    await init();
    return await _prefs!.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  static Future<bool> remove(String key) async {
    await init();
    return await _prefs!.remove(key);
  }
}

