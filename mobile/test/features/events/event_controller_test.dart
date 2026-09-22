import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/events/controllers/event_controller.dart';
import 'package:sadguru_catering/features/events/models/event.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';
import 'package:sadguru_catering/features/events/services/event_service_contract.dart';

void main() {
  late _FakeEventService service;
  late EventController controller;

  setUp(() {
    service = _FakeEventService();
    controller = EventController(service);
  });

  tearDown(() {
    controller.dispose();
  });

  test('load populates events', () async {
    await controller.load();

    expect(controller.events, hasLength(2));
    expect(controller.events.first.title, 'Wedding');
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('load maps API errors', () async {
    service.shouldFail = true;

    await controller.load();

    expect(controller.events, isEmpty);
    expect(controller.error?.type, AppErrorType.server);
    expect(controller.isLoading, isFalse);
  });

  test('refresh reloads events', () async {
    await controller.load();

    service.events = [_event(3, 'New Event', EventStatus.upcoming)];

    await controller.refresh();

    expect(controller.events, hasLength(1));
    expect(controller.events.single.id, 3);
  });

  test('selectEvent loads selected event', () async {
    await controller.selectEvent(1);

    expect(controller.selectedEvent?.id, 1);
    expect(controller.selectedEvent?.title, 'Wedding');
    expect(controller.error, isNull);
  });

  test('createEvent adds server event and selects it', () async {
    final result = await controller.createEvent(
      title: 'Reception',
      eventDate: '2026-09-20',
      venue: 'Function Hall',
      guestCount: 300,
    );

    expect(result, isTrue);
    expect(controller.events, hasLength(1));
    expect(controller.selectedEvent?.title, 'Reception');
    expect(controller.selectedEvent?.id, 10);
    expect(controller.isMutating, isFalse);
  });

  test('createEvent maps API errors', () async {
    service.shouldFail = true;

    final result = await controller.createEvent(
      title: 'Reception',
      eventDate: '2026-09-20',
      venue: 'Function Hall',
      guestCount: 300,
    );

    expect(result, isFalse);
    expect(controller.error?.type, AppErrorType.server);
    expect(controller.isMutating, isFalse);
  });

  test('updateStatus replaces the server event', () async {
    await controller.load();

    final result = await controller.updateStatus(1, EventStatus.running);

    expect(result, isTrue);
    expect(controller.events.first.status, EventStatus.running);
  });

  test('updateStatus updates selected event', () async {
    await controller.selectEvent(1);

    await controller.updateStatus(1, EventStatus.running);

    expect(controller.selectedEvent?.status, EventStatus.running);
  });

  test('deleteEvent removes event and clears selected event', () async {
    await controller.load();
    await controller.selectEvent(1);

    final result = await controller.deleteEvent(1);

    expect(result, isTrue);
    expect(controller.events, hasLength(1));
    expect(controller.events.single.id, 2);
    expect(controller.selectedEvent, isNull);
  });

  test('retry reloads events', () async {
    service.shouldFail = true;

    await controller.load();

    expect(controller.error, isNotNull);

    service.shouldFail = false;
    service.events = [_event(5, 'Retry Event', EventStatus.upcoming)];

    await controller.retry();

    expect(controller.error, isNull);
    expect(controller.events.single.id, 5);
  });

  test('clearError removes current error', () async {
    service.shouldFail = true;

    await controller.load();

    expect(controller.error, isNotNull);

    controller.clearError();

    expect(controller.error, isNull);
  });

  test('clearSelectedEvent removes selected event', () async {
    await controller.selectEvent(1);

    controller.clearSelectedEvent();

    expect(controller.selectedEvent, isNull);
  });
}

class _FakeEventService implements EventServiceContract {
  List<Event> events = [
    _event(1, 'Wedding', EventStatus.upcoming),
    _event(2, 'Birthday', EventStatus.running),
  ];

  bool shouldFail = false;

  @override
  Future<List<Event>> getEvents() async {
    _throwIfNeeded();
    return events;
  }

  @override
  Future<Event> getEvent(int id) async {
    _throwIfNeeded();

    return events.firstWhere(
      (event) => event.id == id,
      orElse: () => _event(id, 'Selected Event', EventStatus.upcoming),
    );
  }

  @override
  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) async {
    _throwIfNeeded();

    return _event(10, title, EventStatus.upcoming);
  }

  @override
  Future<Event> updateStatus(int id, EventStatus status) async {
    _throwIfNeeded();

    final existing = events.firstWhere((event) => event.id == id);

    final updated = _event(existing.id, existing.title, status);

    events = events.map((event) => event.id == id ? updated : event).toList();

    return updated;
  }

  @override
  Future<void> deleteEvent(int id) async {
    _throwIfNeeded();

    events = events.where((event) => event.id != id).toList();
  }

  void _throwIfNeeded() {
    if (shouldFail) {
      throw const ApiException(
        code: 'SERVER_ERROR',
        message: 'Temporary failure',
        statusCode: 500,
      );
    }
  }
}

Event _event(int id, String title, EventStatus status) {
  return Event(
    id: id,
    title: title,
    eventDate: '2026-09-05',
    venue: 'Sadguru Function Hall',
    guestCount: 500,
    status: status,
    createdAt: DateTime.parse('2026-09-03T10:00:00Z'),
    updatedAt: DateTime.parse('2026-09-03T10:00:00Z'),
  );
}
