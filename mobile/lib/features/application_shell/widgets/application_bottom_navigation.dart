import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../models/application_tab.dart';

class ApplicationBottomNavigation extends StatelessWidget {
  const ApplicationBottomNavigation({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });

  final ApplicationTab currentTab;
  final ValueChanged<ApplicationTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) {
        onTabSelected(ApplicationTab.values[index]);
      },
      destinations: [
        NavigationDestination(
          icon: Icon(ApplicationTab.dashboard.icon),
          selectedIcon: Icon(ApplicationTab.dashboard.selectedIcon),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: Icon(ApplicationTab.events.icon),
          selectedIcon: Icon(ApplicationTab.events.selectedIcon),
          label: l10n.events,
        ),
        NavigationDestination(
          icon: Icon(ApplicationTab.finance.icon),
          selectedIcon: Icon(ApplicationTab.finance.selectedIcon),
          label: l10n.finance,
        ),
        NavigationDestination(
          icon: Icon(ApplicationTab.settings.icon),
          selectedIcon: Icon(ApplicationTab.settings.selectedIcon),
          label: l10n.settings,
        ),
      ],
    );
  }
}