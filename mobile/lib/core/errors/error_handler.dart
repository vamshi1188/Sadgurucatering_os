
import '../network/api_exception.dart';
import 'app_error.dart';

class ErrorHandler {
  ErrorHandler._();

  static AppError fromApiException(ApiException exception) {
    final statusCode = exception.statusCode;

    if (statusCode == 401) {
      return AppError(
        type: AppErrorType.unauthorized,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: false,
      );
    }

    if (statusCode == 403) {
      return AppError(
        type: AppErrorType.forbidden,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: false,
      );
    }

    if (statusCode == 404) {
      return AppError(
        type: AppErrorType.notFound,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: false,
      );
    }

    if (statusCode != null &&
        statusCode >= 400 &&
        statusCode < 500) {
      return AppError(
        type: AppErrorType.validation,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: false,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return AppError(
        type: AppErrorType.server,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: true,
      );
    }

    final message = exception.message.toLowerCase();

    if (message.contains('timed out')) {
      return AppError(
        type: AppErrorType.timeout,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: true,
      );
    }

    if (message.contains('unable to connect')) {
      return AppError(
        type: AppErrorType.network,
        message: exception.message,
        code: exception.code,
        statusCode: statusCode,
        retryable: true,
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      message: exception.message,
      code: exception.code,
      statusCode: statusCode,
      retryable: false,
    );
  }
}