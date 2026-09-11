import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/core/widgets/app_card.dart';

void main() {
  testWidgets('AppCard renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppCard(child: Text('Test content'))),
      ),
    );

    expect(find.text('Test content'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });
}
