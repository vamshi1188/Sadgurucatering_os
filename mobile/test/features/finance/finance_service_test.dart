import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/finance/models/finance_period.dart';
import 'package:sadguru_catering/features/finance/services/finance_service.dart';

import '../../support/finance_report_fixture.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late String responseBody;
  late int responseStatus;
  late Uri? requestedUri;

  setUp(() async {
    responseBody = jsonEncode({'data': financeReportJson()});
    responseStatus = HttpStatus.ok;
    requestedUri = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestedUri = request.uri;
      request.response.statusCode = responseStatus;
      request.response.headers.contentType = ContentType.json;
      request.response.write(responseBody);
      await request.response.close();
    });
    baseUrl = 'http://${server.address.host}:${server.port}/api/v1';
  });

  tearDown(() => server.close(force: true));

  test(
    'requests business finance summary with filter and pagination',
    () async {
      final service = FinanceService(ApiClient(baseUrl: baseUrl));

      final report = await service.getReport(
        period: FinancePeriod.custom,
        from: '2026-09-01',
        to: '2026-09-30',
        page: 2,
      );

      expect(requestedUri!.path, '/api/v1/finance/summary');
      expect(requestedUri!.queryParameters, {
        'period': 'custom',
        'from': '2026-09-01',
        'to': '2026-09-30',
        'page': '2',
        'page_size': '20',
      });
      expect(report.profit, '32000.00');
    },
  );

  test(
    'returns an explicit contract error for malformed report data',
    () async {
      responseBody = jsonEncode({
        'data': {...financeReportJson(), 'profit': 32000.00},
      });
      final service = FinanceService(ApiClient(baseUrl: baseUrl));

      await expectLater(
        service.getReport(period: FinancePeriod.thisMonth, page: 1),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.code,
                'code',
                'INVALID_FINANCE_REPORT_RESPONSE',
              )
              .having((error) => error.message, 'message', contains('profit')),
        ),
      );
    },
  );

  for (final status in [
    HttpStatus.unauthorized,
    HttpStatus.notFound,
    HttpStatus.internalServerError,
  ]) {
    test('propagates HTTP $status', () async {
      responseStatus = status;
      responseBody = jsonEncode({
        'error': {'code': 'HTTP_ERROR', 'message': 'Request failed'},
      });
      final service = FinanceService(ApiClient(baseUrl: baseUrl));

      await expectLater(
        service.getReport(period: FinancePeriod.thisMonth, page: 1),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            status,
          ),
        ),
      );
    });
  }
}
