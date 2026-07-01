import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app bar theme uses slate only in dark mode', () async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    expect(
      AppThemeController.instance.themeData.appBarTheme.backgroundColor,
      AppThemePalette.darkSlateBar,
    );
    expect(
      AppThemeController.instance.themeData.appBarTheme.foregroundColor,
      AppThemePalette.onPrimary(AppThemePalette.darkSlateBar),
    );

    await AppThemeController.instance.updateDarkMode(false);

    expect(
      AppThemeController.instance.themeData.appBarTheme.backgroundColor,
      AppThemePalette.primary,
    );
  });

  testWidgets('home chat card bot icon uses app background in dark mode', (
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
            of: find.byType(ImageIcon),
            matching: find.byType(CircleAvatar),
          )
          .first,
    );
    final icon = tester.widget<ImageIcon>(find.byType(ImageIcon).first);
    final image = icon.image as AssetImage;

    expect(avatar.backgroundColor, AppThemePalette.background);
    expect(image.assetName, 'assets/images/sis_bot_icon.png');
  });

  testWidgets('home top and bottom bars use dark slate in dark mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final headerContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.textContaining('MAHASISWA'),
            matching: find.byType(Container),
          )
          .first,
    );
    final headerDecoration = headerContainer.decoration! as BoxDecoration;
    expect(headerDecoration.color, AppThemePalette.darkSlateBar);

    final bottomBar = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.notifications),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(bottomBar.color, AppThemePalette.darkSlateBar);

    final floatingChat = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.chat_sharp),
            matching: find.byType(Container),
          )
          .first,
    );
    final floatingDecoration = floatingChat.decoration! as BoxDecoration;
    expect(floatingDecoration.color, AppThemePalette.darkSlateBar);
  });

  testWidgets('home main cards use slate gradient in dark mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatPage())),
    );

    final cardContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Academic Assistant'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = cardContainer.decoration! as BoxDecoration;

    expect(decoration.gradient, isA<LinearGradient>());
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, [const Color(0xFF1E293B), const Color(0xFF334155)]);
  });

  testWidgets('home header greets student first name from session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token',
      'idLogin': '205040',
      'userid': 'U-205040',
      'nim': '064102400001',
      'stdname': 'AHMAD  ARDIANSYAH',
    });
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('AHMAD'), findsOneWidget);
    expect(find.textContaining('ARDIANSYAH'), findsNothing);
    expect(find.textContaining('064102400001'), findsNothing);
  });

  testWidgets('home header does not use NIM when student name is missing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token',
      'idLogin': '205040',
      'userid': 'U-205040',
      'nim': '064102400002',
    });
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('MAHASISWA'), findsOneWidget);
    expect(find.textContaining('064102400002'), findsNothing);
  });
}
