import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/features/events/controllers/event_controller.dart';
import 'package:sadguru_catering/features/events/models/event.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';
import 'package:sadguru_catering/features/events/screens/create_event_screen.dart';
import 'package:sadguru_catering/features/events/services/event_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeEventService implements EventServiceContract {
  Event? createdEvent;
  int createCallCount = 0;

  @override
  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) async {
    createCallCount++;

    final event = Event(
      id: 101,
      title: title,
      eventDate: eventDate,
      venue: venue,
      guestCount: guestCount,
      status: EventStatus.upcoming,
      createdAt: DateTime.parse('2026-09-11T10:00:00Z'),
      updatedAt: DateTime.parse('2026-09-11T10:00:00Z'),
    );

    createdEvent = event;
    return event;
  }

  @override
  Future<List<Event>> getEvents() async => const [];

  @override
  Future<Event> getEvent(int id) async => throw UnimplementedError();

  @override
  Future<Event> updateStatus(int id, EventStatus status) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteEvent(int id) async => throw UnimplementedError();
}

Widget _buildTestApp({
  required EventController controller,
  required ValueChanged<Event>? onCreated,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CreateEventScreen(controller: controller, onCreated: onCreated),
  );
}

void main() {
  group('CreateEventScreen', () {
    testWidgets('shows all event fields', (tester) async {
      final service = _FakeEventService();
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, onCreated: (_) {}),
      );

      expect(find.text('Create Event'), findsWidgets);
      expect(find.text('Event Title'), findsOneWidget);
      expect(find.text('Event Date'), findsOneWidget);
      expect(find.text('Venue'), findsOneWidget);
      expect(find.text('Guests'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('rejects empty required fields', (tester) async {
      final service = _FakeEventService();
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, onCreated: (_) {}),
      );

      await tester.tap(find.text('Create Event').last);
      await tester.pump();

      expect(find.text('Enter event title'), findsOneWidget);
      expect(service.createCallCount, 0);
    });

    testWidgets('rejects negative guest count', (tester) async {
      final service = _FakeEventService();
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, onCreated: (_) {}),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Title'),
        'Wedding Reception',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Venue'),
        'Sadguru Function Hall',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Guests'),
        '-1',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('event-date-field')),
      );
      await tester.tap(find.byKey(const ValueKey('event-date-field')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final createButton = find.byType(ElevatedButton);
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid guest count.'), findsOneWidget);
      expect(service.createCallCount, 0);
    });

    testWidgets('rejects missing event date', (tester) async {
      final service = _FakeEventService();
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, onCreated: (_) {}),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Title'),
        'Wedding Reception',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Venue'),
        'Sadguru Function Hall',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Guests'),
        '500',
      );

      await tester.tap(find.text('Create Event').last);
      await tester.pump();

      expect(find.text('Select event date'), findsAtLeastNWidgets(1));
      expect(service.createCallCount, 0);
    });

    testWidgets('creates event with entered values', (tester) async {
      final service = _FakeEventService();
      final controller = EventController(service);

      var created = false;

      await tester.pumpWidget(
        _buildTestApp(controller: controller, onCreated: (_) => created = true),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Title'),
        'Wedding Reception',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Venue'),
        'Sadguru Function Hall',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Guests'),
        '500',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('event-date-field')),
      );
      await tester.tap(find.byKey(const ValueKey('event-date-field')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final createButton = find.byType(ElevatedButton);
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(service.createCallCount, 1);
      expect(service.createdEvent?.title, 'Wedding Reception');
      expect(service.createdEvent?.venue, 'Sadguru Function Hall');
      expect(service.createdEvent?.guestCount, 500);
      expect(service.createdEvent?.eventDate, isNotEmpty);
      expect(created, isTrue);
      expect(controller.selectedEvent?.id, 101);
    });
  });
}
