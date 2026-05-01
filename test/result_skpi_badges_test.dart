import 'package:chatbot/result_skpi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('summary badges fit three-digit counts on narrow width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: SkpiSummaryBadges(
              organizationCount: 128,
              languageCount: 12,
              softskillCount: 144,
              honorCount: 32,
              textColor: Colors.white,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('128'), findsOneWidget);
    expect(find.text('144'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
