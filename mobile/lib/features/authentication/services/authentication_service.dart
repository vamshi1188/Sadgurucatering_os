import '../../../core/network/api_client.dart';
import '../models/authentication_state.dart';

class AuthenticationService {
  const AuthenticationService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthenticationState> login(String password) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{'password': password},
    );

    return _authenticationStateFromResponse(response.data);
  }

  Future<AuthenticationState> checkSession() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/session',
    );

    return _authenticationStateFromResponse(response.data);
  }

  Future<AuthenticationState> logout() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/logout',
    );

    return _authenticationStateFromResponse(response.data);
  }

  AuthenticationState _authenticationStateFromResponse(
    Map<String, dynamic> data,
  ) {
    final authenticated = data['authenticated'];

    if (authenticated is! bool) {
      throw const FormatException('Invalid authentication response');
    }

    return authenticated
        ? const AuthenticationState.authenticated()
        : const AuthenticationState.unauthenticated();
  }
}
