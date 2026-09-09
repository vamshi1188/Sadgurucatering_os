enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationState {
  const AuthenticationState({required this.status});

  const AuthenticationState.unknown() : status = AuthenticationStatus.unknown;

  const AuthenticationState.authenticated()
    : status = AuthenticationStatus.authenticated;

  const AuthenticationState.unauthenticated()
    : status = AuthenticationStatus.unauthenticated;

  final AuthenticationStatus status;

  bool get isAuthenticated => status == AuthenticationStatus.authenticated;

  bool get isUnauthenticated => status == AuthenticationStatus.unauthenticated;
}
