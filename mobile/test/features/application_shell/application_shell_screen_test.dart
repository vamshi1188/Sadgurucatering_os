import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/app/sadguru_app.dart';
import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/config/environment.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';

import '../../support/test_api_client.dart';
import '../../support/authentication_fixture.dart';

void main() {
  late AppConfig config;

  setUp(() {
    config = const AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://127.0.0.1:1/api/v1',
    );
  });

  testWidgets('starts on dashboard', (tester) async {
    final apiClient = createTestApiClient();

    await tester.pumpWidget(
      SadguruApp(
        config: config,
        apiClient: apiClient,
        initialAuthenticationState: authenticatedOwner,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('switches between application tabs', (tester) async {
    var financeRequests = 0;
    final apiClient = createTestApiClient(
      onRequest: (options) {
        if (options.path.endsWith('/finance/summary')) {
          financeRequests++;
        }
      },
    );

    await tester.pumpWidget(
      SadguruApp(
        config: config,
        apiClient: apiClient,
        initialAuthenticationState: authenticatedOwner,
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsWidgets);
    expect(find.text('Finance'), findsOneWidget);

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();

    expect(find.text('Finance'), findsWidgets);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Event-wise Breakdown'), findsOneWidget);
    expect(financeRequests, 1);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();
    expect(financeRequests, 2);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('User Management'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('User Management'));
    await tester.pumpAndSettle();
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Create user'), findsOneWidget);
    expect(find.text('No users available'), findsOneWidget);
  });

  testWidgets('opens event details when an event is tapped', (tester) async {
    final apiClient = createTestApiClient(includeTestEvent: true);

    await tester.pumpWidget(
      SadguruApp(
        config: config,
        apiClient: apiClient,
        initialAuthenticationState: authenticatedOwner,
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('Wedding Reception'), findsOneWidget);

    await tester.tap(find.text('Wedding Reception'));
    await tester.pumpAndSettle();

    expect(find.text('Event Workspace'), findsOneWidget);
    expect(find.text('Wedding Reception'), findsOneWidget);
    expect(find.text('Sadguru Function Hall'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('Event Information'), findsOneWidget);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Total Income'), findsOneWidget);
    expect(find.text('Add Income'), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    expect(find.text('Total Expenses'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });

  testWidgets('supervisors can view data without mutation controls', (
    tester,
  ) async {
    final apiClient = createTestApiClient(includeTestEvent: true);

    await tester.pumpWidget(
      SadguruApp(
        config: config,
        apiClient: apiClient,
        initialAuthenticationState: const AuthenticationState.authenticated(
          user: AuthenticatedUser(
            id: 2,
            username: 'supervisor',
            role: 'supervisor',
            mustChangePassword: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(find.text('Wedding Reception'), findsOneWidget);
    expect(find.text('Create Event'), findsNothing);

    await tester.tap(find.text('Wedding Reception'));
    await tester.pumpAndSettle();
    expect(find.text('Start Event'), findsNothing);
    expect(find.text('Delete Event'), findsNothing);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Add Income'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('User Management'), findsNothing);
  });
}
