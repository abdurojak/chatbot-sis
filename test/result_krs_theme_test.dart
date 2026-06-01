import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/result_krs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HasilKrsPage empty state uses dark theme colors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(const MaterialApp(home: HasilKrsPage()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final emptyText = tester.widget<Text>(find.text('Tidak ada data KRS'));

    expect(scaffold.backgroundColor, AppThemePalette.background);
    expect(emptyText.style?.color, AppThemePalette.textSecondary);
  });
}
