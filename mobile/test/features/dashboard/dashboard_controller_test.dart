import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/features/dashboard/controllers/dashboard_controller.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_period.dart';
import 'package:sadguru_catering/features/dashboard/services/dashboard_service.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  final requestedRanges = <String>[];
  var shouldFail = false;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestedRanges.add(
        '${request.uri.queryParameters['from']}:${request.uri.queryParameters['to']}',
      );
      if (shouldFail) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          '{"error":{"code":"SERVER_ERROR","message":"Temporary failure"}}',
        );
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'data': {
              'from': '2026-01-01',
              'to': '2026-01-31',
              'event_count': 0,
              'upcoming_count': 0,
              'running_count': 0,
              'completed_count': 0,
              'total_income': '0',
              'total_expenses': '0',
              'profit': '0',
              'events': [],
            },
          }),
        );
      }
      await request.response.close();
    });
    baseUrl = 'http://${server.address.host}:${server.port}';
    requestedRanges.clear();
  });

  tearDown(() => server.close(force: true));

  DashboardController createController() {
    return DashboardController(DashboardService(ApiClient(baseUrl: baseUrl)));
  }

  test('loads a dashboard summary', () async {
    final controller = createController();

    await controller.load();

    expect(controller.summary, isNotNull);
    expect(controller.summary!.eventCount, 0);
    expect(controller.error, isNull);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('maps API failures to retryable AppError and retry reloads', () async {
    shouldFail = true;
    final controller = createController();

    await controller.load();

    expect(controller.summary, isNull);
    expect(controller.error!.type, AppErrorType.server);
    expect(controller.error!.retryable, isTrue);

    shouldFail = false;
    await controller.retry();

    expect(controller.summary, isNotNull);
    expect(controller.error, isNull);
    controller.dispose();
  });

  test(
    'financial and event period selection reloads only its own summary',
    () async {
      final controller = createController();

      await controller.load();
      requestedRanges.clear();

      await controller.selectFinancialPeriod(FinancialPeriod.today);

      expect(requestedRanges, ['2026-09-11:2026-09-11']);

      requestedRanges.clear();
      await controller.selectEventPeriod(EventPeriod.tomorrow);

      expect(requestedRanges, ['2026-09-12:2026-09-12']);
      controller.dispose();
    },
  );
}
