import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/config/environment.dart';

import 'package:sadguru_catering/app/sadguru_app.dart';
import 'package:sadguru_catering/config/app_config.dart';

void main() {
  testWidgets('language selector switches between English and Telugu', (
    tester,
  ) async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://localhost:3000/api/v1',
    );

    await tester.pumpWidget(
      const SadguruApp(config: config),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('తెలుగు'));
    await tester.pumpAndSettle();

    expect(find.text('స్వాగతం'), findsOneWidget);
    expect(find.text('భాష'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}
