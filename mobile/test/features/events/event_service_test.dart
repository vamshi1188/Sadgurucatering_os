import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';
import 'package:sadguru_catering/features/events/services/event_service.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      final path = request.uri.path;

      if (path == '/events' && request.method == 'GET') {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'data': [
              _eventJson(1, 'Wedding', 'upcoming'),
              _eventJson(2, 'Birthday', 'running'),
            ],
          }),
        );
      } else if (path == '/events/1' && request.method == 'GET') {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'data': _eventJson(1, 'Wedding', 'upcoming')}),
        );
      } else if (path == '/events' && request.method == 'POST') {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;

        expect(payload['title'], 'Wedding Reception');
        expect(payload['event_date'], '2026-09-05');
        expect(payload['venue'], 'Sadguru Function Hall');
        expect(payload['guest_count'], 500);
        expect(payload.containsKey('status'), isFalse);

        request.response.statusCode = HttpStatus.created;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'data': _eventJson(3, 'Wedding Reception', 'upcoming')}),
        );
      } else if (path == '/events/1/status' && request.method == 'PATCH') {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;

        expect(payload['status'], 'running');

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'data': _eventJson(1, 'Wedding', 'running')}),
        );
      } else if (path == '/events/1' && request.method == 'DELETE') {
        request.response.statusCode = HttpStatus.noContent;
      } else if (path == '/events/999' && request.method == 'GET') {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          '{"error":{"code":"NOT_FOUND","message":"Event not found"}}',
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }

      await request.response.close();
    });

    baseUrl = 'http://${server.address.host}:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
  });

  EventService createService() {
    return EventService(ApiClient(baseUrl: baseUrl));
  }

  test('getEvents parses event list', () async {
    final events = await createService().getEvents();

    expect(events, hasLength(2));
    expect(events[0].id, 1);
    expect(events[0].title, 'Wedding');
    expect(events[0].status, EventStatus.upcoming);
    expect(events[1].status, EventStatus.running);
  });

  test('getEvent parses a single event', () async {
    final event = await createService().getEvent(1);

    expect(event.id, 1);
    expect(event.title, 'Wedding');
    expect(event.status, EventStatus.upcoming);
  });

  test('createEvent sends the correct backend payload', () async {
    final event = await createService().createEvent(
      title: 'Wedding Reception',
      eventDate: '2026-09-05',
      venue: 'Sadguru Function Hall',
      guestCount: 500,
    );

    expect(event.id, 3);
    expect(event.title, 'Wedding Reception');
    expect(event.status, EventStatus.upcoming);
  });

  test('updateStatus sends the backend status payload', () async {
    final event = await createService().updateStatus(1, EventStatus.running);

    expect(event.id, 1);
    expect(event.status, EventStatus.running);
  });

  test('deleteEvent accepts backend 204 response', () async {
    await expectLater(createService().deleteEvent(1), completes);
  });

  test('backend errors become ApiException', () async {
    final service = createService();

    expect(
      () => service.getEvent(999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'NOT_FOUND')
            .having((e) => e.message, 'message', 'Event not found')
            .having((e) => e.statusCode, 'statusCode', HttpStatus.notFound),
      ),
    );
  });
}

Map<String, dynamic> _eventJson(int id, String title, String status) {
  return {
    'id': id,
    'title': title,
    'event_date': '2026-09-05',
    'venue': 'Sadguru Function Hall',
    'guest_count': 500,
    'status': status,
    'created_at': '2026-09-03T10:00:00Z',
    'updated_at': '2026-09-03T10:00:00Z',
  };
}
