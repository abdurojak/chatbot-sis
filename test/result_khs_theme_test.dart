import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/result_khs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HasilKhsPage section title uses dark theme color', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(const MaterialApp(home: HasilKhsPage()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final detailTitle = tester.widget<Text>(find.text('Detail Mata Kuliah'));

    expect(scaffold.backgroundColor, AppThemePalette.background);
    expect(detailTitle.style?.color, AppThemePalette.textPrimary);
  });

  testWidgets('KHS performance card uses negative accent and metric icon', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildKhsPerformanceCardForTest(
            title: 'IPS',
            value: '3.75',
            icon: Icons.show_chart,
          ),
        ),
      ),
    );

    final card = tester.widget<Container>(
      find
          .ancestor(of: find.text('IPS'), matching: find.byType(Container))
          .last,
    );
    final decoration = card.decoration! as BoxDecoration;
    final icon = tester.widget<Icon>(find.byIcon(Icons.show_chart));
    final value = tester.widget<Text>(find.text('3.75'));

    expect(decoration.border!.top.color, AppThemePalette.negative());
    expect(icon.color, AppThemePalette.negative());
    expect(value.style?.color, AppThemePalette.negative());
  });
}
