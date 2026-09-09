import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/app/app_theme.dart';
import 'package:sadguru_catering/core/design/app_colors.dart';
import 'package:sadguru_catering/core/design/app_dimensions.dart';
import 'package:sadguru_catering/core/design/app_radii.dart';

void main() {
  test('Sadguru light theme uses the configured design system', () {
    final theme = SadguruAppTheme.light();

    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.secondary);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.colorScheme.error, AppColors.error);

    expect(theme.scaffoldBackgroundColor, AppColors.background);

    expect(
      theme.cardTheme.shape,
      isA<RoundedRectangleBorder>(),
    );

    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;

    expect(
      cardShape.borderRadius,
      BorderRadius.circular(AppRadii.medium),
    );

    expect(
      theme.elevatedButtonTheme.style?.minimumSize?.resolve({}),
      const Size(0, AppDimensions.buttonHeight),
    );

    expect(
      theme.outlinedButtonTheme.style?.minimumSize?.resolve({}),
      const Size(0, AppDimensions.buttonHeight),
    );
  });
}