import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/widgets/primary_button.dart';

void main() {
  testWidgets('PrimaryButton calls onPressed', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Continue',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('PrimaryButton shows loading indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Continue',
            onPressed: null,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
