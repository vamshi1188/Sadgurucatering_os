import 'package:flutter/material.dart';

enum ApplicationTab {
  dashboard,
  events,
  finance,
  settings,
}

extension ApplicationTabDetails on ApplicationTab {
  IconData get icon {
    switch (this) {
      case ApplicationTab.dashboard:
        return Icons.dashboard_outlined;
      case ApplicationTab.events:
        return Icons.event_outlined;
      case ApplicationTab.finance:
        return Icons.account_balance_wallet_outlined;
      case ApplicationTab.settings:
        return Icons.settings_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case ApplicationTab.dashboard:
        return Icons.dashboard;
      case ApplicationTab.events:
        return Icons.event;
      case ApplicationTab.finance:
        return Icons.account_balance_wallet;
      case ApplicationTab.settings:
        return Icons.settings;
    }
  }
}