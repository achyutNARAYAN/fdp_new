import 'package:flutter/foundation.dart';

/// Senior-grade structured logger for debugging, lifecycle, and network telemetry
class AppLogger {
  AppLogger._();

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] 🟢 $message');
      if (error != null) debugPrint('   Details: $error');
      if (stackTrace != null) debugPrint('   Trace: $stackTrace');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] 🔵 $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] 🟡 $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] 🔴 $message');
    if (error != null) debugPrint('   Cause: $error');
    if (stackTrace != null) debugPrint('   StackTrace: $stackTrace');
  }

  static void network(String method, String url, {int? statusCode, dynamic payload}) {
    if (kDebugMode) {
      final code = statusCode != null ? '[$statusCode]' : '';
      debugPrint('[NETWORK] 🌐 $method $url $code');
      if (payload != null) {
        debugPrint('   Payload: $payload');
      }
    }
  }
}

