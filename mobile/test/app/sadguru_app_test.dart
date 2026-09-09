import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/app/sadguru_app.dart';
import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/core/network/api_client.dart';
import 'package:sadguru_catering/config/environment.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';

void main() {
  testWidgets(
    'SadguruApp switches between English and Telugu',
    (tester) async {
      const config = AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'http://localhost:3000/api/v1',
      );

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

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      await tester.tap(find.text('తెలుగు'));
      await tester.pump();

      expect(find.text('స్వాగతం'), findsOneWidget);
      expect(find.text('భాష'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    },
  );
}