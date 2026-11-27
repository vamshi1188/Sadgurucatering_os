import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/finance_period.dart';
import '../models/finance_report.dart';
import 'finance_service_contract.dart';

class FinanceService implements FinanceServiceContract {
  const FinanceService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<FinanceReport> getReport({
    required FinancePeriod period,
    required int page,
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.get<FinanceReport>(
      '/finance/summary',
      queryParameters: {
        'period': period.apiValue,
        'page': page,
        'page_size': 20,
        'from': ?from,
        'to': ?to,
      },
      parser: (data) {
        if (data is! Map) {
          throw const ApiException(
            code: 'INVALID_FINANCE_REPORT_RESPONSE',
            message: 'Invalid finance report response: expected an object.',
          );
        }
        try {
          return FinanceReport.fromJson(Map<String, dynamic>.from(data));
        } on FormatException catch (error) {
          throw ApiException(
            code: 'INVALID_FINANCE_REPORT_RESPONSE',
            message: error.message,
          );
        }
      },
    );

    return response.data;
  }
}
