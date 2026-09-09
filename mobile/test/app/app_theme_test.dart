import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/app/app_theme.dart';

void main() {
  test('Sadguru light theme uses the configured primary color', () {
    final theme = SadguruAppTheme.light();

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, SadguruAppTheme.primaryColor);
    expect(theme.useMaterial3, isTrue);
  });
}
