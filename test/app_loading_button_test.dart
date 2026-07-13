import 'package:chatbot/component/app_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppLoadingButton disables presses and shows loading label', (
    tester,
  ) async {
    var pressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppLoadingButton(
            label: 'Drop MK',
            loadingLabel: 'Memproses...',
            isLoading: true,
            onPressed: () => pressCount++,
          ),
        ),
      ),
    );

    expect(find.text('Memproses...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(AppLoadingButton));

    expect(pressCount, 0);
  });
}
