import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home chat card icon avatars use app background in dark mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatPage())),
    );

    final avatar = tester.widget<CircleAvatar>(
      find
          .ancestor(
            of: find.byIcon(Icons.account_balance),
            matching: find.byType(CircleAvatar),
          )
          .first,
    );

    expect(avatar.backgroundColor, AppThemePalette.background);
  });
}
