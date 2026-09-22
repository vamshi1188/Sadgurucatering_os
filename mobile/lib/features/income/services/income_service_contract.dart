import '../models/income.dart';

abstract interface class IncomeServiceContract {
  Future<IncomeFinancials> getIncome(int eventId);

  Future<Income> createIncome({
    required int eventId,
    required String description,
    required String amount,
  });

  Future<void> deleteIncome({required int eventId, required int incomeId});
}
