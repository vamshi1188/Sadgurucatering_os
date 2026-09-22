import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/income.dart';
import '../services/income_service_contract.dart';

class IncomeController extends ChangeNotifier {
  IncomeController({required this.eventId, required this.service});

  final int eventId;
  final IncomeServiceContract service;

  List<Income> _incomes = const [];
  String _totalIncome = '0.00';
  AppError? _error;
  bool _isLoading = false;
  bool _isMutating = false;

  List<Income> get incomes => List.unmodifiable(_incomes);
  String get totalIncome => _totalIncome;
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final financials = await service.getIncome(eventId);
      _applyFinancials(financials);
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<bool> createIncome({
    required String description,
    required String amount,
  }) {
    return _runMutation(() async {
      await service.createIncome(
        eventId: eventId,
        description: description,
        amount: amount,
      );
      await _reloadAfterMutation();
    });
  }

  Future<bool> deleteIncome(int incomeId) {
    return _runMutation(() async {
      await service.deleteIncome(eventId: eventId, incomeId: incomeId);
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

  void _applyFinancials(IncomeFinancials financials) {
    _incomes = List.unmodifiable(financials.income);
    _totalIncome = financials.totalIncome;
  }

  Future<void> _reloadAfterMutation() async {
    final financials = await service.getIncome(eventId);
    _applyFinancials(financials);
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
