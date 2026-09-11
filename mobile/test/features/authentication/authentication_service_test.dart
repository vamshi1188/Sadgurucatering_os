import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';
import 'package:sadguru_catering/features/authentication/services/authentication_service.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;

      switch (request.uri.path) {
        case '/auth/login':
          final body = await utf8.decoder.bind(request).join();

          if (body.contains('test-password')) {
            request.response.headers.add(
              'set-cookie',
              'sadguru_session=test-session; Path=/',
            );
            request.response.statusCode = HttpStatus.ok;
            request.response.write('{"data":{"authenticated":true}}');
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(
              '{"error":{"code":"UNAUTHORIZED","message":"Invalid password"}}',
            );
          }

        case '/auth/session':
          final cookie = request.headers.value('cookie') ?? '';

          if (cookie.contains('sadguru_session=test-session')) {
            request.response.statusCode = HttpStatus.ok;
            request.response.write('{"data":{"authenticated":true}}');
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(
              '{"error":{"code":"UNAUTHORIZED","message":"Authentication required"}}',
            );
          }

        case '/auth/logout':
          request.response.headers.add(
            'set-cookie',
            'sadguru_session=; Max-Age=0; Path=/',
          );
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"data":{"authenticated":false}}');

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

  test('login returns authenticated state and stores session cookie', () async {
    final client = ApiClient(baseUrl: baseUrl);
    final service = AuthenticationService(client);

    final state = await service.login('test-password');

    expect(state.status, AuthenticationStatus.authenticated);
    expect(state.isAuthenticated, true);

    final sessionState = await service.checkSession();

    expect(sessionState.status, AuthenticationStatus.authenticated);
  });

  test('login rejects an incorrect password', () async {
    final client = ApiClient(baseUrl: baseUrl);
    final service = AuthenticationService(client);

    expect(
      () => service.login('wrong-password'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'UNAUTHORIZED')
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('session rejects a client without authentication', () async {
    final client = ApiClient(baseUrl: baseUrl);
    final service = AuthenticationService(client);

    expect(
      () => service.checkSession(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'UNAUTHORIZED')
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('logout returns unauthenticated state', () async {
    final client = ApiClient(baseUrl: baseUrl);
    final service = AuthenticationService(client);

    final state = await service.logout();

    expect(state.status, AuthenticationStatus.unauthenticated);
    expect(state.isUnauthenticated, true);
  });
}
