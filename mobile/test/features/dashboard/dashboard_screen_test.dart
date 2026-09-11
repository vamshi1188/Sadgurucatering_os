import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/widgets/empty_view.dart';
import 'package:sadguru_catering/features/dashboard/controllers/dashboard_controller.dart';
import 'package:sadguru_catering/features/dashboard/screens/dashboard_screen.dart';
import 'package:sadguru_catering/features/dashboard/services/dashboard_service.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

import '../../support/test_api_client.dart';

void main() {
  testWidgets('renders the dashboard empty state in English', (tester) async {
    final controller = DashboardController(
      DashboardService(createTestApiClient()),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Events'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.byType(EmptyView), findsOneWidget);
    controller.dispose();
  });

  testWidgets('renders dashboard labels in Telugu', (tester) async {
    final controller = DashboardController(
      DashboardService(createTestApiClient()),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('te'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('మొత్తం ఈవెంట్లు'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.byType(EmptyView), findsOneWidget);
    controller.dispose();
  });
}
