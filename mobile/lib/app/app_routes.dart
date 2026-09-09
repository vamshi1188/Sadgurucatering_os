import 'package:flutter/material.dart';

import 'bootstrap_screen.dart';

class SadguruRoutes {
  SadguruRoutes._();

  static const String home = '/';

  static Map<String, WidgetBuilder> routes({
    required ValueChanged<Locale> onLocaleChanged,
  }) {
    return {
      home: (context) => BootstrapScreen(
        onLocaleChanged: onLocaleChanged,
      ),
    };
  }
}
