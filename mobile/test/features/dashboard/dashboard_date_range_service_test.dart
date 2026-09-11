import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_period.dart';
import 'package:sadguru_catering/features/dashboard/services/dashboard_date_range_service.dart';

void main() {
  const service = DashboardDateRangeService();
  final date = DateTime(2026, 9, 11);

  test('calculates financial periods', () {
    expect(
      service.financialRange(FinancialPeriod.today, now: date).from,
      '2026-09-11',
    );
    expect(
      service.financialRange(FinancialPeriod.today, now: date).to,
      '2026-09-11',
    );
    expect(
      service.financialRange(FinancialPeriod.thisMonth, now: date).from,
      '2026-09-01',
    );
    expect(
      service.financialRange(FinancialPeriod.thisMonth, now: date).to,
      '2026-09-30',
    );
    expect(
      service.financialRange(FinancialPeriod.thisYear, now: date).from,
      '2026-01-01',
    );
    expect(
      service.financialRange(FinancialPeriod.thisYear, now: date).to,
      '2026-12-31',
    );
  });

  test('calculates event periods from Monday through Sunday', () {
    expect(service.eventRange(EventPeriod.today, now: date).from, '2026-09-11');
    expect(service.eventRange(EventPeriod.today, now: date).to, '2026-09-11');
    expect(
      service.eventRange(EventPeriod.tomorrow, now: date).from,
      '2026-09-12',
    );
    expect(
      service.eventRange(EventPeriod.tomorrow, now: date).to,
      '2026-09-12',
    );
    expect(
      service.eventRange(EventPeriod.thisWeek, now: date).from,
      '2026-09-07',
    );
    expect(
      service.eventRange(EventPeriod.thisWeek, now: date).to,
      '2026-09-13',
    );
    expect(
      service.eventRange(EventPeriod.thisMonth, now: date).from,
      '2026-09-01',
    );
    expect(
      service.eventRange(EventPeriod.thisMonth, now: date).to,
      '2026-09-30',
    );
    expect(
      service.eventRange(EventPeriod.thisYear, now: date).from,
      '2026-01-01',
    );
    expect(
      service.eventRange(EventPeriod.thisYear, now: date).to,
      '2026-12-31',
    );
  });
}
