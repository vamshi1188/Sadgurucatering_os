import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../localization/app_localizations.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class SadguruApp extends StatelessWidget {
  const SadguruApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sadguru Catering OS',
      debugShowCheckedModeBanner: false,
      theme: SadguruAppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: SadguruRoutes.home,
      routes: SadguruRoutes.routes,
    );
  }
}
