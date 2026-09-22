import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sadguru_catering/core/network/api_client.dart';

ApiClient createTestApiClient({bool includeTestEvent = false}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'));
  dio.httpClientAdapter = _DashboardResponseAdapter(
    includeTestEvent: includeTestEvent,
  );
  return ApiClient(baseUrl: 'http://test.invalid', dio: dio);
}

class _DashboardResponseAdapter implements HttpClientAdapter {
  _DashboardResponseAdapter({required this.includeTestEvent});

  final bool includeTestEvent;

  static const _eventJson = '''
{
  "id": 42,
  "title": "Wedding Reception",
  "event_date": "2026-09-20",
  "venue": "Sadguru Function Hall",
  "guest_count": 500,
  "status": "upcoming",
  "created_at": "2026-09-01T10:00:00Z",
  "updated_at": "2026-09-01T10:00:00Z"
}
''';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isEventListRequest = options.path == '/events';
    final isEventDetailsRequest =
        options.path.startsWith('/events/') && options.path != '/events/';
    final isFinancialsRequest = options.path.endsWith('/financials');

    final String responseBody;

    if (includeTestEvent && isEventListRequest) {
      responseBody = '{"data":[$_eventJson]}';
    } else if (includeTestEvent && isFinancialsRequest) {
      responseBody =
          '{"data":{"event_id":42,"total_income":"0.00",'
          '"total_expenses":"0.00","profit":"0.00",'
          '"income":[],"expenses":[]}}';
    } else if (includeTestEvent && isEventDetailsRequest) {
      responseBody = '{"data":$_eventJson}';
    } else if (options.path.endsWith('/events')) {
      responseBody = '{"data":[]}';
    } else {
      responseBody =
          '{"data":{"from":"2026-01-01","to":"2026-01-31",'
          '"event_count":0,"upcoming_count":0,"running_count":0,'
          '"completed_count":0,"total_income":"0","total_expenses":"0",'
          '"profit":"0","events":[]}}';
    }

    return ResponseBody.fromString(
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
