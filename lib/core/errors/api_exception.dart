class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final List<dynamic>? details;
  final String? requestId;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
    this.requestId,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, int statusCode) {
    final errorObj = json['error'];
    if (errorObj is Map<String, dynamic>) {
      return ApiException(
        message: errorObj['message'] ?? 'An error occurred with the server.',
        code: errorObj['code']?.toString(),
        statusCode: statusCode,
        details: errorObj['details'] is List ? errorObj['details'] : null,
        requestId: errorObj['requestId']?.toString(),
      );
    }
    return ApiException(
      message: json['message'] ?? 'Unexpected server response.',
      statusCode: statusCode,
    );
  }

  factory ApiException.networkError(dynamic error) {
    return ApiException(
      message: 'Unable to connect to the server. Please check your internet connection.',
      code: 'NETWORK_ERROR',
      statusCode: 0,
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      message: 'Server request timed out. Please try again.',
      code: 'TIMEOUT',
      statusCode: 408,
    );
  }

  @override
  String toString() => message;
}
