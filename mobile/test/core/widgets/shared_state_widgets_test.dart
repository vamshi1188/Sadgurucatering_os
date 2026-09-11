import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/widgets/empty_view.dart';
import 'package:sadguru_catering/core/widgets/error_view.dart';
import 'package:sadguru_catering/core/widgets/loading_view.dart';

void main() {
  testWidgets('LoadingView displays loading indicator and message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoadingView(message: 'Loading')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('ErrorView displays error message and retry action', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Something went wrong',
            retryLabel: 'Retry',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('EmptyView displays empty-state message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptyView(message: 'No data available')),
      ),
    );

    expect(find.text('No data available'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
