import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/events/controllers/event_controller.dart';
import 'package:sadguru_catering/features/events/models/event.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';
import 'package:sadguru_catering/features/events/services/event_service_contract.dart';
import 'package:sadguru_catering/features/events/screens/event_details_screen.dart';
import 'package:sadguru_catering/features/expenses/controllers/expense_controller.dart';
import 'package:sadguru_catering/features/expenses/models/expense.dart';
import 'package:sadguru_catering/features/expenses/services/expense_service_contract.dart';
import 'package:sadguru_catering/features/income/controllers/income_controller.dart';
import 'package:sadguru_catering/features/income/models/income.dart';
import 'package:sadguru_catering/features/income/services/income_service_contract.dart';
import 'package:sadguru_catering/features/profitability/controllers/profitability_controller.dart';
import 'package:sadguru_catering/features/profitability/models/profitability.dart';
import 'package:sadguru_catering/features/profitability/services/profitability_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeIncomeServiceContract implements IncomeServiceContract {
  _FakeIncomeServiceContract({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Future<IncomeFinancials> getIncome(int eventId) async {
    return IncomeFinancials(
      eventId: eventId,
      totalIncome: '1000.00',
      income: [],
    );
  }

  @override
  Future<Income> createIncome({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    onCreate?.call();
    return Income(
      id: 11,
      eventId: eventId,
      description: description,
      amount: amount,
      createdAt: DateTime.utc(2026, 9, 3, 10),
    );
  }

  @override
  Future<void> deleteIncome({
    required int eventId,
    required int incomeId,
  }) async {}
}

class _FakeExpenseServiceContract implements ExpenseServiceContract {
  _FakeExpenseServiceContract({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Future<ExpenseFinancials> getExpenses(int eventId) async {
    return ExpenseFinancials(
      eventId: eventId,
      totalExpenses: '250.50',
      expenses: [],
    );
  }

  @override
  Future<Expense> createExpense({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    onCreate?.call();
    return Expense(
      id: 21,
      eventId: eventId,
      description: description,
      amount: amount,
      createdAt: DateTime.utc(2026, 9, 3, 10),
    );
  }

  @override
  Future<void> deleteExpense({
    required int eventId,
    required int expenseId,
  }) async {}
}

class _FakeProfitabilityServiceContract
    implements ProfitabilityServiceContract {
  Profitability profitability = const Profitability(
    eventId: 42,
    totalIncome: '1000.00',
    totalExpenses: '250.50',
    netProfit: '749.50',
  );
  int getCallCount = 0;
  int? lastRequestedEventId;

  @override
  Future<Profitability> getProfitability(int eventId) async {
    getCallCount++;
    lastRequestedEventId = eventId;
    return profitability;
  }
}

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
  IncomeController? incomeController,
  ExpenseController? expenseController,
  ProfitabilityController? profitabilityController,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: EventDetailsScreen(
      controller: controller,
      eventId: eventId,
      incomeController: incomeController,
      expenseController: expenseController,
      profitabilityController: profitabilityController,
    ),
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

    testWidgets('navigates workspace financial module slots', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      final profitabilityService = _FakeProfitabilityServiceContract();
      final incomeService = _FakeIncomeServiceContract(
        onCreate: () {
          profitabilityService.profitability = const Profitability(
            eventId: 42,
            totalIncome: '1200.00',
            totalExpenses: '250.50',
            netProfit: '949.50',
          );
        },
      );
      final incomeController = IncomeController(
        eventId: 42,
        service: incomeService,
      );

      final expenseService = _FakeExpenseServiceContract(
        onCreate: () {
          profitabilityService.profitability = const Profitability(
            eventId: 42,
            totalIncome: '1200.00',
            totalExpenses: '300.50',
            netProfit: '899.50',
          );
        },
      );
      final expenseController = ExpenseController(
        eventId: 42,
        service: expenseService,
      );

      final profitabilityController = ProfitabilityController(
        eventId: 42,
        service: profitabilityService,
      );

      await tester.pumpWidget(
        _buildTestApp(
          controller: controller,
          eventId: 42,
          incomeController: incomeController,
          expenseController: expenseController,
          profitabilityController: profitabilityController,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.text('Total Income'), findsOneWidget);
      expect(
        await incomeController.createIncome(
          description: 'Final payment',
          amount: '200.00',
        ),
        isTrue,
      );

      await tester.tap(find.text('Profitability'));
      await tester.pumpAndSettle();
      expect(find.text('₹ 949.50'), findsOneWidget);
      expect(profitabilityService.getCallCount, 1);
      expect(profitabilityService.lastRequestedEventId, 42);

      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(
        await expenseController.createExpense(
          description: 'Extra supplies',
          amount: '50.00',
        ),
        isTrue,
      );

      await tester.tap(find.text('Profitability'));
      await tester.pumpAndSettle();

      expect(find.text('Net Profit'), findsOneWidget);
      expect(find.text('₹ 899.50'), findsOneWidget);
      expect(profitabilityService.getCallCount, 2);
      expect(profitabilityService.lastRequestedEventId, 42);
    });

    testWidgets('workspace module labels support Telugu', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(
          controller: controller,
          eventId: 42,
          locale: const Locale('te'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('అవలోకనం'), findsOneWidget);
      expect(find.text('ఆదాయం'), findsOneWidget);
      expect(find.text('ఖర్చులు'), findsOneWidget);
      expect(find.text('లాభదాయకత'), findsOneWidget);
    });

    testWidgets('cancelling delete keeps the event', (tester) async {
      final service = _FakeEventService(_testEvent());
      final controller = EventController(service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, eventId: 42),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Delete Event'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete Event'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to delete this event?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.deleteEventCallCount, 0);
      await tester.scrollUntilVisible(
        find.text('Wedding Reception'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
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

      await tester.scrollUntilVisible(
        find.text('Delete Event'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
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

      await tester.scrollUntilVisible(
        find.text('Delete Event'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete Event'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(service.deleteEventCallCount, 1);
      await tester.scrollUntilVisible(
        find.text('Wedding Reception'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
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
