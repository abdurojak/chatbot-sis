import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/submit_krs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SubmitKrsScreen summary panel uses dark theme colors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: SubmitKrsScreen(idSemester: '773')),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final panel = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Semester to Register'),
            matching: find.byType(Container),
          )
          .last,
    );
    final valueChip = tester.widget<Container>(
      find.ancestor(of: find.text('-'), matching: find.byType(Container)).first,
    );
    final label = tester.widget<Text>(find.text('Semester to Register'));

    expect(scaffold.backgroundColor, AppThemePalette.background);
    expect((panel.decoration! as BoxDecoration).color, AppThemePalette.surface);
    expect(
      (valueChip.decoration! as BoxDecoration).color,
      AppThemePalette.accentAvatar,
    );
    expect(label.style?.color, AppThemePalette.textPrimary);
  });
}
