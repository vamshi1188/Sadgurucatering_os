import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/income/models/income.dart';

void main() {
  test('parses decimal amount strings and serializes records', () {
    final income = Income.fromJson({
      'id': 10,
      'event_id': 1,
      'description': 'Catering advance',
      'amount': '50000.00',
      'created_at': '2026-09-03 10:15:00+00',
    });

    expect(income.id, 10);
    expect(income.eventId, 1);
    expect(income.amount, '50000.00');
    expect(income.createdAt.toUtc().year, 2026);
    expect(income.toJson()['amount'], '50000.00');
  });

  test('parses financials with empty income list', () {
    final financials = IncomeFinancials.fromJson({
      'event_id': 1,
      'total_income': '0.00',
      'income': [],
    });

    expect(financials.income, isEmpty);
    expect(financials.totalIncome, '0.00');
  });
}
