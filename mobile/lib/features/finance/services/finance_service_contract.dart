import '../models/finance_period.dart';
import '../models/finance_report.dart';

abstract interface class FinanceServiceContract {
  Future<FinanceReport> getReport({
    required FinancePeriod period,
    required int page,
    String? from,
    String? to,
  });
}
