import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/result_skpi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              internshipCount: 6,
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

  testWidgets('evidence source sheet uses themed surface in dark mode', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildSkpiEvidenceSourceSheetForTest(onSelect: (_) {}),
        ),
      ),
    );

    final sheet = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Ambil dari Kamera'),
            matching: find.byType(Container),
          )
          .last,
    );
    final title = tester.widget<Text>(find.text('Ambil dari Kamera'));

    expect((sheet.decoration! as BoxDecoration).color, AppThemePalette.surface);
    expect(title.style?.color, AppThemePalette.textPrimary);
  });

  testWidgets('SKPI section accent uses negative color', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    expect(skpiSectionAccentColorForTest(), AppThemePalette.negative());
  });

  testWidgets('SKPI destructive action color is dark-mode aware', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    expect(skpiDestructiveColorForTest(), isNot(Colors.red));
  });

  testWidgets('SKPI expanded item palette follows requested colors', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    expect(
      skpiExpandedItemBackgroundForTest(),
      AppThemePalette.primary.withAlpha(42),
    );
    expect(skpiExpandedItemAccentForTest(), AppThemePalette.negative());
    expect(skpiEditActionColorForTest(), const Color(0xFFF59E0B));
    expect(skpiDeleteActionColorForTest(), const Color(0xFFEF4444));
  });
}
