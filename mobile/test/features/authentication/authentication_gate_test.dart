import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/app/sadguru_app.dart';
import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/config/environment.dart';
import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/storage/secure_storage.dart';
import 'package:sadguru_catering/features/authentication/controllers/authentication_controller.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';
import 'package:sadguru_catering/features/authentication/screens/login_screen.dart';
import 'package:sadguru_catering/features/authentication/services/authentication_service.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

import '../../support/fake_token_storage.dart';
import '../../support/test_api_client.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://127.0.0.1:1/api/v1',
  );

  testWidgets('login requires a username and password', (tester) async {
    await tester.pumpWidget(
      SadguruApp(
        config: config,
        apiClient: createTestApiClient(),
        initialAuthenticationState: const AuthenticationState.unauthenticated(),
      ),
    );

    expect(find.text('Sadguru Catering OS'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('session connection failures show a retry action', (
    tester,
  ) async {
    final apiDio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
    apiDio.httpClientAdapter = _FailingApiAdapter();
    final apiClient = ApiClient(
      baseUrl: config.apiBaseUrl,
      dio: apiDio,
      secureStorage: FakeTokenStorage()..token = 'saved-token',
    );
    await tester.pumpWidget(SadguruApp(config: config, apiClient: apiClient));

    await tester.pumpAndSettle();

    expect(
      find.text(
        "We couldn't connect to the server. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Username'), findsNothing);
  });

  testWidgets('login shows loading and a credential-specific error', (
    tester,
  ) async {
    final controller = _PendingLoginController();
    addTearDown(() {
      controller.completeLoginFailure();
      controller.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(controller: controller, onLocaleChanged: (_) {}),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'wrong-user');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextFormField>(fields.at(0)).enabled, isFalse);

    controller.completeLoginFailure();
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsNothing,
    );
  });

  testWidgets('default account is required to change its password', (
    tester,
  ) async {
    await tester.pumpWidget(
      SadguruApp(
        config: config,
        apiClient: createTestApiClient(),
        initialAuthenticationState: const AuthenticationState.authenticated(
          user: AuthenticatedUser(
            id: 1,
            username: 'admin',
            role: 'owner',
            mustChangePassword: true,
          ),
        ),
      ),
    );

    expect(find.text('Change password'), findsWidgets);
    expect(find.text('Current password'), findsOneWidget);
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });
}

class _PendingLoginController extends AuthenticationController {
  _PendingLoginController()
    : super(
        AuthenticationService(
          ApiClient(baseUrl: 'http://test.invalid'),
          _UnusedTokenStorage(),
        ),
        initialState: const AuthenticationState.unauthenticated(),
      );

  final Completer<void> _releaseLogin = Completer<void>();
  bool _isLoading = false;
  AppError? _error;

  @override
  bool get isLoading => _isLoading;

  @override
  AppError? get error => _error;

  @override
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    await _releaseLogin.future;
    _isLoading = false;
    _error = const AppError(
      type: AppErrorType.unauthorized,
      message: 'Invalid username or password',
      statusCode: 401,
    );
    notifyListeners();
    return false;
  }

  void completeLoginFailure() {
    if (!_releaseLogin.isCompleted) {
      _releaseLogin.complete();
    }
  }
}

class _UnusedTokenStorage implements TokenStorage {
  const _UnusedTokenStorage();

  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String token) async {}
}

class _FailingApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
