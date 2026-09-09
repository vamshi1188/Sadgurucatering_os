import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/errors/app_error.dart';

void main() {
  group('AppError', () {
    test('identifies unauthorized errors', () {
      const error = AppError(
        type: AppErrorType.unauthorized,
        message: 'Authentication required',
        statusCode: 401,
      );

      expect(error.type, AppErrorType.unauthorized);
      expect(error.requiresAuthentication, isTrue);
      expect(error.retryable, isFalse);
    });

    test('identifies retryable network errors', () {
      const error = AppError(
        type: AppErrorType.network,
        message: 'Unable to connect to the server',
        retryable: true,
      );

      expect(error.type, AppErrorType.network);
      expect(error.retryable, isTrue);
      expect(error.requiresAuthentication, isFalse);
    });

    test('preserves API metadata', () {
      const error = AppError(
        type: AppErrorType.server,
        message: 'Server error',
        code: 'INTERNAL_ERROR',
        statusCode: 500,
        requestId: 'req-123',
      );

      expect(error.code, 'INTERNAL_ERROR');
      expect(error.statusCode, 500);
      expect(error.requestId, 'req-123');
    });
  });
}