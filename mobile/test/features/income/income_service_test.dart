import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/income/services/income_service.dart';

void main() {
  late HttpServer server;
  late IncomeService service;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/events/1/financials') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'data': {
                'event_id': 1,
                'total_income': '50000.00',
                'income': [
                  {
                    'id': 10,
                    'event_id': 1,
                    'description': 'Advance',
                    'amount': '50000.00',
                    'created_at': '2026-09-03 10:15:00+00',
                  },
                ],
                'expenses': [],
              },
            }),
          );
      } else if (request.uri.path == '/events/1/income' &&
          request.method == 'POST') {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        expect(payload['amount'], '100.00');
        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'data': {
                'id': 11,
                'event_id': 1,
                'description': payload['description'],
                'amount': '100.00',
                'created_at': '2026-09-03 10:15:00+00',
              },
            }),
          );
      } else if (request.uri.path == '/events/1/income/10' &&
          request.method == 'DELETE') {
        request.response.statusCode = HttpStatus.noContent;
      } else if (request.uri.path == '/events/404/financials') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..headers.contentType = ContentType.json
          ..write('{"error":{"code":"NOT_FOUND","message":"Event not found"}}');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    service = IncomeService(
      ApiClient(baseUrl: 'http://${server.address.host}:${server.port}'),
    );
  });

  tearDown(() => server.close(force: true));

  test('gets financials income, creates income, and deletes income', () async {
    final financials = await service.getIncome(1);
    expect(financials.totalIncome, '50000.00');
    expect(financials.income.single.id, 10);

    final created = await service.createIncome(
      eventId: 1,
      description: 'Second payment',
      amount: '100.00',
    );
    expect(created.id, 11);

    await expectLater(
      service.deleteIncome(eventId: 1, incomeId: 10),
      completes,
    );
  });

  test('maps backend errors', () async {
    expect(
      () => service.getIncome(404),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'NOT_FOUND')
            .having((error) => error.statusCode, 'statusCode', 404),
      ),
    );
  });
}
