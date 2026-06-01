import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/fill_krs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PengisianKrsPage info panel uses dark theme colors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: PengisianKrsPage(idSemester: '773')),
    );
    await tester.pumpAndSettle();

    final panel = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Semester to Register'),
            matching: find.byType(Container),
          )
          .first,
    );
    final panelDecoration = panel.decoration! as BoxDecoration;

    final valueChip = tester.widget<Container>(
      find.ancestor(of: find.text('-'), matching: find.byType(Container)).first,
    );
    final valueChipDecoration = valueChip.decoration! as BoxDecoration;

    final label = tester.widget<Text>(find.text('Semester to Register'));

    expect(panelDecoration.color, AppThemePalette.surface);
    expect(valueChipDecoration.color, AppThemePalette.accentAvatar);
    expect(label.style?.color, AppThemePalette.textPrimary);
  });
}
