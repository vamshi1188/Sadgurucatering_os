import '../../../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  const DashboardService(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> getSummary({String? from, String? to}) async {
    final response = await _apiClient.get<DashboardSummary>(
      '/dashboard/summary',
      queryParameters: {
        ...?from == null ? null : {'from': from},
        ...?to == null ? null : {'to': to},
      },
      parser: (data) {
        return DashboardSummary.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
      },
    );

    return response.data;
  }
}
