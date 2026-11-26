import '../models/expense.dart';

abstract interface class ExpenseServiceContract {
  Future<ExpenseFinancials> getExpenses(int eventId);

  Future<Expense> createExpense({
    required int eventId,
    required String description,
    required String amount,
  });

  Future<void> deleteExpense({required int eventId, required int expenseId});
}
