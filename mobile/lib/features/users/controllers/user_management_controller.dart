import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/managed_user.dart';
import '../services/user_management_service.dart';

class UserManagementController extends ChangeNotifier {
  UserManagementController(this._service);

  final UserManagementServiceContract _service;

  List<ManagedUser> _users = const [];
  AppError? _error;
  bool _isLoading = false;
  bool _isMutating = false;

  List<ManagedUser> get users => List.unmodifiable(_users);
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _service.listUsers();
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String username,
    required String password,
    required String role,
  }) => _mutate(() async {
    await _service.createUser(
      username: username,
      password: password,
      role: role,
    );
    _users = await _service.listUsers();
  });

  Future<bool> updateUser({
    required int id,
    required String username,
    required String role,
    required bool isActive,
  }) => _mutate(() async {
    await _service.updateUser(
      id: id,
      username: username,
      role: role,
      isActive: isActive,
    );
    _users = await _service.listUsers();
  });

  Future<bool> resetPassword({required int id, required String password}) =>
      _mutate(() async {
        await _service.resetPassword(id: id, password: password);
        _users = await _service.listUsers();
      });

  Future<bool> deleteUser(int id) => _mutate(() async {
    await _service.deleteUser(id);
    _users = await _service.listUsers();
  });

  Future<bool> _mutate(Future<void> Function() operation) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
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
