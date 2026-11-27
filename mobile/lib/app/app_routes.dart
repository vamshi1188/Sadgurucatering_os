import 'package:flutter/material.dart';

import '../core/errors/app_error_localization.dart';
import '../core/network/api_client.dart';
import '../core/widgets/error_view.dart';
import '../core/widgets/loading_view.dart';
import '../features/authentication/controllers/authentication_controller.dart';
import '../features/authentication/models/authentication_state.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/authentication/screens/change_password_screen.dart';
import '../features/application_shell/screens/application_shell_screen.dart';
import '../localization/app_localizations.dart';

class SadguruRoutes {
  SadguruRoutes._();

  static const String home = '/';
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes({
    required AuthenticationController authenticationController,
    required ValueChanged<Locale> onLocaleChanged,
    required ApiClient apiClient,
  }) {
    return {
      home: (context) => _AuthenticationGate(
        controller: authenticationController,
        onLocaleChanged: onLocaleChanged,
        apiClient: apiClient,
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
    required this.apiClient,
  });

  final AuthenticationController controller;
  final ValueChanged<Locale> onLocaleChanged;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final localization = AppLocalizations.of(context)!;
        final state = controller.state;

        if (state.status == AuthenticationStatus.unknown) {
          final error = controller.error;
          if (error != null) {
            return Scaffold(
              body: ErrorView(
                message: localizedAppErrorMessage(localization, error),
                retryLabel: localization.retry,
                onRetry: error.retryable ? controller.checkSession : null,
              ),
            );
          }

          return Scaffold(body: LoadingView(message: localization.loading));
        }

        if (state.isUnauthenticated || state.user == null) {
          return LoginScreen(
            controller: controller,
            onLocaleChanged: onLocaleChanged,
          );
        }

        if (state.user!.mustChangePassword) {
          return ChangePasswordScreen(controller: controller);
        }

        return ApplicationShellScreen(
          onLocaleChanged: onLocaleChanged,
          authenticationController: controller,
          apiClient: apiClient,
        );
      },
    );
  }
}
