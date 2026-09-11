import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/network/api_exception.dart';

void main() {
  group('ApiException', () {
    test('stores message, code and status', () {
      const exception = ApiException(
        message: 'Invalid password',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

      expect(exception.message, 'Invalid password');
      expect(exception.code, 'UNAUTHORIZED');
      expect(exception.statusCode, 401);
    });

    test('toString includes error code when available', () {
      const exception = ApiException(
        message: 'Invalid password',
        code: 'UNAUTHORIZED',
      );

      expect(exception.toString(), 'UNAUTHORIZED: Invalid password');
    });

    test('toString returns message when code is absent', () {
      const exception = ApiException(
        message: 'Unable to connect to the server',
      );

      expect(exception.toString(), 'Unable to connect to the server');
    });
  });
}
