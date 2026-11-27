import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/features/users/services/user_management_service.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late List<String> methods;
  late Map<String, dynamic> lastBody;

  setUp(() async {
    methods = [];
    lastBody = {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      methods.add('${request.method} ${request.uri.path}');
      final body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        lastBody = jsonDecode(body) as Map<String, dynamic>;
      }

      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = HttpStatus.ok;
      if (request.method == 'GET') {
        request.response.write('{"data":[${_user(1, 'admin', 'owner')}]}');
      } else if (request.method == 'POST' &&
          request.uri.path.endsWith('/reset-password')) {
        request.response.write('{"data":{"updated":true}}');
      } else if (request.method == 'DELETE') {
        request.response.write('{"data":{"deleted":true}}');
      } else if (request.method == 'POST') {
        request.response.write('{"data":${_user(2, 'viewer', 'supervisor')}}');
      } else {
        request.response.write('{"data":${_user(2, 'viewer', 'owner')}}');
      }
      await request.response.close();
    });
    baseUrl = 'http://${server.address.host}:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('uses user-management API paths and request bodies', () async {
    final service = UserManagementService(ApiClient(baseUrl: baseUrl));

    final users = await service.listUsers();
    expect(users.single.username, 'admin');

    final created = await service.createUser(
      username: 'viewer',
      password: 'strong-password',
      role: 'supervisor',
    );
    expect(created.role, 'supervisor');
    expect(lastBody, {
      'username': 'viewer',
      'password': 'strong-password',
      'role': 'supervisor',
    });

    await service.updateUser(
      id: 2,
      username: 'viewer',
      role: 'owner',
      isActive: false,
    );
    expect(lastBody['is_active'], false);

    await service.resetPassword(id: 2, password: 'replacement-password');
    expect(lastBody['password'], 'replacement-password');

    await service.deleteUser(2);
    expect(methods, [
      'GET /users',
      'POST /users',
      'PATCH /users/2',
      'POST /users/2/reset-password',
      'DELETE /users/2',
    ]);
  });
}

String _user(int id, String username, String role) =>
    '''
{"id":$id,"username":"$username","role":"$role","is_active":true,
"must_change_password":false,"created_at":"2026-01-01T00:00:00Z"}
''';
