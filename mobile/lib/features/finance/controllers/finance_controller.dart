import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/finance_period.dart';
import '../models/finance_report.dart';
import '../services/finance_service_contract.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(this._service);

  final FinanceServiceContract _service;

  FinanceReport? _report;
  AppError? _error;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _requestId = 0;
  FinancePeriod _period = FinancePeriod.thisMonth;
  String? _from;
  String? _to;

  FinanceReport? get report => _report;
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  FinancePeriod get period => _period;
  String? get from => _from;
  String? get to => _to;
  bool get hasMore =>
      _report != null &&
      _report!.pagination.page < _report!.pagination.totalPages;

  Future<void> load() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getReport(
        period: _period,
        page: 1,
        from: _from,
        to: _to,
      );
      if (requestId == _requestId) {
        _report = result;
      }
    } on ApiException catch (exception) {
      if (requestId == _requestId) {
        _error = ErrorHandler.fromApiException(exception);
      }
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => load();

  Future<void> retry() => load();

  Future<void> selectPeriod(
    FinancePeriod period, {
    String? from,
    String? to,
  }) async {
    final newFrom = period == FinancePeriod.custom ? from : null;
    final newTo = period == FinancePeriod.custom ? to : null;
    if (_period != period || _from != newFrom || _to != newTo) {
      _report = null;
    }
    _period = period;
    _from = newFrom;
    _to = newTo;
    await load();
  }

  Future<void> loadMore() async {
    final current = _report;
    if (current == null || !hasMore || _isLoadingMore) {
      return;
    }
    _isLoadingMore = true;
    final requestId = _requestId;
    _error = null;
    notifyListeners();
    try {
      final nextPage = await _service.getReport(
        period: _period,
        page: current.pagination.page + 1,
        from: _from,
        to: _to,
      );
      if (nextPage.period != current.period ||
          nextPage.from != current.from ||
          nextPage.to != current.to ||
          nextPage.pagination.page != current.pagination.page + 1) {
        throw const ApiException(
          code: 'INCONSISTENT_FINANCE_REPORT',
          message: 'Finance report changed while loading more transactions.',
        );
      }
      if (requestId != _requestId) {
        return;
      }
      _report = FinanceReport(
        period: current.period,
        from: current.from,
        to: current.to,
        totalIncome: nextPage.totalIncome,
        totalExpenses: nextPage.totalExpenses,
        profit: nextPage.profit,
        events: nextPage.events,
        transactions: [...current.transactions, ...nextPage.transactions],
        pagination: nextPage.pagination,
      );
    } on ApiException catch (exception) {
      if (requestId == _requestId) {
        _error = ErrorHandler.fromApiException(exception);
      }
    } finally {
      if (requestId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
