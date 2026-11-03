/// Core Domain Failure classes for Clean Architecture
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => '$runtimeType: $message (${code ?? ''})';
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {super.code, super.details, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Please check your internet connection'])
      : super(code: 'NETWORK_ERROR');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please sign in again.'])
      : super(code: 'UNAUTHORIZED');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local cached data'])
      : super(code: 'CACHE_ERROR');
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}
