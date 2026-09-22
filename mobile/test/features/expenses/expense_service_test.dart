import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/expenses/services/expense_service.dart';

void main() {
  late HttpServer server;
  late ExpenseService service;

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
                'total_expenses': '20000.00',
                'expenses': [
                  {
                    'id': 20,
                    'event_id': 1,
                    'description': 'Food supplies',
                    'amount': '20000.00',
                    'created_at': '2026-09-03 10:20:00+00',
                  },
                ],
              },
            }),
          );
      } else if (request.uri.path == '/events/1/expenses' &&
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
                'id': 21,
                'event_id': 1,
                'description': payload['description'],
                'amount': '100.00',
                'created_at': '2026-09-03 10:20:00+00',
              },
            }),
          );
      } else if (request.uri.path == '/events/1/expenses/20' &&
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

    service = ExpenseService(
      ApiClient(baseUrl: 'http://${server.address.host}:${server.port}'),
    );
  });

  tearDown(() => server.close(force: true));

  test('gets, creates, and deletes expenses', () async {
    final financials = await service.getExpenses(1);
    expect(financials.totalExpenses, '20000.00');
    expect(financials.expenses.single.id, 20);

    final created = await service.createExpense(
      eventId: 1,
      description: 'Second supply',
      amount: '100.00',
    );
    expect(created.id, 21);

    await expectLater(
      service.deleteExpense(eventId: 1, expenseId: 20),
      completes,
    );
  });

  test('maps backend errors', () async {
    expect(
      () => service.getExpenses(404),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          404,
        ),
      ),
    );
  });
}
