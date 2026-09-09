import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      switch (request.uri.path) {
        case '/success':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.ok;
          request.response.write(
            '{"data":{"status":"ok"},"meta":{"request_id":"req_123"}}',
          );

        case '/created':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.created;
          request.response.write('{"data":{"created":true}}');

        case '/updated':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"data":{"updated":true}}');

        case '/error':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(
            '{"error":{"code":"UNAUTHORIZED","message":"Authentication required"}}',
          );

        case '/forbidden':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write(
            '{"error":{"code":"FORBIDDEN","message":"Access denied"}}',
          );

        case '/not-found':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(
            '{"error":{"code":"NOT_FOUND","message":"Resource not found"}}',
          );

        case '/server-error':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.write(
            '{"error":{"code":"SERVER_ERROR","message":"Server failure"}}',
          );

        case '/invalid':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"unexpected":true}');

        case '/set-cookie':
          request.response.headers.contentType = ContentType.json;
          request.response.headers.add(
            'set-cookie',
            'sadguru_session=test-session; Path=/',
          );
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"data":{"authenticated":true}}');

        case '/check-cookie':
          request.response.headers.contentType = ContentType.json;
          final cookie = request.headers.value('cookie') ?? '';

          if (cookie.contains('sadguru_session=test-session')) {
            request.response.statusCode = HttpStatus.ok;
            request.response.write('{"data":{"cookie_received":true}}');
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(
              '{"error":{"code":"UNAUTHORIZED","message":"Cookie missing"}}',
            );
          }

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

  test('GET parses data and request ID', () async {
    final client = ApiClient(baseUrl: baseUrl);

    final response = await client.get<Map<String, dynamic>>(
      '/success',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(response.data['status'], 'ok');
    expect(response.requestId, 'req_123');
  });

  test('POST parses created response', () async {
    final client = ApiClient(baseUrl: baseUrl);

    final response = await client.post<Map<String, dynamic>>(
      '/created',
      data: {'name': 'Test'},
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(response.data['created'], true);
  });

  test('PATCH parses updated response', () async {
    final client = ApiClient(baseUrl: baseUrl);

    final response = await client.patch<Map<String, dynamic>>(
      '/updated',
      data: {'status': 'running'},
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(response.data['updated'], true);
  });

  test('parses backend error envelope', () async {
    final client = ApiClient(baseUrl: baseUrl);

    expect(
      () => client.get<dynamic>('/error'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'UNAUTHORIZED')
            .having((e) => e.message, 'message', 'Authentication required')
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('rejects invalid success response', () async {
    final client = ApiClient(baseUrl: baseUrl);

    expect(
      () => client.get<dynamic>('/invalid'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Invalid server response',
        ),
      ),
    );
  });

  test('connection failure becomes ApiException', () async {
    await server.close(force: true);
    final client = ApiClient(baseUrl: baseUrl);

    expect(
      () => client.get<dynamic>('/success'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Unable to connect to the server',
        ),
      ),
    );
  });

  test('connection timeout becomes ApiException', () async {
    final client = _clientWithDioException(DioExceptionType.connectionTimeout);

    expect(
      () => client.get<dynamic>('/success'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'The request timed out',
        ),
      ),
    );
  });

  test('receive timeout becomes ApiException', () async {
    final client = _clientWithDioException(DioExceptionType.receiveTimeout);

    expect(
      () => client.get<dynamic>('/success'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'The request timed out',
        ),
      ),
    );
  });

  test('preserves API error details for common HTTP failures', () async {
    final client = ApiClient(baseUrl: baseUrl);

    final cases = <String, List<Object>>{
      '/error': [HttpStatus.unauthorized, 'UNAUTHORIZED', 'Authentication required'],
      '/forbidden': [HttpStatus.forbidden, 'FORBIDDEN', 'Access denied'],
      '/not-found': [HttpStatus.notFound, 'NOT_FOUND', 'Resource not found'],
      '/server-error': [HttpStatus.internalServerError, 'SERVER_ERROR', 'Server failure'],
    };

    for (final entry in cases.entries) {
      expect(
        () => client.get<dynamic>(entry.key),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', entry.value[0])
              .having((e) => e.code, 'code', entry.value[1])
              .having((e) => e.message, 'message', entry.value[2]),
        ),
      );
    }
  });

  test('persists session cookie between requests', () async {
    final client = ApiClient(baseUrl: baseUrl, cookieJar: CookieJar());

    final loginResponse = await client.get<Map<String, dynamic>>(
      '/set-cookie',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(loginResponse.data['authenticated'], true);

    final sessionResponse = await client.get<Map<String, dynamic>>(
      '/check-cookie',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(sessionResponse.data['cookie_received'], true);
  });
}

ApiClient _clientWithDioException(DioExceptionType type) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'));
  dio.httpClientAdapter = _ThrowingAdapter(type);
  return ApiClient(baseUrl: 'http://test.invalid', dio: dio);
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.type);

  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: type,
    );
  }

  @override
  void close({bool force = false}) {}
}
