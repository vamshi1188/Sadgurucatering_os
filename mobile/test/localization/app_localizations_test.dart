import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/localization/app_localizations.dart';

void main() {
  testWidgets('English localization contains expected foundation strings', (
    tester,
  ) async {
    late AppLocalizations localization;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            localization = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(localization.appName, 'Sadguru Catering OS');
    expect(localization.welcome, 'Welcome');
    expect(localization.language, 'Language');
    expect(localization.retry, 'Retry');
  });

  testWidgets('Telugu localization contains expected foundation strings', (
    tester,
  ) async {
    late AppLocalizations localization;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('te'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            localization = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(localization.appName, 'సద్గురు క్యాటరింగ్ OS');
    expect(localization.welcome, 'స్వాగతం');
    expect(localization.language, 'భాష');
    expect(localization.retry, 'మళ్లీ ప్రయత్నించండి');
  });
}
