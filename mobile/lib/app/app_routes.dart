import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class SadguruRoutes {
  SadguruRoutes._();

  static const String home = '/';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const _BootstrapHomeScreen(),
  };
}

class _BootstrapHomeScreen extends StatelessWidget {
  const _BootstrapHomeScreen();

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localization.appName)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localization.welcome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(localization.language),
            const SizedBox(height: 8),
            Text(localization.english),
            Text(localization.telugu),
          ],
        ),
      ),
    );
  }
}
