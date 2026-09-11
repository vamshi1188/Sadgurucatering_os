import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/errors/error_handler.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';

void main() {
  group('ErrorHandler', () {
    test('maps 401 to unauthorized', () {
      const exception = ApiException(
        message: 'Authentication required',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.unauthorized);
      expect(error.requiresAuthentication, isTrue);
      expect(error.retryable, isFalse);
      expect(error.code, 'UNAUTHORIZED');
    });

    test('maps 403 to forbidden', () {
      const exception = ApiException(
        message: 'Access denied',
        code: 'FORBIDDEN',
        statusCode: 403,
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.forbidden);
      expect(error.retryable, isFalse);
    });

    test('maps 404 to not found', () {
      const exception = ApiException(
        message: 'Resource not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.notFound);
      expect(error.retryable, isFalse);
    });

    test('maps other 4xx errors to validation', () {
      const exception = ApiException(
        message: 'Invalid request',
        code: 'VALIDATION_ERROR',
        statusCode: 422,
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.validation);
      expect(error.retryable, isFalse);
    });

    test('maps 5xx errors to retryable server errors', () {
      const exception = ApiException(
        message: 'Internal server error',
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.server);
      expect(error.retryable, isTrue);
    });

    test('maps timeout errors to retryable timeout errors', () {
      const exception = ApiException(
        message: 'The request timed out',
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.timeout);
      expect(error.retryable, isTrue);
    });

    test('maps connection errors to retryable network errors', () {
      const exception = ApiException(
        message: 'Unable to connect to the server',
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.network);
      expect(error.retryable, isTrue);
    });

    test('maps unknown errors to unknown', () {
      const exception = ApiException(
        message: 'Unexpected failure',
      );

      final error = ErrorHandler.fromApiException(exception);

      expect(error.type, AppErrorType.unknown);
      expect(error.retryable, isFalse);
    });
  });
}