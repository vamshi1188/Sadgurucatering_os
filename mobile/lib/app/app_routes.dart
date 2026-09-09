import 'package:flutter/material.dart';

import '../features/authentication/controllers/authentication_controller.dart';
import '../features/authentication/models/authentication_state.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/application_shell/screens/application_shell_screen.dart';

class SadguruRoutes {
  SadguruRoutes._();

  static const String home = '/';
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes({
    required AuthenticationController authenticationController,
    required ValueChanged<Locale> onLocaleChanged,
  }) {
    return {
      home: (context) => _AuthenticationGate(
        controller: authenticationController,
        onLocaleChanged: onLocaleChanged,
      ),
      login: (context) => LoginScreen(
        controller: authenticationController,
        onLocaleChanged: onLocaleChanged,
      ),
    };
  }
}

class _AuthenticationGate extends StatelessWidget {
  const _AuthenticationGate({
    required this.controller,
    required this.onLocaleChanged,
  });

  final AuthenticationController controller;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    if (state.status == AuthenticationStatus.unknown) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.isUnauthenticated) {
      return LoginScreen(
        controller: controller,
        onLocaleChanged: onLocaleChanged,
      );
    }

    return ApplicationShellScreen(
      onLocaleChanged: onLocaleChanged,
      authenticationController: controller,
    );
  }
}