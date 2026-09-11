import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sadguru_catering/core/network/api_client.dart';

ApiClient createTestApiClient() {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'));
  dio.httpClientAdapter = _DashboardResponseAdapter();
  return ApiClient(baseUrl: 'http://test.invalid', dio: dio);
}

class _DashboardResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"data":{"from":"2026-01-01","to":"2026-01-31",'
      '"event_count":0,"upcoming_count":0,"running_count":0,'
      '"completed_count":0,"total_income":"0","total_expenses":"0",'
      '"profit":"0","events":[]}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
