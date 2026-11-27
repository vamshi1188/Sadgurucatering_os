import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/finance/models/finance_report.dart';

import '../../support/finance_report_fixture.dart';

void main() {
  test('preserves exact decimal strings and positive profit', () {
    final report = FinanceReport.fromJson(financeReportJson());

    expect(report.totalIncome, '50000.00');
    expect(report.totalExpenses, '18000.00');
    expect(report.profit, '32000.00');
  });

  test('preserves negative and zero profit without recalculation', () {
    expect(
      FinanceReport.fromJson(
        financeReportJson(
          totalIncome: '100.00',
          totalExpenses: '300.00',
          profit: '-200.00',
        ),
      ).profit,
      '-200.00',
    );
    expect(
      FinanceReport.fromJson(
        financeReportJson(
          totalIncome: '0.00',
          totalExpenses: '0.00',
          profit: '0.00',
        ),
      ).profit,
      '0.00',
    );
  });

  test(
    'uses the backend profit even when it differs from local subtraction',
    () {
      final report = FinanceReport.fromJson(
        financeReportJson(
          totalIncome: '50000.00',
          totalExpenses: '18000.00',
          profit: '123.45',
        ),
      );

      expect(report.profit, '123.45');
    },
  );

  test('accepts empty event and transaction arrays', () {
    final report = FinanceReport.fromJson(financeReportJson());

    expect(report.events, isEmpty);
    expect(report.transactions, isEmpty);
  });

  test('parses event and income and expense transaction collections', () {
    final report = FinanceReport.fromJson(
      financeReportJson(
        events: [financeEventJson()],
        transactions: [
          financeTransactionJson(),
          financeTransactionJson(type: 'expense', id: 2, amount: '20.00'),
        ],
        total: 2,
        totalPages: 1,
      ),
    );

    expect(report.events.single.id, 7);
    expect(report.transactions.map((transaction) => transaction.type), [
      'income',
      'expense',
    ]);
  });

  test('rejects missing and malformed required fields', () {
    for (final field in [
      'period',
      'total_income',
      'total_expenses',
      'profit',
      'events',
      'transactions',
      'pagination',
    ]) {
      final json = financeReportJson()..remove(field);
      expect(
        () => FinanceReport.fromJson(json),
        throwsA(isA<FormatException>()),
        reason: field,
      );
    }

    for (final amount in [500.00, null, '1.2', 'NaN', '1.234']) {
      final json = financeReportJson()..['total_income'] = amount;
      expect(
        () => FinanceReport.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('rejects malformed event and transaction rows', () {
    expect(
      () => FinanceReport.fromJson(
        financeReportJson(events: [financeEventJson(profit: 'invalid')]),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => FinanceReport.fromJson(
        financeReportJson(
          transactions: [financeTransactionJson(type: 'refund')],
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
