import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/profitability/services/profitability_service.dart';

void main() {
  late HttpServer server;
  late ProfitabilityService service;
  final requestPaths = <String>[];
  final requestMethods = <String>[];

  setUp(() async {
    requestPaths.clear();
    requestMethods.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestPaths.add(request.uri.path);
      requestMethods.add(request.method);

      if (request.uri.path == '/events/1/financials') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'data': {
                'event_id': 1,
                'total_income': '1000.00',
                'total_expenses': '250.50',
                'profit': '749.50',
                'income': [],
                'expenses': [],
              },
            }),
          );
      } else if (request.uri.path == '/events/2/financials') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'data': {
                'event_id': 2,
                'total_income': '1000.00',
                'total_expenses': '250.50',
                'profit': '749.50',
                'income': [],
                'expenses': [],
              },
            }),
          );
      } else if (request.uri.path == '/events/401/financials') {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..headers.contentType = ContentType.json
          ..write(
            '{"error":{"code":"UNAUTHORIZED","message":"Authentication required"}}',
          );
      } else if (request.uri.path == '/events/404/financials') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..headers.contentType = ContentType.json
          ..write('{"error":{"code":"NOT_FOUND","message":"Event not found"}}');
      } else if (request.uri.path == '/events/500/financials') {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write(
            '{"error":{"code":"INTERNAL_ERROR","message":"Unable to retrieve event financials"}}',
          );
      } else if (request.uri.path == '/events/502/financials') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            '{"data":{"event_id":502,"total_income":"1.00","total_expenses":"0.00","profit":"1.00","income":[]}}',
          );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    service = ProfitabilityService(
      ApiClient(baseUrl: 'http://${server.address.host}:${server.port}'),
    );
  });

  tearDown(() => server.close(force: true));

  test('successfully fetches event profitability', () async {
    final result = await service.getProfitability(1);

    expect(result.eventId, 1);
    expect(result.totalIncome, '1000.00');
    expect(result.totalExpenses, '250.50');
    expect(result.netProfit, '749.50');
    expect(requestPaths, ['/events/1/financials']);
    expect(requestMethods, ['GET']);
  });

  test('uses the requested event ID in the endpoint', () async {
    final result = await service.getProfitability(2);

    expect(result.eventId, 2);
    expect(requestPaths, ['/events/2/financials']);
    expect(requestMethods, ['GET']);
  });

  test('rejects malformed financials as an explicit contract error', () async {
    await expectLater(
      service.getProfitability(502),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.code,
              'code',
              'INVALID_FINANCIALS_RESPONSE',
            )
            .having(
              (error) => error.message,
              'message',
              contains('expenses must be an array'),
            ),
      ),
    );
    expect(requestPaths, ['/events/502/financials']);
  });

  test('handles not found error', () async {
    await expectLater(
      service.getProfitability(404),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'NOT_FOUND')
            .having((error) => error.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('handles unauthorized error', () async {
    await expectLater(
      service.getProfitability(401),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'UNAUTHORIZED')
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('propagates actual HTTP 500 errors', () async {
    await expectLater(
      service.getProfitability(500),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'INTERNAL_ERROR')
            .having((error) => error.statusCode, 'statusCode', 500),
      ),
    );
    expect(requestPaths, ['/events/500/financials']);
  });
}
