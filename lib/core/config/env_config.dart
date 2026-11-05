import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized Environment Configuration Manager
/// Loads variables with precedence:
/// 1. Bundled `.env` asset (via rootBundle)
/// 2. Direct filesystem `.env` file (Desktop/Debug/Test)
/// 3. `--dart-define` / `--dart-define-from-file=.env` flags
class EnvConfig {
  EnvConfig._();

  static final Map<String, String> _env = {};
  static bool _initialized = false;

  /// Initialize and load the .env configuration
  static Future<void> init() async {
    if (_initialized) return;

    // 1. Attempt loading from asset bundle (rootBundle)
    try {
      final content = await rootBundle.loadString('.env');
      _parse(content);
    } catch (_) {
      // .env asset may not be bundled in some environments
    }

    // 2. Fallback: Attempt loading from filesystem (Desktop / macOS / Test runner)
    if (_env.isEmpty && !kIsWeb) {
      try {
        final file = File('.env');
        if (await file.exists()) {
          final content = await file.readAsString();
          _parse(content);
        }
      } catch (_) {}
    }

    _initialized = true;
  }

  static void _parse(String content) {
    const splitter = LineSplitter();
    final lines = splitter.convert(content);
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eqIndex = line.indexOf('=');
      if (eqIndex == -1) continue;
      final key = line.substring(0, eqIndex).trim();
      var value = line.substring(eqIndex + 1).trim();

      // Strip surrounding single or double quotes
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        if (value.length >= 2) {
          value = value.substring(1, value.length - 1);
        }
      }

      if (key.isNotEmpty) {
        _env[key] = value;
      }
    }
  }

  /// Get environment variable value by key
  static String get(String key, {String defaultValue = ''}) {
    if (_env.containsKey(key) && _env[key]!.isNotEmpty) {
      return _env[key]!;
    }
    return defaultValue;
  }

  /// Check if a key is present and non-empty
  static bool has(String key) {
    return _env.containsKey(key) && _env[key]!.isNotEmpty;
  }
}

