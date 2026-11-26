import '../../../core/network/api_client.dart';
import '../models/expense.dart';
import 'expense_service_contract.dart';

class ExpenseService implements ExpenseServiceContract {
  const ExpenseService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ExpenseFinancials> getExpenses(int eventId) async {
    final response = await _apiClient.get<ExpenseFinancials>(
      '/events/$eventId/financials',
      parser: (data) =>
          ExpenseFinancials.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return response.data;
  }

  @override
  Future<Expense> createExpense({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    final response = await _apiClient.post<Expense>(
      '/events/$eventId/expenses',
      data: {'description': description, 'amount': amount},
      parser: (data) =>
          Expense.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return response.data;
  }

  @override
  Future<void> deleteExpense({required int eventId, required int expenseId}) {
    return _apiClient.delete('/events/$eventId/expenses/$expenseId');
  }
}
