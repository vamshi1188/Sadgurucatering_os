import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';
import 'package:sadguru_catering/features/authentication/services/authentication_service.dart';

import '../../support/fake_token_storage.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late FakeTokenStorage storage;

  setUp(() async {
    storage = FakeTokenStorage();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      switch (request.uri.path) {
        case '/auth/login':
          final body = jsonDecode(
            await utf8.decoder.bind(request).join(),
          ) as Map<String, dynamic>;
          if (body['username'] == 'admin' &&
              body['password'] == 'test-password') {
            request.response.statusCode = HttpStatus.ok;
            request.response.write(
              '{"data":{"token":"test-session","user":'
              '{"id":1,"username":"admin","role":"owner",'
              '"must_change_password":true}}}',
            );
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(
              '{"error":{"code":"UNAUTHORIZED","message":"Invalid credentials"}}',
            );
          }
        case '/auth/session':
          if (request.headers.value('authorization') == 'Bearer test-session') {
            request.response.statusCode = HttpStatus.ok;
            request.response.write(
              '{"data":{"user":{"id":1,"username":"admin","role":"owner",'
              '"must_change_password":false}}}',
            );
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(
              '{"error":{"code":"UNAUTHORIZED","message":"Authentication required"}}',
            );
          }
        case '/auth/logout':
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"data":{"logged_out":true}}');
        case '/auth/change-password':
          request.response.statusCode = HttpStatus.ok;
          request.response.write(
            '{"data":{"user":{"id":1,"username":"admin","role":"owner",'
            '"must_change_password":false}}}',
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
    await server.close(force: true);
  });

  AuthenticationService createService() {
    final client = ApiClient(baseUrl: baseUrl, secureStorage: storage);
    return AuthenticationService(client, storage);
  }

  test('login stores the token securely and returns the user', () async {
    final service = createService();
    final state = await service.login('admin', 'test-password');

    expect(state.status, AuthenticationStatus.authenticated);
    expect(state.user?.username, 'admin');
    expect(state.user?.isOwner, isTrue);
    expect(state.user?.mustChangePassword, isTrue);
    expect(storage.token, 'test-session');

    final sessionState = await service.checkSession();
    expect(sessionState.user?.username, 'admin');
  });

  test('login rejects invalid credentials with a generic error', () async {
    final service = createService();
    await expectLater(
      service.login('unknown', 'wrong-password'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'UNAUTHORIZED')
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
  });

  test(
    'session check skips the API when secure storage has no token',
    () async {
      final service = createService();
      final state = await service.checkSession();

      expect(state.isUnauthenticated, isTrue);
      expect(storage.token, isNull);
    },
  );

  test('logout revokes the token and clears secure storage', () async {
    final service = createService();
    await service.login('admin', 'test-password');

    final state = await service.logout();

    expect(state.isUnauthenticated, isTrue);
    expect(storage.token, isNull);
  });

  test('first-login password change returns the updated user', () async {
    final service = createService();
    await service.login('admin', 'test-password');
    final user = await service.changePassword(
      currentPassword: 'test-password',
      newPassword: 'strong-new-password',
    );

    expect(user.mustChangePassword, isFalse);
    expect(user.username, 'admin');
  });
}
