import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/profitability.dart';
import 'profitability_service_contract.dart';

class ProfitabilityService implements ProfitabilityServiceContract {
  const ProfitabilityService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Profitability> getProfitability(int eventId) async {
    final response = await _apiClient.get<Profitability>(
      '/events/$eventId/financials',
      parser: (data) {
        if (data is! Map) {
          throw const ApiException(
            code: 'INVALID_FINANCIALS_RESPONSE',
            message: 'Invalid financials response: expected an object.',
          );
        }

        try {
          return Profitability.fromJson(Map<String, dynamic>.from(data));
        } on FormatException catch (error) {
          throw ApiException(
            code: 'INVALID_FINANCIALS_RESPONSE',
            message: error.message,
          );
        }
      },
    );

    return response.data;
  }
}
