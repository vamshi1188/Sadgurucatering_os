import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/expenses/controllers/expense_controller.dart';
import 'package:sadguru_catering/features/expenses/models/expense.dart';
import 'package:sadguru_catering/features/expenses/services/expense_service_contract.dart';

class _FakeExpenseService implements ExpenseServiceContract {
  _FakeExpenseService(this.financials);

  ExpenseFinancials financials;
  bool shouldFail = false;
  int loadCount = 0;
  int createCount = 0;
  int deleteCount = 0;

  @override
  Future<ExpenseFinancials> getExpenses(int eventId) async {
    loadCount++;
    if (shouldFail) {
      throw const ApiException(message: 'Unable to connect to the server');
    }
    return financials;
  }

  @override
  Future<Expense> createExpense({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    createCount++;
    return _expense(2, description, amount);
  }

  @override
  Future<void> deleteExpense({
    required int eventId,
    required int expenseId,
  }) async {
    deleteCount++;
  }
}

Expense _expense(int id, String description, String amount) => Expense(
  id: id,
  eventId: 1,
  description: description,
  amount: amount,
  createdAt: DateTime.utc(2026, 9, 3, 10),
);

void main() {
  test('loads canonical expenses and total', () async {
    final service = _FakeExpenseService(
      ExpenseFinancials(
        eventId: 1,
        totalExpenses: '20000.00',
        expenses: [_expense(1, 'Food supplies', '20000.00')],
      ),
    );
    final controller = ExpenseController(eventId: 1, service: service);

    await controller.load();

    expect(controller.expenses.single.description, 'Food supplies');
    expect(controller.totalExpenses, '20000.00');
    expect(controller.error, isNull);
  });

  test('maps load error and retry recovers', () async {
    final service = _FakeExpenseService(
      const ExpenseFinancials(eventId: 1, totalExpenses: '0.00', expenses: []),
    )..shouldFail = true;
    final controller = ExpenseController(eventId: 1, service: service);

    await controller.load();
    expect(controller.error, isNotNull);

    service.shouldFail = false;
    await controller.retry();
    expect(controller.error, isNull);
    expect(service.loadCount, 2);
  });

  test('create and delete refresh canonical state', () async {
    final service = _FakeExpenseService(
      const ExpenseFinancials(eventId: 1, totalExpenses: '0.00', expenses: []),
    );
    final controller = ExpenseController(eventId: 1, service: service);

    expect(
      await controller.createExpense(description: 'Food', amount: '10.00'),
      isTrue,
    );
    expect(await controller.deleteExpense(2), isTrue);
    expect(service.createCount, 1);
    expect(service.deleteCount, 1);
    expect(service.loadCount, 2);
  });
}
