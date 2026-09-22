import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/expenses/controllers/expense_controller.dart';
import 'package:sadguru_catering/features/expenses/models/expense.dart';
import 'package:sadguru_catering/features/expenses/screens/expense_list_screen.dart';
import 'package:sadguru_catering/features/expenses/services/expense_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeExpenseService implements ExpenseServiceContract {
  _FakeExpenseService(this.expenses);

  List<Expense> expenses;
  int deleteCount = 0;

  @override
  Future<ExpenseFinancials> getExpenses(int eventId) async => ExpenseFinancials(
    eventId: eventId,
    totalExpenses: expenses.isEmpty ? '0.00' : '100.00',
    expenses: expenses,
  );

  @override
  Future<Expense> createExpense({
    required int eventId,
    required String description,
    required String amount,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteExpense({
    required int eventId,
    required int expenseId,
  }) async {
    deleteCount++;
    expenses = expenses.where((expense) => expense.id != expenseId).toList();
  }
}

Widget _app(ExpenseController controller) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: ExpenseListScreen(controller: controller, onAddExpense: () {}),
);

Expense _expense() => Expense(
  id: 1,
  eventId: 1,
  description: 'Food supplies',
  amount: '100.00',
  createdAt: DateTime.utc(2026, 9, 3),
);

void main() {
  testWidgets('shows empty expense state', (tester) async {
    final controller = ExpenseController(
      eventId: 1,
      service: _FakeExpenseService([]),
    );
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.text('No expense records'), findsOneWidget);
  });

  testWidgets('shows expense total and records', (tester) async {
    final controller = ExpenseController(
      eventId: 1,
      service: _FakeExpenseService([_expense()]),
    );
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.text('100.00'), findsNWidgets(2));
    expect(find.text('Food supplies'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('confirms delete and shows empty state', (tester) async {
    final service = _FakeExpenseService([_expense()]);
    final controller = ExpenseController(eventId: 1, service: service);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to delete this expense?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCount, 1);
    expect(find.text('No expense records'), findsOneWidget);
  });
}
