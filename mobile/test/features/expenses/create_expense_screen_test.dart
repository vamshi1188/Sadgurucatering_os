import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/expenses/controllers/expense_controller.dart';
import 'package:sadguru_catering/features/expenses/models/expense.dart';
import 'package:sadguru_catering/features/expenses/screens/create_expense_screen.dart';
import 'package:sadguru_catering/features/expenses/services/expense_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeExpenseService implements ExpenseServiceContract {
  int createCount = 0;

  @override
  Future<Expense> createExpense({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    createCount++;
    return Expense(
      id: 1,
      eventId: eventId,
      description: description,
      amount: amount,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<ExpenseFinancials> getExpenses(int eventId) async =>
      const ExpenseFinancials(eventId: 1, totalExpenses: '0.00', expenses: []);

  @override
  Future<void> deleteExpense({
    required int eventId,
    required int expenseId,
  }) async {}
}

Widget _app(ExpenseController controller) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: CreateExpenseScreen(controller: controller),
);

void main() {
  testWidgets('rejects required fields and invalid amount', (tester) async {
    final service = _FakeExpenseService();
    final controller = ExpenseController(eventId: 1, service: service);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a description'), findsOneWidget);
    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(service.createCount, 0);
  });

  testWidgets('submits valid expense', (tester) async {
    final service = _FakeExpenseService();
    final controller = ExpenseController(eventId: 1, service: service);
    await tester.pumpWidget(_app(controller));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Food supplies',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '100.00',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.createCount, 1);
  });
}
