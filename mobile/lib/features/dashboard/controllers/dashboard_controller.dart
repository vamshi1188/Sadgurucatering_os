import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/dashboard_period.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_date_range_service.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(
    this._service, {
    DashboardDateRangeService? dateRangeService,
  }) : _dateRangeService =
           dateRangeService ?? const DashboardDateRangeService();

  final DashboardService _service;
  final DashboardDateRangeService _dateRangeService;

  DashboardSummary? _todaySummary;
  DashboardSummary? _financialSummary;
  DashboardSummary? _eventsSummary;
  AppError? _error;
  bool _isLoading = false;

  DashboardSummary? get todaySummary => _todaySummary;
  DashboardSummary? get financialSummary => _financialSummary;
  DashboardSummary? get eventsSummary => _eventsSummary;

  // Kept for callers that still use the original single-summary API.
  DashboardSummary? get summary => _todaySummary;
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  FinancialPeriod get financialPeriod => _financialPeriod;
  EventPeriod get eventPeriod => _eventPeriod;

  FinancialPeriod _financialPeriod = FinancialPeriod.thisMonth;
  EventPeriod _eventPeriod = EventPeriod.thisWeek;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final todayRange = _dateRangeService.financialRange(
        FinancialPeriod.today,
      );
      final financialRange = _dateRangeService.financialRange(_financialPeriod);
      final eventRange = _dateRangeService.eventRange(_eventPeriod);

      final results = await Future.wait([
        _service.getSummary(from: todayRange.from, to: todayRange.to),
        _service.getSummary(from: financialRange.from, to: financialRange.to),
        _service.getSummary(from: eventRange.from, to: eventRange.to),
      ]);

      _todaySummary = results[0];
      _financialSummary = results[1];
      _eventsSummary = results[2];
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectFinancialPeriod(FinancialPeriod period) async {
    if (_financialPeriod == period) {
      return;
    }

    _financialPeriod = period;
    await _loadFinancialSummary();
  }

  Future<void> selectEventPeriod(EventPeriod period) async {
    if (_eventPeriod == period) {
      return;
    }

    _eventPeriod = period;
    await _loadEventsSummary();
  }

  Future<void> retry() => load();

  Future<void> _loadFinancialSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final range = _dateRangeService.financialRange(_financialPeriod);
      _financialSummary = await _service.getSummary(
        from: range.from,
        to: range.to,
      );
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadEventsSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final range = _dateRangeService.eventRange(_eventPeriod);
      _eventsSummary = await _service.getSummary(
        from: range.from,
        to: range.to,
      );
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
