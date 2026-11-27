import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../features/authentication/controllers/authentication_controller.dart';
import '../features/authentication/models/authentication_state.dart';
import '../features/authentication/services/authentication_service.dart';
import '../localization/app_localizations.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class SadguruApp extends StatefulWidget {
  const SadguruApp({
    super.key,
    required this.config,
    required this.apiClient,
    this.initialAuthenticationState = const AuthenticationState.unknown(),
  });

  final AppConfig config;
  final ApiClient apiClient;
  final AuthenticationState initialAuthenticationState;

  @override
  State<SadguruApp> createState() => _SadguruAppState();
}

class _SadguruAppState extends State<SadguruApp> {
  late final AuthenticationController _authenticationController;
  final _navigatorKey = GlobalKey<NavigatorState>();

  Locale _locale = const Locale('en');
  AuthenticationStatus? _lastAuthenticationStatus;

  @override
  void initState() {
    super.initState();

    _authenticationController = AuthenticationController(
      AuthenticationService(
        widget.apiClient,
        widget.apiClient.secureStorage ?? SecureStorage(),
      ),
      initialState: widget.initialAuthenticationState,
    );
    _lastAuthenticationStatus = widget.initialAuthenticationState.status;
    widget.apiClient.onUnauthorized = _authenticationController.expireSession;
    _authenticationController.addListener(_handleAuthenticationChange);

    if (widget.initialAuthenticationState.status ==
        AuthenticationStatus.unknown) {
      _checkSession();
    }
  }

  void _handleAuthenticationChange() {
    final previous = _lastAuthenticationStatus;
    final current = _authenticationController.state.status;
    _lastAuthenticationStatus = current;
    if (previous != AuthenticationStatus.authenticated ||
        current != AuthenticationStatus.unauthenticated) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      navigator.pushNamedAndRemoveUntil('/', (route) => false);
    });
  }

  Future<void> _checkSession() async {
    await _authenticationController.checkSession();
  }

  void _changeLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }

    setState(() {
      _locale = locale;
    });
  }

  @override
  void dispose() {
    _authenticationController.removeListener(_handleAuthenticationChange);
    _authenticationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authenticationController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Sadguru Catering OS',
          debugShowCheckedModeBanner: false,
          theme: SadguruAppTheme.light(),
          locale: _locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: SadguruRoutes.home,
          routes: SadguruRoutes.routes(
            authenticationController: _authenticationController,
            onLocaleChanged: _changeLocale,
            apiClient: widget.apiClient,
          ),
        );
      },
    );
  }
}
