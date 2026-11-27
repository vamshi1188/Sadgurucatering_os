import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/application_shell/screens/settings_screen.dart';
import 'package:sadguru_catering/features/application_shell/services/settings_services.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

void main() {
  testWidgets('shows app name and dynamically loaded version and build', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsApp(
        appInfoProvider: _FakeAppInfoProvider(
          const AppVersionInfo(version: '2.4.1', buildNumber: '88'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sadguru Catering OS'), findsWidgets);
    expect(find.text('Version 2.4.1 (Build 88)'), findsOneWidget);
  });

  testWidgets('uses Share App action to share installed package', (
    tester,
  ) async {
    final shareService = _FakeAppSharingService();
    await tester.pumpWidget(_settingsApp(appSharingService: shareService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share App'));
    await tester.pumpAndSettle();

    expect(shareService.shareCount, 1);
  });

  testWidgets('shows localized error when sharing is unavailable', (
    tester,
  ) async {
    final shareService = _FakeAppSharingService(
      error: const ShareAppUnavailableException(),
    );
    await tester.pumpWidget(_settingsApp(appSharingService: shareService));

    await tester.tap(find.text('Share App'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The app package is unavailable and no distribution link is configured.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('updates application locale from preferences', (tester) async {
    Locale? selectedLocale;
    await tester.pumpWidget(
      _settingsApp(onLocaleChanged: (locale) => selectedLocale = locale),
    );

    await tester.tap(find.text('Telugu'));
    await tester.pumpAndSettle();

    expect(selectedLocale, const Locale('te'));
  });

  testWidgets('opens the configured support address in email app', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      _settingsApp(
        openSupportEmail: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );

    await tester.tap(find.text('Contact Support'));
    await tester.pumpAndSettle();

    expect(openedUri?.scheme, 'mailto');
    expect(openedUri?.path, 'saivamshik11@gmail.com');
    expect(
      openedUri?.queryParameters['subject'],
      'Sadguru Catering OS support',
    );
  });

  testWidgets('opens the about dialog', (tester) async {
    await tester.pumpWidget(_settingsApp());

    await tester.tap(find.text('About Sadguru Catering OS'));
    await tester.pumpAndSettle();

    expect(find.text('About Sadguru Catering OS'), findsWidgets);
    expect(
      find.text(
        'Sadguru Catering OS helps manage catering events, finances, and business operations.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders Telugu settings labels', (tester) async {
    await tester.pumpWidget(_settingsApp(locale: const Locale('te')));

    expect(find.text('అప్లికేషన్'), findsOneWidget);
    expect(find.text('యాప్‌ను షేర్ చేయండి'), findsOneWidget);
    expect(find.text('సహాయాన్ని సంప్రదించండి'), findsOneWidget);
  });
}

Widget _settingsApp({
  Locale locale = const Locale('en'),
  AppInfoProvider appInfoProvider = const _DefaultAppInfoProvider(),
  AppSharingService? appSharingService,
  ValueChanged<Locale>? onLocaleChanged,
  Future<bool> Function(Uri)? openSupportEmail,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SettingsScreen(
      onLocaleChanged: onLocaleChanged ?? (_) {},
      appInfoProvider: appInfoProvider,
      appSharingService: appSharingService,
      openSupportEmail: openSupportEmail ?? (_) async => true,
    ),
  ),
);

class _DefaultAppInfoProvider implements AppInfoProvider {
  const _DefaultAppInfoProvider();

  @override
  Future<AppVersionInfo> getAppInfo() async =>
      const AppVersionInfo(version: '1.0.0', buildNumber: '1');
}

class _FakeAppInfoProvider implements AppInfoProvider {
  const _FakeAppInfoProvider(this.info);

  final AppVersionInfo info;

  @override
  Future<AppVersionInfo> getAppInfo() async => info;
}

class _FakeAppSharingService extends AppSharingService {
  _FakeAppSharingService({this.error});

  final Object? error;
  int shareCount = 0;

  @override
  Future<void> shareApp() async {
    shareCount++;
    if (error != null) {
      throw error!;
    }
  }
}
