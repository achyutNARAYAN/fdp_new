import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../errors/api_exception.dart';
import 'api_logger.dart';

class ApiResponse<T> {
  final bool success;
  final T data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? raw;

  const ApiResponse({
    required this.success,
    required this.data,
    this.meta,
    this.raw,
  });
}

class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    final String fullUrl = '${ApiConfig.baseUrl}$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          sanitizedParams[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: sanitizedParams);
    }
    return Uri.parse(fullUrl);
  }

  Future<ApiResponse<dynamic>> _sendRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final finalHeaders = _buildHeaders(headers);
    ApiLogger.logRequest(
      method: method,
      uri: uri,
      headers: finalHeaders,
      body: body,
    );

    final stopwatch = Stopwatch()..start();

    try {
      final http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: finalHeaders).timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await _client.post(uri, headers: finalHeaders, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: finalHeaders, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: finalHeaders, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: finalHeaders, body: encodedBody).timeout(ApiConfig.timeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      stopwatch.stop();

      ApiLogger.logResponse(
        method: method,
        uri: uri,
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: stopwatch.elapsed,
      );

      return _processResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      ApiLogger.logError(
        method: method,
        uri: uri,
        error: 'Timeout after ${ApiConfig.timeout.inSeconds}s',
        duration: stopwatch.elapsed,
      );
      throw ApiException.timeout();
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(
        method: method,
        uri: uri,
        error: 'Network connection failed: ${e.message}',
        duration: stopwatch.elapsed,
      );
      throw ApiException.networkError(e);
    } catch (e, stack) {
      stopwatch.stop();
      ApiLogger.logError(
        method: method,
        uri: uri,
        error: e,
        duration: stopwatch.elapsed,
        stackTrace: stack,
      );
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    return _sendRequest('GET', uri, headers: headers);
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest('POST', uri, headers: headers, body: body);
  }

  Future<ApiResponse<dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest('PATCH', uri, headers: headers, body: body);
  }

  Future<ApiResponse<dynamic>> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest('PUT', uri, headers: headers, body: body);
  }

  Future<ApiResponse<dynamic>> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    return _sendRequest('DELETE', uri, headers: headers, body: body);
  }

  ApiResponse<dynamic> _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        message: 'Invalid server response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final bool hasData =
            decoded.containsKey('data') && decoded['data'] != null;
        final payload = hasData ? decoded['data'] : decoded;
        return ApiResponse(
          success: decoded['success'] != false,
          data: payload,
          meta: decoded['meta'] is Map<String, dynamic>
              ? decoded['meta'] as Map<String, dynamic>
              : null,
          raw: decoded,
        );
      }
      return ApiResponse(success: true, data: decoded);
    } else {
      if (decoded is Map<String, dynamic>) {
        throw ApiException.fromJson(decoded, response.statusCode);
      }
      throw ApiException(
        message: 'Request failed with status code ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }
}

final globalApiClient = ApiClient();
