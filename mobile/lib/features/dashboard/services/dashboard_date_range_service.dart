import '../models/dashboard_date_range.dart';
import '../models/dashboard_period.dart';

class DashboardDateRangeService {
  const DashboardDateRangeService();

  DashboardDateRange financialRange(FinancialPeriod period, {DateTime? now}) {
    final date = _dateOnly(now ?? DateTime.now());

    switch (period) {
      case FinancialPeriod.today:
        return _range(date, date);
      case FinancialPeriod.thisMonth:
        return _range(
          DateTime(date.year, date.month, 1),
          DateTime(date.year, date.month + 1, 0),
        );
      case FinancialPeriod.thisYear:
        return _range(DateTime(date.year, 1, 1), DateTime(date.year, 12, 31));
    }
  }

  DashboardDateRange eventRange(EventPeriod period, {DateTime? now}) {
    final date = _dateOnly(now ?? DateTime.now());

    switch (period) {
      case EventPeriod.today:
        return _range(date, date);
      case EventPeriod.tomorrow:
        final tomorrow = date.add(const Duration(days: 1));
        return _range(tomorrow, tomorrow);
      case EventPeriod.thisWeek:
        final from = date.subtract(
          Duration(days: date.weekday - DateTime.monday),
        );
        return _range(from, from.add(const Duration(days: 6)));
      case EventPeriod.thisMonth:
        return _range(
          DateTime(date.year, date.month, 1),
          DateTime(date.year, date.month + 1, 0),
        );
      case EventPeriod.thisYear:
        return _range(DateTime(date.year, 1, 1), DateTime(date.year, 12, 31));
    }
  }

  DashboardDateRange _range(DateTime from, DateTime to) {
    return DashboardDateRange(from: _format(from), to: _format(to));
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _format(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
