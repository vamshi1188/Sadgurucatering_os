import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/events/controllers/event_controller.dart';
import 'package:sadguru_catering/features/events/models/event.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';
import 'package:sadguru_catering/features/events/screens/event_list_screen.dart';
import 'package:sadguru_catering/features/events/services/event_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeEventService implements EventServiceContract {
  _FakeEventService({this.events = const []});

  final List<Event> events;

  int getEventsCalls = 0;

  @override
  Future<List<Event>> getEvents() async {
    getEventsCalls++;

    return events;
  }

  @override
  Future<Event> getEvent(int id) async =>
      events.firstWhere((event) => event.id == id);

  @override
  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Event> updateStatus(int id, EventStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(int id) {
    throw UnimplementedError();
  }
}

Event _event({
  int id = 1,
  String title = 'Wedding Reception',
  String date = '2026-09-20',
  String venue = 'Sadguru Function Hall',
  int guests = 500,
  EventStatus status = EventStatus.upcoming,
}) {
  final timestamp = DateTime(2026, 9, 1, 10);

  return Event(
    id: id,
    title: title,
    eventDate: date,
    venue: venue,
    guestCount: guests,
    status: status,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

Widget _buildApp(EventController controller, {ValueChanged<Event>? onTap}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: EventListScreen(controller: controller, onEventTap: onTap),
  );
}

void main() {
  group('EventListScreen', () {
    testWidgets('renders event information', (tester) async {
      final service = _FakeEventService(events: [_event()]);
      final controller = EventController(service);

      await tester.pumpWidget(_buildApp(controller));
      await tester.pumpAndSettle();

      expect(find.text('Wedding Reception'), findsOneWidget);
      expect(find.textContaining('Sadguru Function Hall'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('renders all event statuses', (tester) async {
      final service = _FakeEventService(
        events: [
          _event(id: 1, status: EventStatus.upcoming),
          _event(id: 2, title: 'Birthday Event', status: EventStatus.running),
          _event(
            id: 3,
            title: 'Corporate Event',
            status: EventStatus.completed,
          ),
        ],
      );
      final controller = EventController(service);

      await tester.pumpWidget(_buildApp(controller));
      await tester.pumpAndSettle();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      final service = _FakeEventService();
      final controller = EventController(service);

      await tester.pumpWidget(_buildApp(controller));
      await tester.pumpAndSettle();

      expect(find.text('No events available'), findsOneWidget);
    });

    testWidgets('renders loading state while request is pending', (
      tester,
    ) async {
      final service = _DelayedEventService();
      final controller = EventController(service);

      await tester.pumpWidget(_buildApp(controller));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('renders error state and retry action', (tester) async {
      final service = _RetryEventService();
      final controller = EventController(service);

      await tester.pumpWidget(_buildApp(controller));
      await tester.pumpAndSettle();

      expect(
        find.text('The server is temporarily unavailable. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Wedding Reception'), findsOneWidget);
      expect(service.getEventsCalls, 2);
    });

    testWidgets('calls event tap callback', (tester) async {
      Event? selectedEvent;

      final service = _FakeEventService(events: [_event()]);
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildApp(controller, onTap: (event) => selectedEvent = event),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wedding Reception'));
      await tester.pump();

      expect(selectedEvent?.id, 1);
    });

    testWidgets('pull to refresh reloads events', (tester) async {
      final service = _FakeEventService(events: [_event()]);
      final controller = EventController(service);

      await tester.pumpWidget(_buildApp(controller));
      await tester.pumpAndSettle();

      expect(service.getEventsCalls, 1);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(service.getEventsCalls, 2);
    });
  });
}

class _DelayedEventService implements EventServiceContract {
  final Completer<List<Event>> _completer = Completer<List<Event>>();

  void complete() {
    _completer.complete(const []);
  }

  @override
  Future<List<Event>> getEvents() => _completer.future;

  @override
  Future<Event> getEvent(int id) => throw UnimplementedError();

  @override
  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) => throw UnimplementedError();

  @override
  Future<Event> updateStatus(int id, EventStatus status) =>
      throw UnimplementedError();

  @override
  Future<void> deleteEvent(int id) => throw UnimplementedError();
}

class _RetryEventService implements EventServiceContract {
  int getEventsCalls = 0;

  @override
  Future<List<Event>> getEvents() async {
    getEventsCalls++;

    if (getEventsCalls == 1) {
      throw const ApiException(
        code: 'SERVER_ERROR',
        message: 'Temporary failure',
        statusCode: 500,
      );
    }

    return [_event()];
  }

  @override
  Future<Event> getEvent(int id) => throw UnimplementedError();

  @override
  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) => throw UnimplementedError();

  @override
  Future<Event> updateStatus(int id, EventStatus status) =>
      throw UnimplementedError();

  @override
  Future<void> deleteEvent(int id) => throw UnimplementedError();
}
