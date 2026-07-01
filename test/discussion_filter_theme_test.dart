import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('discussion requires login before showing categories', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: DiscussionPage()));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Pilih kategori diskusi'), findsNothing);
    expect(find.text('Kontak'), findsNothing);
  });

  testWidgets('selected discussion categories and filters use avatar color', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token',
      'idLogin': '241149',
      'userid': '241149',
      'nim': '064102400001',
    });
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: DiscussionPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All'));
    await tester.pump();

    final selectedCategoryContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('[All]'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final selectedCategoryDecoration =
        selectedCategoryContainer.decoration! as BoxDecoration;

    final unselectedCategoryContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('[KRS]'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final unselectedCategoryDecoration =
        unselectedCategoryContainer.decoration! as BoxDecoration;

    final selectedFilterChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'All'),
    );
    final unselectedFilterChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Unread'),
    );

    expect(selectedCategoryDecoration.color, AppThemePalette.accentAvatar);
    expect(unselectedCategoryDecoration.color, AppThemePalette.mutedSurface);
    expect(selectedFilterChip.selectedColor, AppThemePalette.accentAvatar);
    expect(unselectedFilterChip.backgroundColor, AppThemePalette.mutedSurface);
  });
}
