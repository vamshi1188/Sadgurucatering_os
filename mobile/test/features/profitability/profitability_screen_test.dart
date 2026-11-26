import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/profitability/controllers/profitability_controller.dart';
import 'package:sadguru_catering/features/profitability/models/profitability.dart';
import 'package:sadguru_catering/features/profitability/screens/profitability_screen.dart';
import 'package:sadguru_catering/features/profitability/services/profitability_service_contract.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

class _FakeProfitabilityService implements ProfitabilityServiceContract {
  _FakeProfitabilityService(this.profitability);

  Profitability profitability;
  ApiException? error;
  int getProfitabilityCallCount = 0;
  Completer<Profitability>? completer;

  @override
  Future<Profitability> getProfitability(int eventId) async {
    getProfitabilityCallCount++;

    final comp = completer;
    if (comp != null) {
      return comp.future;
    }

    if (error != null) {
      throw error!;
    }

    return profitability;
  }
}

Widget _buildTestApp({
  required ProfitabilityController controller,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: ProfitabilityScreen(controller: controller)),
  );
}

void main() {
  const sampleProfitability = Profitability(
    eventId: 42,
    totalIncome: '1000.00',
    totalExpenses: '250.50',
    netProfit: '749.50',
  );
  const negativeProfitability = Profitability(
    eventId: 42,
    totalIncome: '500.00',
    totalExpenses: '1250.75',
    netProfit: '-750.75',
  );
  const zeroProfitability = Profitability(
    eventId: 42,
    totalIncome: '0.00',
    totalExpenses: '0.00',
    netProfit: '0.00',
  );

  group('ProfitabilityScreen', () {
    testWidgets('displays loading view while fetching profitability', (
      tester,
    ) async {
      final service = _FakeProfitabilityService(sampleProfitability);
      service.completer = Completer<Profitability>();

      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);

      service.completer!.complete(sampleProfitability);
      await tester.pumpAndSettle();

      expect(find.text('Total Income'), findsOneWidget);
    });

    testWidgets('displays error view on failure and allows retry', (
      tester,
    ) async {
      final service = _FakeProfitabilityService(sampleProfitability);
      service.error = const ApiException(
        message: 'Unable to connect to the server',
      );

      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "We couldn't connect to the server. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      service.error = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('₹ 1000.00'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('₹ 250.50'), findsOneWidget);
      expect(find.text('Net Profit'), findsOneWidget);
      expect(find.text('₹ 749.50'), findsOneWidget);
    });

    testWidgets(
      'displays populated financial profitability content in English',
      (tester) async {
        final service = _FakeProfitabilityService(sampleProfitability);
        final controller = ProfitabilityController(
          eventId: 42,
          service: service,
        );

        await tester.pumpWidget(_buildTestApp(controller: controller));
        await tester.pumpAndSettle();

        expect(find.text('Total Income'), findsOneWidget);
        expect(find.text('₹ 1000.00'), findsOneWidget);
        expect(find.text('Total Expenses'), findsOneWidget);
        expect(find.text('₹ 250.50'), findsOneWidget);
        expect(find.text('Net Profit'), findsOneWidget);
        expect(find.text('₹ 749.50'), findsOneWidget);
      },
    );

    testWidgets('displays profitability content in Telugu', (tester) async {
      final service = _FakeProfitabilityService(sampleProfitability);
      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(
        _buildTestApp(controller: controller, locale: const Locale('te')),
      );
      await tester.pumpAndSettle();

      expect(find.text('మొత్తం ఆదాయం'), findsOneWidget);
      expect(find.text('₹ 1000.00'), findsOneWidget);
      expect(find.text('మొత్తం ఖర్చులు'), findsOneWidget);
      expect(find.text('₹ 250.50'), findsOneWidget);
      expect(find.text('నికర లాభం'), findsOneWidget);
      expect(find.text('₹ 749.50'), findsOneWidget);
    });

    testWidgets('presents negative profit using the error color', (
      tester,
    ) async {
      final service = _FakeProfitabilityService(negativeProfitability);
      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      final profitText = tester.widget<Text>(find.text('₹ -750.75'));
      expect(profitText.style?.color, ThemeData().colorScheme.error);
    });

    testWidgets('presents zero profit without changing its value', (
      tester,
    ) async {
      final service = _FakeProfitabilityService(zeroProfitability);
      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('₹ 0.00'), findsNWidgets(3));
    });

    testWidgets('hides retry for non-retryable errors', (tester) async {
      final service = _FakeProfitabilityService(sampleProfitability)
        ..error = const ApiException(
          code: 'NOT_FOUND',
          message: 'Event not found',
          statusCode: 404,
        );
      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(
        find.text('The requested resource was not found.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows retry for retryable server errors', (tester) async {
      final service = _FakeProfitabilityService(sampleProfitability)
        ..error = const ApiException(
          code: 'INTERNAL_ERROR',
          message: 'Unable to retrieve event financials',
          statusCode: 500,
        );
      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('pull-to-refresh shows the latest backend values', (
      tester,
    ) async {
      final service = _FakeProfitabilityService(sampleProfitability);
      final controller = ProfitabilityController(eventId: 42, service: service);

      await tester.pumpWidget(_buildTestApp(controller: controller));
      await tester.pumpAndSettle();
      expect(service.getProfitabilityCallCount, 1);

      service.profitability = const Profitability(
        eventId: 42,
        totalIncome: '1200.00',
        totalExpenses: '300.00',
        netProfit: '900.00',
      );
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(service.getProfitabilityCallCount, 2);
      expect(find.text('₹ 900.00'), findsOneWidget);
    });
  });
}
