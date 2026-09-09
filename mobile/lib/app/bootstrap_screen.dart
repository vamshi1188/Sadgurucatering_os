import 'package:flutter/material.dart';

import '../features/authentication/controllers/authentication_controller.dart';
import '../localization/app_localizations.dart';

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({
    super.key,
    required this.onLocaleChanged,
    required this.authenticationController,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final AuthenticationController authenticationController;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.appName),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: authenticationController.isLoading
                ? null
                : () async {
                    await authenticationController.logout();
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localization.welcome,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text(
                localization.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'en',
                    label: Text('English'),
                  ),
                  ButtonSegment<String>(
                    value: 'te',
                    label: Text('తెలుగు'),
                  ),
                ],
                selected: {
                  Localizations.localeOf(context).languageCode,
                },
                onSelectionChanged: (selection) {
                  onLocaleChanged(
                    Locale(selection.first),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}