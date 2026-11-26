import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/expense.dart';
import '../services/expense_service_contract.dart';

class ExpenseController extends ChangeNotifier {
  ExpenseController({required this.eventId, required this.service});

  final int eventId;
  final ExpenseServiceContract service;

  List<Expense> _expenses = const [];
  String _totalExpenses = '0.00';
  AppError? _error;
  bool _isLoading = false;
  bool _isMutating = false;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  String get totalExpenses => _totalExpenses;
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _applyFinancials(await service.getExpenses(eventId));
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<bool> createExpense({
    required String description,
    required String amount,
  }) {
    return _runMutation(() async {
      await service.createExpense(
        eventId: eventId,
        description: description,
        amount: amount,
      );
      await _reloadAfterMutation();
    });
  }

  Future<bool> deleteExpense(int expenseId) {
    return _runMutation(() async {
      await service.deleteExpense(eventId: eventId, expenseId: expenseId);
      await _reloadAfterMutation();
    });
  }

  Future<void> retry() => load();

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  void _applyFinancials(ExpenseFinancials financials) {
    _expenses = List.unmodifiable(financials.expenses);
    _totalExpenses = financials.totalExpenses;
  }

  Future<void> _reloadAfterMutation() async {
    _applyFinancials(await service.getExpenses(eventId));
  }

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await mutation();
      return true;
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
