import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Formatter and logger for HTTP REST API requests and responses in the terminal
class ApiLogger {
  ApiLogger._();

  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  /// Logs outgoing HTTP requests to the terminal
  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!ApiConfig.enableLogging) return;

    final buffer = StringBuffer();
    buffer.writeln('\n🌐 ═════════════════════ [API REQUEST] ═════════════════════');
    buffer.writeln('➡️  METHOD : $method');
    buffer.writeln('🔗  URL    : $uri');

    if (headers != null && headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, String>.from(headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        final auth = sanitizedHeaders['Authorization'] ?? '';
        if (auth.length > 20) {
          sanitizedHeaders['Authorization'] = '${auth.substring(0, 15)}...${auth.substring(auth.length - 6)}';
        }
      }
      buffer.writeln('📋  HEADERS: $sanitizedHeaders');
    }

    if (body != null) {
      buffer.writeln('📦  BODY   :');
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          buffer.writeln(_prettyEncoder.convert(decoded));
        } else {
          buffer.writeln(_prettyEncoder.convert(body));
        }
      } catch (_) {
        buffer.writeln(body.toString());
      }
    }
    buffer.writeln('═══════════════════════════════════════════════════════════');

    _printLog(buffer.toString());
  }

  /// Logs incoming HTTP responses to the terminal
  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required String responseBody,
    required Duration duration,
  }) {
    if (!ApiConfig.enableLogging) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';

    final buffer = StringBuffer();
    buffer.writeln('\n$icon ═════════════════ [API RESPONSE: $statusCode] (${duration.inMilliseconds}ms) ═════════════════');
    buffer.writeln('⬅️  METHOD : $method');
    buffer.writeln('🔗  URL    : $uri');
    buffer.writeln('⏱️  TIME   : ${duration.inMilliseconds} ms');
    buffer.writeln('📊  STATUS : $statusCode');

    if (responseBody.isNotEmpty) {
      buffer.writeln('📥  BODY   :');
      try {
        final decoded = jsonDecode(responseBody);
        buffer.writeln(_prettyEncoder.convert(decoded));
      } catch (_) {
        buffer.writeln(responseBody);
      }
    }
    buffer.writeln('═══════════════════════════════════════════════════════════');

    _printLog(buffer.toString());
  }

  /// Logs network or timeout errors to the terminal
  static void logError({
    required String method,
    required Uri uri,
    required Object error,
    Duration? duration,
    StackTrace? stackTrace,
  }) {
    if (!ApiConfig.enableLogging) return;

    final buffer = StringBuffer();
    buffer.writeln('\n⚠️ ═════════════════════ [API ERROR] ═════════════════════');
    buffer.writeln('⬅️  METHOD : $method');
    buffer.writeln('🔗  URL    : $uri');
    if (duration != null) {
      buffer.writeln('⏱️  TIME   : ${duration.inMilliseconds} ms');
    }
    buffer.writeln('💥  ERROR  : $error');
    buffer.writeln('═══════════════════════════════════════════════════════════');

    _printLog(buffer.toString());
  }

  static void _printLog(String message) {
    // debugPrint ensures chunks don't get truncated by OS buffers
    debugPrint(message);
  }
}

