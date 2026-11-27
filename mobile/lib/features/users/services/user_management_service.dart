import '../../../core/network/api_client.dart';
import '../models/managed_user.dart';

abstract interface class UserManagementServiceContract {
  Future<List<ManagedUser>> listUsers();
  Future<ManagedUser> createUser({
    required String username,
    required String password,
    required String role,
  });
  Future<ManagedUser> updateUser({
    required int id,
    required String username,
    required String role,
    required bool isActive,
  });
  Future<void> resetPassword({required int id, required String password});
  Future<void> deleteUser(int id);
}

class UserManagementService implements UserManagementServiceContract {
  const UserManagementService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ManagedUser>> listUsers() async {
    final response = await _apiClient.get<List<ManagedUser>>(
      '/users',
      parser: (data) => (data as List)
          .map(
            (item) =>
                ManagedUser.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
    return response.data;
  }

  @override
  Future<ManagedUser> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await _apiClient.post<ManagedUser>(
      '/users',
      data: {'username': username, 'password': password, 'role': role},
      parser: (data) =>
          ManagedUser.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return response.data;
  }

  @override
  Future<ManagedUser> updateUser({
    required int id,
    required String username,
    required String role,
    required bool isActive,
  }) async {
    final response = await _apiClient.patch<ManagedUser>(
      '/users/$id',
      data: {'username': username, 'role': role, 'is_active': isActive},
      parser: (data) =>
          ManagedUser.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return response.data;
  }

  @override
  Future<void> resetPassword({
    required int id,
    required String password,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/users/$id/reset-password',
      data: {'password': password},
    );
  }

  @override
  Future<void> deleteUser(int id) => _apiClient.delete('/users/$id');
}
