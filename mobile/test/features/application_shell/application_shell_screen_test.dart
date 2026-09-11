import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/app/sadguru_app.dart';
import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/config/environment.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';

void main() {
  late AppConfig config;

  setUp(() {
    config = const AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://localhost:3000/api/v1',
    );
  });

  testWidgets(
    'starts on dashboard',
    (tester) async {
      final apiClient = ApiClient(
        baseUrl: config.apiBaseUrl,
        dio: Dio(),
      );

      await tester.pumpWidget(
        SadguruApp(
          config: config,
          apiClient: apiClient,
          initialAuthenticationState:
              const AuthenticationState.authenticated(),
        ),
      );

      await tester.pump();

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'switches between application tabs',
    (tester) async {
      final apiClient = ApiClient(
        baseUrl: config.apiBaseUrl,
        dio: Dio(),
      );

      await tester.pumpWidget(
        SadguruApp(
          config: config,
          apiClient: apiClient,
          initialAuthenticationState:
              const AuthenticationState.authenticated(),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Events'));
      await tester.pump();

      expect(find.text('Events'), findsWidgets);
      expect(find.text('Finance'), findsOneWidget);

      await tester.tap(find.text('Finance'));
      await tester.pump();

      expect(find.text('Finance'), findsWidgets);
      expect(find.text('Events'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Finance'), findsOneWidget);
    },
  );
}