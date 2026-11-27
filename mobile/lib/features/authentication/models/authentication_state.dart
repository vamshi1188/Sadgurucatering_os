enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.username,
    required this.role,
    required this.mustChangePassword,
  });

  final int id;
  final String username;
  final String role;
  final bool mustChangePassword;

  bool get isOwner => role.toLowerCase() == 'owner';

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    final role = json['role'];
    final mustChangePassword = json['must_change_password'];

    if (id is! int ||
        username is! String ||
        role is! String ||
        mustChangePassword is! bool) {
      throw const FormatException('Invalid user response');
    }

    return AuthenticatedUser(
      id: id,
      username: username,
      role: role,
      mustChangePassword: mustChangePassword,
    );
  }
}

class AuthenticationState {
  const AuthenticationState({required this.status, this.user});

  const AuthenticationState.unknown()
    : status = AuthenticationStatus.unknown,
      user = null;

  const AuthenticationState.authenticated({this.user})
    : status = AuthenticationStatus.authenticated;

  const AuthenticationState.unauthenticated()
    : status = AuthenticationStatus.unauthenticated,
      user = null;

  final AuthenticationStatus status;
  final AuthenticatedUser? user;

  bool get isAuthenticated => status == AuthenticationStatus.authenticated;

  bool get isUnauthenticated => status == AuthenticationStatus.unauthenticated;
}
