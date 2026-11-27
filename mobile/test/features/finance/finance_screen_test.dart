import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/finance/controllers/finance_controller.dart';
import 'package:sadguru_catering/features/finance/models/finance_period.dart';
import 'package:sadguru_catering/features/finance/models/finance_report.dart';
import 'package:sadguru_catering/features/finance/screens/finance_screen.dart';
import 'package:sadguru_catering/features/finance/services/finance_service_contract.dart';
import 'package:sadguru_catering/features/finance/widgets/finance_summary_cards.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

import '../../support/finance_report_fixture.dart';

void main() {
  test(
    'formats INR amounts with Indian grouping without numeric conversion',
    () {
      expect(formatRupees('50000.00'), '50,000.00');
      expect(formatRupees('12345678.90'), '1,23,45,678.90');
      expect(formatRupees('-1200.00'), '-1,200.00');
    },
  );

  for (final (width, textScale, expectedRows) in [
    (280.0, 1.0, 3),
    (390.0, 1.0, 3),
    (800.0, 1.0, 2),
    (390.0, 1.6, 3),
  ]) {
    testWidgets(
      'shows complete short and large amounts at width $width and text scale $textScale',
      (tester) async {
        final report = FinanceReport.fromJson(
          financeReportJson(
            totalIncome: '0.00',
            totalExpenses: '123456789012.34',
            profit: '-123456789012.34',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: SizedBox(
                    width: width,
                    child: FinanceSummaryCards(
                      report: report,
                      incomeLabel: 'Total Income',
                      expensesLabel: 'Total Expenses',
                      profitLabel: 'Net Profit',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('₹ 0.00'), findsOneWidget);
        expect(find.text('₹ 1,23,45,67,89,012.34'), findsOneWidget);
        expect(find.text('₹ -1,23,45,67,89,012.34'), findsOneWidget);

        final cards = tester.widgetList<Card>(find.byType(Card)).toList();
        expect(cards, hasLength(3));
        final cardRects = cards
            .map((card) => tester.getRect(find.byWidget(card)))
            .toList();
        final distinctRows = cardRects.map((rect) => rect.top).toSet().length;
        expect(distinctRows, expectedRows);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final (profit, expected) in [
    ('32000.00', '₹ 32,000.00'),
    ('-200.00', '₹ -200.00'),
    ('0.00', '₹ 0.00'),
  ]) {
    testWidgets('presents profit $profit without numeric conversion', (
      tester,
    ) async {
      final report = FinanceReport.fromJson(
        financeReportJson(
          totalIncome: '50000.00',
          totalExpenses: '18000.00',
          profit: profit,
        ),
      );
      final controller = FinanceController(_FakeFinanceService(report));

      await tester.pumpWidget(_app(FinanceScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text(expected), findsOneWidget);
      controller.dispose();
    });
  }

  testWidgets('renders dashboard labels in English and empty sections', (
    tester,
  ) async {
    final controller = FinanceController(
      _FakeFinanceService(FinanceReport.fromJson(financeReportJson())),
    );

    await tester.pumpWidget(_app(FinanceScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Event-wise Breakdown'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('No financial activity for this period'), findsOneWidget);
    expect(find.text('No transactions for this period'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('renders finance dashboard labels in Telugu', (tester) async {
    final controller = FinanceController(
      _FakeFinanceService(FinanceReport.fromJson(financeReportJson())),
    );

    await tester.pumpWidget(
      _app(FinanceScreen(controller: controller), locale: const Locale('te')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ఈవెంట్ వారీ వివరాలు'), findsOneWidget);
    expect(find.text('ఇటీవలి లావాదేవీలు'), findsOneWidget);
    expect(find.text('మొత్తం ఆదాయం'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('shows retry for retryable errors and recovers', (tester) async {
    final service = _FakeFinanceService(
      FinanceReport.fromJson(financeReportJson()),
      failure: const ApiException(statusCode: 500, message: 'Temporary error'),
    );
    final controller = FinanceController(service);

    await tester.pumpWidget(_app(FinanceScreen(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    service.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recent Transactions'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('hides retry for non-retryable errors', (tester) async {
    final controller = FinanceController(
      _FakeFinanceService(
        FinanceReport.fromJson(financeReportJson()),
        failure: const ApiException(statusCode: 401, message: 'Unauthorized'),
      ),
    );

    await tester.pumpWidget(_app(FinanceScreen(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.byType(OutlinedButton), findsNothing);
    controller.dispose();
  });

  testWidgets('pull to refresh requests the selected report again', (
    tester,
  ) async {
    final service = _FakeFinanceService(
      FinanceReport.fromJson(financeReportJson()),
    );
    final controller = FinanceController(service);

    await tester.pumpWidget(_app(FinanceScreen(controller: controller)));
    await tester.pumpAndSettle();
    expect(service.requestCount, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(service.requestCount, 2);
    controller.dispose();
  });
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

class _FakeFinanceService implements FinanceServiceContract {
  _FakeFinanceService(this.report, {this.failure});

  final FinanceReport report;
  ApiException? failure;
  int requestCount = 0;

  @override
  Future<FinanceReport> getReport({
    required FinancePeriod period,
    required int page,
    String? from,
    String? to,
  }) async {
    requestCount++;
    if (failure != null) {
      throw failure!;
    }
    return report;
  }
}
