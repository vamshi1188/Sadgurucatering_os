import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      headlineSmall: base.headlineSmall,
      titleLarge: base.titleLarge,
      titleMedium: base.titleMedium,
      bodyLarge: base.bodyLarge,
      bodyMedium: base.bodyMedium,
      bodySmall: base.bodySmall,
      labelLarge: base.labelLarge,
      labelMedium: base.labelMedium,
    );
  }
}