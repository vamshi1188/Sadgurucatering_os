import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/income/controllers/income_controller.dart';
import 'package:sadguru_catering/features/income/models/income.dart';
import 'package:sadguru_catering/features/income/screens/create_income_screen.dart';
import 'package:sadguru_catering/features/income/services/income_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeIncomeService implements IncomeServiceContract {
  int createCount = 0;

  @override
  Future<Income> createIncome({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    createCount++;
    return Income(
      id: 1,
      eventId: eventId,
      description: description,
      amount: amount,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<IncomeFinancials> getIncome(int eventId) async =>
      const IncomeFinancials(eventId: 1, totalIncome: '0.00', income: []);

  @override
  Future<void> deleteIncome({
    required int eventId,
    required int incomeId,
  }) async {}
}

Widget _app(IncomeController controller) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: CreateIncomeScreen(controller: controller),
);

void main() {
  testWidgets('rejects required fields and invalid amount', (tester) async {
    final service = _FakeIncomeService();
    final controller = IncomeController(eventId: 1, service: service);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a description'), findsOneWidget);
    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(service.createCount, 0);
  });

  testWidgets('submits valid income', (tester) async {
    final service = _FakeIncomeService();
    final controller = IncomeController(eventId: 1, service: service);
    await tester.pumpWidget(_app(controller));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Advance',
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
