
enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

class AppError {
  const AppError({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.requestId,
    this.retryable = false,
  });

  final AppErrorType type;
  final String message;
  final String? code;
  final int? statusCode;
  final String? requestId;
  final bool retryable;

  bool get requiresAuthentication => type == AppErrorType.unauthorized;
}