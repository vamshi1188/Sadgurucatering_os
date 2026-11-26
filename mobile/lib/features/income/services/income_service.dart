import '../../../core/network/api_client.dart';
import '../models/income.dart';
import 'income_service_contract.dart';

class IncomeService implements IncomeServiceContract {
  const IncomeService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<IncomeFinancials> getIncome(int eventId) async {
    final response = await _apiClient.get<IncomeFinancials>(
      '/events/$eventId/financials',
      parser: (data) =>
          IncomeFinancials.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return response.data;
  }

  @override
  Future<Income> createIncome({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    final response = await _apiClient.post<Income>(
      '/events/$eventId/income',
      data: {'description': description, 'amount': amount},
      parser: (data) => Income.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return response.data;
  }

  @override
  Future<void> deleteIncome({required int eventId, required int incomeId}) {
    return _apiClient.delete('/events/$eventId/income/$incomeId');
  }
}
