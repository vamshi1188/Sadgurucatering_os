import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/app/sadguru_app.dart';
import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/config/environment.dart';
import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';

import '../support/test_api_client.dart';

void main() {
  testWidgets(
    'SadguruApp switches between English and Telugu',
    (tester) async {
      const config = AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'http://127.0.0.1:1/api/v1',
      );

      final apiClient = createTestApiClient();

      await tester.pumpWidget(
        SadguruApp(
          config: config,
          apiClient: apiClient,
          initialAuthenticationState:
              const AuthenticationState.authenticated(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sadguru Catering OS'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Finance'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);

      await tester.tap(find.text('తెలుగు'));
      await tester.pump();

      expect(find.text('సద్గురు క్యాటరింగ్ OS'), findsOneWidget);
      expect(find.text('డాష్‌బోర్డ్'), findsWidgets);
      expect(find.text('ఈవెంట్స్'), findsWidgets);
      expect(find.text('ఫైనాన్స్'), findsWidgets);
      expect(find.text('సెట్టింగ్స్'), findsWidgets);

      await tester.tap(find.text('English'));
      await tester.pump();

      expect(find.text('Sadguru Catering OS'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Finance'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    },
  );
}