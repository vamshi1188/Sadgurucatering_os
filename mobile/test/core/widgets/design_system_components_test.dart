import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/widgets/app_card.dart';
import 'package:sadguru_catering/core/widgets/app_text_field.dart';
import 'package:sadguru_catering/core/widgets/primary_button.dart';
import 'package:sadguru_catering/core/widgets/secondary_button.dart';

void main() {
  testWidgets('PrimaryButton displays label and responds to tap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Save',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton shows loading indicator and disables action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Save',
            isLoading: true,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(tapped, isFalse);
  });

  testWidgets('PrimaryButton displays icon when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Save',
            icon: Icons.save,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('SecondaryButton displays label and responds to tap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecondaryButton(
            label: 'Cancel',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('SecondaryButton displays icon when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecondaryButton(
            label: 'Back',
            icon: Icons.arrow_back,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('AppCard displays its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(
            child: Text('Card content'),
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Card content'), findsOneWidget);
  });

  testWidgets('AppTextField displays label and accepts input', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Password',
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'test-password');

    expect(controller.text, 'test-password');

    controller.dispose();
  });

  testWidgets('AppTextField supports hint text', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            hint: 'Enter password',
          ),
        ),
      ),
    );

    expect(find.text('Enter password'), findsOneWidget);

    controller.dispose();
  });
}