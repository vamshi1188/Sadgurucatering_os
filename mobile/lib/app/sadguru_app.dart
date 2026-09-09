import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../localization/app_localizations.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class SadguruApp extends StatefulWidget {
  const SadguruApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<SadguruApp> createState() => _SadguruAppState();
}

class _SadguruAppState extends State<SadguruApp> {
  Locale _locale = const Locale('en');

  void _changeLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }

    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sadguru Catering OS',
      debugShowCheckedModeBanner: false,
      theme: SadguruAppTheme.light(),
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: SadguruRoutes.home,
      routes: SadguruRoutes.routes(
        onLocaleChanged: _changeLocale,
      ),
    );
  }
}