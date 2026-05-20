import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'NotificationBadge shows count only when count is more than one',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NotificationBadge(count: 1, child: Icon(Icons.notifications)),
                NotificationBadge(count: 2, child: Icon(Icons.notifications)),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
    },
  );
}
