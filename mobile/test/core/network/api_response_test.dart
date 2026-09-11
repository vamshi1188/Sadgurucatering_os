import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/network/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('stores response data', () {
      const response = ApiResponse<String>(data: 'success');

      expect(response.data, 'success');
      expect(response.requestId, isNull);
    });

    test('stores request ID', () {
      const response = ApiResponse<String>(
        data: 'success',
        requestId: 'req_123',
      );

      expect(response.data, 'success');
      expect(response.requestId, 'req_123');
    });
  });
}
