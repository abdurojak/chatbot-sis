import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ProfilePage cards rebuild when dark mode changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token',
      'idLogin': '205040',
      'userid': '205040',
      'nim': '205040',
      'active': '1',
    });
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
    );
    await tester.pumpAndSettle();

    final lightColor = _developmentCardColor(tester);

    await AppThemeController.instance.updateDarkMode(true);
    await tester.pump();

    expect(_developmentCardColor(tester), isNot(lightColor));
    expect(_developmentCardColor(tester), AppThemePalette.surface);
  });
}

Color? _developmentCardColor(WidgetTester tester) {
  final cardFinder = find.ancestor(
    of: find.text('Development Mode'),
    matching: find.byType(Container),
  );
  final container = tester.widgetList<Container>(cardFinder).firstWhere((
    container,
  ) {
    final decoration = container.decoration;
    return decoration is BoxDecoration && decoration.color != null;
  });

  final decoration = container.decoration! as BoxDecoration;
  return decoration.color;
}
