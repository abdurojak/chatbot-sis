import 'package:chatbot/user_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatDebugIds displays IdSender and IdReceiver', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatDebugIds(idSender: '214908', idReceiver: '3'),
        ),
      ),
    );

    expect(find.text('IdSender: 214908 | IdReceiver: 3'), findsOneWidget);
  });
}
