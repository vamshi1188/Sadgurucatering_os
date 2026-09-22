import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/events/controllers/event_controller.dart';
import 'package:sadguru_catering/features/events/models/event.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';
import 'package:sadguru_catering/features/events/services/event_service_contract.dart';
import 'package:sadguru_catering/features/events/screens/event_details_screen.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeEventService implements EventServiceContract {
  _FakeEventService(this.event);

  Event? event;
  ApiException? error;
  int getEventCallCount = 0;
  int updateStatusCallCount = 0;
  int? lastUpdatedEventId;
  EventStatus? lastUpdatedStatus;
  Completer<Event>? updateStatusCompleter;
  int deleteEventCallCount = 0;
  int? lastDeletedEventId;

  @override
  Future<List<Event>> getEvents() async => event == null ? [] : [event!];

  @override
  Future<Event> getEvent(int id) async {
    getEventCallCount++;

    if (error != null) {
      throw error!;
    }

    if (event == null || event!.id != id) {
      throw Exception('Event not found');
    }

    return event!;
  }

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
  Future<Event> updateStatus(int id, EventStatus status) async {
    updateStatusCallCount++;
    lastUpdatedEventId = id;
    lastUpdatedStatus = status;

    final completer = updateStatusCompleter;
    if (completer != null) {
      return completer.future;
    }

    event = event!.copyWith(status: status);
    return event!;
  }

  @override
  Future<void> deleteEvent(int id) async {
    deleteEventCallCount++;
    lastDeletedEventId = id;

    if (error != null) {
      throw error!;
    }

    event = null;
  }
}

Event _testEvent({EventStatus status = EventStatus.upcoming}) {
  return Event(
    id: 42,
    title: 'Wedding Reception',
    eventDate: '2026-09-15',
    venue: 'Sadguru Function Hall',
    guestCount: 500,
    status: status,
    createdAt: DateTime(2026, 9, 1, 10, 30),
    updatedAt: DateTime(2026, 9, 2, 14, 45),
  );
}

Widget _buildTestApp({
  required EventController controller,
  required int eventId,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: EventDetailsScreen(controller: controller, eventId: eventId),
  );
}

void main() {
  group('EventDetailsScreen', () {
    testWidgets('loads and displays event details', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Wedding Reception'), findsOneWidget);
      expect(find.text('Sadguru Function Hall'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Event Information'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Event Record'), findsOneWidget);
      expect(find.text('Event ID'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(service.getEventCallCount, 1);
    });

    testWidgets('displays running status', (tester) async {
      final service = _FakeEventService(
        _testEvent(status: EventStatus.running),
      );
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('displays completed status', (tester) async {
      final service = _FakeEventService(
        _testEvent(status: EventStatus.completed),
      );
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('starts an upcoming event', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start Event'), findsOneWidget);

      await tester.tap(find.text('Start Event'));
      await tester.pumpAndSettle();

      expect(service.updateStatusCallCount, 1);
      expect(service.lastUpdatedEventId, 42);
      expect(service.lastUpdatedStatus, EventStatus.running);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Complete Event'), findsOneWidget);
      expect(find.text('Start Event'), findsNothing);
    });

    testWidgets('completes a running event', (tester) async {
      final service = _FakeEventService(
        _testEvent(status: EventStatus.running),
      );
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Complete Event'), findsOneWidget);

      await tester.tap(find.text('Complete Event'));
      await tester.pumpAndSettle();

      expect(service.updateStatusCallCount, 1);
      expect(service.lastUpdatedEventId, 42);
      expect(service.lastUpdatedStatus, EventStatus.completed);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Complete Event'), findsNothing);
    });

    testWidgets('does not show a status action for a completed event', (
      tester,
    ) async {
      final service = _FakeEventService(
        _testEvent(status: EventStatus.completed),
      );
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start Event'), findsNothing);
      expect(find.text('Complete Event'), findsNothing);
    });

    testWidgets('cancelling delete keeps the event', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Event'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to delete this event?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.deleteEventCallCount, 0);
      expect(find.text('Wedding Reception'), findsOneWidget);
    });

    testWidgets('confirming delete removes the event and closes details', (
      tester,
    ) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Event'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(service.deleteEventCallCount, 1);
      expect(service.lastDeletedEventId, 42);
      expect(find.text('Wedding Reception'), findsNothing);
    });

    testWidgets('delete failure keeps the event', (tester) async {
      final service = _FakeEventService(_testEvent());

      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      service.error = const ApiException(message: 'Unable to delete event');

      await tester.tap(find.text('Delete Event'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(service.deleteEventCallCount, 1);
      expect(find.text('Wedding Reception'), findsOneWidget);
      expect(find.text('Unable to delete event.'), findsOneWidget);
    });

    testWidgets('shows loading state while event is loading', (tester) async {
      final service = _SlowEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      // EventDetailsScreen starts loading after its first frame.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.complete();

      await tester.pumpAndSettle();

      expect(find.text('Wedding Reception'), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      final service = _FakeEventService(_testEvent());
      service.error = const ApiException(
        message: 'Unable to connect to the server',
      );

      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          "We couldn't connect to the server. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry reloads the event', (tester) async {
      final service = _FakeEventService(_testEvent());
      service.error = const ApiException(
        message: 'Unable to connect to the server',
      );

      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      service.error = null;

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Wedding Reception'), findsOneWidget);
      expect(service.getEventCallCount, 2);
    });

    testWidgets('supports pull to refresh', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      expect(service.getEventCallCount, 1);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(service.getEventCallCount, 2);
    });
  });
}

class _SlowEventService implements EventServiceContract {
  _SlowEventService(this.event);

  final Event event;
  final completer = Completer<Event>();

  @override
  Future<List<Event>> getEvents() async => [event];

  @override
  Future<Event> getEvent(int id) => completer.future;

  void complete() {
    completer.complete(event);
  }

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
