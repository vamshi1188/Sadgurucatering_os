import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/features/authentication/controllers/authentication_controller.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';
import 'package:sadguru_catering/features/authentication/services/authentication_service.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  var holdLogin = false;
  Completer<void>? loginRelease;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;

      switch (request.uri.path) {
        case '/auth/login':
          final body = await utf8.decoder.bind(request).join();
          if (holdLogin) {
            await loginRelease!.future;
          }

          final payload = jsonDecode(body) as Map<String, dynamic>;
          if (payload['password'] == 'test-password') {
            request.response.statusCode = HttpStatus.ok;
            request.response.write('{"data":{"authenticated":true}}');
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(
              '{"error":{"code":"UNAUTHORIZED","message":"Invalid password"}}',
            );
          }

        case '/auth/session':
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(
            '{"error":{"code":"UNAUTHORIZED","message":"Session expired"}}',
          );

        default:
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(
            '{"error":{"code":"NOT_FOUND","message":"Resource not found"}}',
          );
      }

      await request.response.close();
    });

    baseUrl = 'http://${server.address.host}:${server.port}';
  });

  tearDown(() async {
    if (loginRelease != null && !loginRelease!.isCompleted) {
      loginRelease!.complete();
    }
    holdLogin = false;
    loginRelease = null;
    await server.close(force: true);
  });

  AuthenticationController createController({
    AuthenticationState initialState = const AuthenticationState.unknown(),
  }) {
    final client = ApiClient(baseUrl: baseUrl);
    return AuthenticationController(
      AuthenticationService(client),
      initialState: initialState,
    );
  }

  test('successful login updates state and clears errors', () async {
    final controller = createController();

    final success = await controller.login('test-password');

    expect(success, isTrue);
    expect(controller.state.isAuthenticated, isTrue);
    expect(controller.error, isNull);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('failed login is exposed as an AppError', () async {
    final controller = createController();

    final success = await controller.login('wrong-password');

    expect(success, isFalse);
    expect(controller.error, isA<AppError>());
    expect(controller.error!.message, 'Invalid password');
    expect(controller.error!.statusCode, HttpStatus.unauthorized);
    controller.dispose();
  });

  test('401 errors map to unauthorized AppError', () async {
    final controller = createController();

    await controller.login('wrong-password');

    expect(controller.error!.type, AppErrorType.unauthorized);
    expect(controller.error!.requiresAuthentication, isTrue);
    expect(controller.error!.retryable, isFalse);
    controller.dispose();
  });

  test('expired session changes state to unauthenticated', () async {
    final controller = createController(
      initialState: const AuthenticationState.authenticated(),
    );

    await controller.checkSession();

    expect(controller.state.isUnauthenticated, isTrue);
    expect(controller.error!.type, AppErrorType.unauthorized);
    controller.dispose();
  });

  test('controller reports loading while an operation is pending', () async {
    holdLogin = true;
    loginRelease = Completer<void>();
    final controller = createController();

    final operation = controller.login('test-password');
    expect(controller.isLoading, isTrue);

    loginRelease!.complete();
    await operation;

    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('new operation clears the previous error immediately', () async {
    final controller = createController();
    await controller.login('wrong-password');
    expect(controller.error, isNotNull);

    holdLogin = true;
    loginRelease = Completer<void>();
    final operation = controller.login('test-password');

    expect(controller.error, isNull);
    expect(controller.isLoading, isTrue);

    loginRelease!.complete();
    await operation;
    controller.dispose();
  });

  test('successful operation clears a previous error', () async {
    final controller = createController();
    await controller.login('wrong-password');
    expect(controller.error, isNotNull);

    final success = await controller.login('test-password');

    expect(success, isTrue);
    expect(controller.error, isNull);
    expect(controller.state.isAuthenticated, isTrue);
    controller.dispose();
  });
}