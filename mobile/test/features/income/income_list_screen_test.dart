import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/income/controllers/income_controller.dart';
import 'package:sadguru_catering/features/income/models/income.dart';
import 'package:sadguru_catering/features/income/screens/income_list_screen.dart';
import 'package:sadguru_catering/features/income/services/income_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeIncomeService implements IncomeServiceContract {
  _FakeIncomeService(this.income);

  List<Income> income;
  bool shouldFail = false;

  @override
  Future<IncomeFinancials> getIncome(int eventId) async {
    if (shouldFail) {
      throw const ApiException(message: 'Unable to connect to the server');
    }
    return IncomeFinancials(
      eventId: eventId,
      totalIncome: income.isEmpty ? '0.00' : '100.00',
      income: income,
    );
  }

  @override
  Future<Income> createIncome({
    required int eventId,
    required String description,
    required String amount,
  }) => throw UnimplementedError();

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
  home: IncomeListScreen(controller: controller, onAddIncome: () {}),
);

Income _income() => Income(
  id: 1,
  eventId: 1,
  description: 'Advance',
  amount: '100.00',
  createdAt: DateTime.utc(2026, 9, 3),
);

void main() {
  testWidgets('shows empty state', (tester) async {
    final controller = IncomeController(
      eventId: 1,
      service: _FakeIncomeService([]),
    );
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.text('No income records'), findsOneWidget);
  });

  testWidgets('shows total and income records', (tester) async {
    final controller = IncomeController(
      eventId: 1,
      service: _FakeIncomeService([_income()]),
    );
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.text('100.00'), findsNWidgets(2));
    expect(find.text('Advance'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
