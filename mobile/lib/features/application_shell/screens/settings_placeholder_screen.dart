import 'package:flutter/material.dart';

import '../../../core/widgets/empty_view.dart';
import '../../../localization/app_localizations.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _PlaceholderContent(
      title: l10n.settings,
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EmptyView(
      message: '$title\n${l10n.noData}',
    );
  }
}