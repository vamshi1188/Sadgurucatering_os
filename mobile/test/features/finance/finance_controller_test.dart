import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/finance/controllers/finance_controller.dart';
import 'package:sadguru_catering/features/finance/models/finance_period.dart';
import 'package:sadguru_catering/features/finance/models/finance_report.dart';
import 'package:sadguru_catering/features/finance/services/finance_service_contract.dart';

import '../../support/finance_report_fixture.dart';

void main() {
  test('loads and refreshes the latest report', () async {
    final service = _FakeFinanceService([
      FinanceReport.fromJson(financeReportJson(profit: '10.00')),
      FinanceReport.fromJson(financeReportJson(profit: '25.00')),
    ]);
    final controller = FinanceController(service);

    await controller.load();
    expect(controller.report!.profit, '10.00');
    await controller.refresh();

    expect(controller.report!.profit, '25.00');
    expect(service.requests.map((request) => request.page), [1, 1]);
    controller.dispose();
  });

  test('exposes loading state while the request is pending', () async {
    final completer = Completer<FinanceReport>();
    final controller = FinanceController(
      _FakeFinanceService([], completer: completer),
    );

    final load = controller.load();
    expect(controller.isLoading, isTrue);
    completer.complete(FinanceReport.fromJson(financeReportJson()));
    await load;
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('maps API error and retry loads the report', () async {
    final service = _FakeFinanceService(
      [FinanceReport.fromJson(financeReportJson())],
      failure: const ApiException(
        statusCode: 500,
        message: 'Temporary failure',
      ),
    );
    final controller = FinanceController(service);

    await controller.load();
    expect(controller.error!.type, AppErrorType.server);
    expect(controller.error!.retryable, isTrue);

    service.failure = null;
    await controller.retry();
    expect(controller.error, isNull);
    expect(controller.report, isNotNull);
    controller.dispose();
  });

  test('loads additional transaction pages and retains exact profit', () async {
    final first = FinanceReport.fromJson(
      financeReportJson(
        profit: '-2.00',
        transactions: [financeTransactionJson()],
        page: 1,
        total: 2,
        totalPages: 2,
      ),
    );
    final second = FinanceReport.fromJson(
      financeReportJson(
        profit: '-2.00',
        transactions: [
          financeTransactionJson(type: 'expense', id: 2, amount: '2.00'),
        ],
        page: 2,
        total: 2,
        totalPages: 2,
      ),
    );
    final service = _FakeFinanceService([first, second]);
    final controller = FinanceController(service);

    await controller.load();
    expect(controller.hasMore, isTrue);
    await controller.loadMore();

    expect(controller.report!.transactions, hasLength(2));
    expect(controller.report!.profit, '-2.00');
    expect(service.requests.map((request) => request.page), [1, 2]);
    controller.dispose();
  });

  test(
    'selecting a custom date period sends the same filter to the service',
    () async {
      final service = _FakeFinanceService([
        FinanceReport.fromJson(financeReportJson(period: 'custom')),
      ]);
      final controller = FinanceController(service);

      await controller.selectPeriod(
        FinancePeriod.custom,
        from: '2026-09-01',
        to: '2026-09-30',
      );

      expect(service.requests.single.period, FinancePeriod.custom);
      expect(service.requests.single.from, '2026-09-01');
      expect(service.requests.single.to, '2026-09-30');
      controller.dispose();
    },
  );
}

class _FakeFinanceService implements FinanceServiceContract {
  _FakeFinanceService(this.reports, {this.completer, this.failure});

  final List<FinanceReport> reports;
  final Completer<FinanceReport>? completer;
  ApiException? failure;
  final requests = <_Request>[];

  @override
  Future<FinanceReport> getReport({
    required FinancePeriod period,
    required int page,
    String? from,
    String? to,
  }) async {
    requests.add(_Request(period, page, from, to));
    if (failure != null) {
      throw failure!;
    }
    if (completer != null) {
      return completer!.future;
    }
    final report = reports.removeAt(0);
    return FinanceReport(
      period: report.period,
      from: report.from,
      to: report.to,
      totalIncome: report.totalIncome,
      totalExpenses: report.totalExpenses,
      profit: report.profit,
      events: report.events,
      transactions: report.transactions,
      pagination: FinancePagination(
        page: page,
        pageSize: report.pagination.pageSize,
        total: report.pagination.total,
        totalPages: report.pagination.totalPages,
      ),
    );
  }
}

class _Request {
  const _Request(this.period, this.page, this.from, this.to);

  final FinancePeriod period;
  final int page;
  final String? from;
  final String? to;
}
