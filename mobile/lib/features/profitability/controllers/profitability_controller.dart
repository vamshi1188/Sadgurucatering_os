import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/profitability.dart';
import '../services/profitability_service_contract.dart';

class ProfitabilityController extends ChangeNotifier {
  ProfitabilityController({required this.eventId, required this.service});

  final int eventId;
  final ProfitabilityServiceContract service;

  Profitability? _profitability;
  AppError? _error;
  bool _isLoading = false;

  Profitability? get profitability => _profitability;
  AppError? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profitability = await service.getProfitability(eventId);
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> retry() => load();

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }
}
