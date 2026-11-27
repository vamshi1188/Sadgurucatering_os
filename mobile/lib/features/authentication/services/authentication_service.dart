import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/authentication_state.dart';

class AuthenticationService {
  const AuthenticationService(this._apiClient, this._secureStorage);

  final ApiClient _apiClient;
  final TokenStorage _secureStorage;

  Future<AuthenticationState> login(String username, String password) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{'username': username, 'password': password},
    );

    final token = response.data['token'];
    final userData = response.data['user'];
    if (token is! String || token.isEmpty || userData is! Map) {
      throw const FormatException('Invalid authentication response');
    }

    await _secureStorage.writeToken(token);
    return AuthenticationState.authenticated(
      user: AuthenticatedUser.fromJson(Map<String, dynamic>.from(userData)),
    );
  }

  Future<AuthenticationState> checkSession() async {
    final token = await _secureStorage.readToken();
    if (token == null || token.isEmpty) {
      return const AuthenticationState.unauthenticated();
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/session',
    );

    final userData = response.data['user'];
    if (userData is! Map) {
      throw const FormatException('Invalid session response');
    }

    return AuthenticationState.authenticated(
      user: AuthenticatedUser.fromJson(Map<String, dynamic>.from(userData)),
    );
  }

  Future<AuthenticationState> logout() async {
    try {
      await _apiClient.post<Map<String, dynamic>>('/auth/logout');
    } finally {
      await _secureStorage.clearToken();
    }
    return const AuthenticationState.unauthenticated();
  }

  Future<AuthenticatedUser> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    final userData = response.data['user'];
    if (userData is! Map) {
      throw const FormatException('Invalid password change response');
    }
    return AuthenticatedUser.fromJson(Map<String, dynamic>.from(userData));
  }
}
