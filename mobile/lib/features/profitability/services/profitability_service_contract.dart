import '../models/profitability.dart';

abstract class ProfitabilityServiceContract {
  Future<Profitability> getProfitability(int eventId);
}
