import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/expenses/models/expense.dart';

void main() {
  test('parses and serializes decimal expense amounts', () {
    final expense = Expense.fromJson({
      'id': 20,
      'event_id': 1,
      'description': 'Food supplies',
      'amount': '20000.00',
      'created_at': '2026-09-03 10:20:00+00',
    });

    expect(expense.id, 20);
    expect(expense.eventId, 1);
    expect(expense.amount, '20000.00');
    expect(expense.createdAt.toUtc().year, 2026);
    expect(expense.toJson()['amount'], '20000.00');
  });

  test('parses empty expense financials', () {
    final financials = ExpenseFinancials.fromJson({
      'event_id': 1,
      'total_expenses': '0.00',
      'expenses': [],
    });

    expect(financials.totalExpenses, '0.00');
    expect(financials.expenses, isEmpty);
  });
}
