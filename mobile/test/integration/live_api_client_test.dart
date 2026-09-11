import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';

void main() {
  test(
    'ApiClient reaches the live Sadguru API health endpoint',
    () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:3000/api/v1',
      );

      final response = await client.get<Map<String, dynamic>>(
        '/health',
        parser: (data) => data as Map<String, dynamic>,
      );

      expect(response.data['status'], 'ok');
      expect(response.requestId, isNotNull);
      expect(response.requestId, isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
