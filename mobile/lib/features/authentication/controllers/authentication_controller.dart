import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/authentication_state.dart';
import '../services/authentication_service.dart';

class AuthenticationController extends ChangeNotifier {
  AuthenticationController(
    this._service, {
    AuthenticationState initialState = const AuthenticationState.unknown(),
  }) : _state = initialState;

  final AuthenticationService _service;

  AuthenticationState _state;
  AppError? _error;
  bool _isLoading = false;

  AuthenticationState get state => _state;
  AppError? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> checkSession() async {
    await _run(() async {
      _state = await _service.checkSession();
    }, unauthenticatedOnUnauthorized: true);
  }

  Future<bool> login(String username, String password) async {
    return _run(() async {
      _state = await _service.login(username, password);
    });
  }

  Future<bool> logout() async {
    final success = await _run(() async {
      _state = await _service.logout();
    }, unauthenticatedOnUnauthorized: true);
    if (!success) {
      _state = const AuthenticationState.unauthenticated();
      notifyListeners();
    }
    return success;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _run(() async {
      final user = await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _state = AuthenticationState.authenticated(user: user);
    });
  }

  void expireSession() {
    if (_state.isUnauthenticated) {
      return;
    }
    _state = const AuthenticationState.unauthenticated();
    notifyListeners();
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    bool unauthenticatedOnUnauthorized = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await operation();
      return true;
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);

      if (_error!.requiresAuthentication &&
          (unauthenticatedOnUnauthorized || _error!.statusCode == 401)) {
        _state = const AuthenticationState.unauthenticated();
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
