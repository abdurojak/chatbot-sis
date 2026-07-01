import 'dart:convert';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ProfilePage shows login session data and hides developer mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token',
      'idLogin': '205040',
      'userid': 'U-205040',
      'nim': '064102400001',
      'stdname': 'AHMAD  ARDIANSYAH',
      'photo': _transparentPixelDataUrl,
      'active': '1',
      'role': 'STD',
      'color': '#1E73BE',
    });
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Development Mode'), findsNothing);
    expect(find.text('AHMAD  ARDIANSYAH'), findsOneWidget);
    expect(find.text('205040'), findsOneWidget);
    expect(find.text('U-205040'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Mahasiswa Aktif'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsWidgets);

    final profileCard = _profileCardColor(tester);
    expect(profileCard, AppThemePalette.surface);

    await AppThemeController.instance.updateDarkMode(true);
    await tester.pump();

    expect(_profileCardColor(tester), isNot(profileCard));
    expect(_profileCardColor(tester), AppThemePalette.surface);
  });

  testWidgets('ProfilePage requires login when no session exists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login Required'), findsOneWidget);
    expect(
      find.text('Masuk untuk melihat profil akademik Anda.'),
      findsOneWidget,
    );
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Development Mode'), findsNothing);
  });

  testWidgets('ProfilePage logout clears session and shows login required', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token',
      'idLogin': '205040',
      'userid': 'U-205040',
      'nim': '064102400001',
      'stdname': 'AHMAD  ARDIANSYAH',
      'active': '1',
      'role': 'STD',
    });
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Logout'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), isNull);
    expect(prefs.getString('idLogin'), isNull);
    await tester.scrollUntilVisible(
      find.text('Login Required'),
      -300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Login Required'), findsOneWidget);
  });
}

Color? _profileCardColor(WidgetTester tester) {
  final cardFinder = find.ancestor(
    of: find.text('AHMAD  ARDIANSYAH'),
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

final _transparentPixelDataUrl =
    'data:image/png;base64,${base64Encode(_transparentPixelPng)}';

final _transparentPixelPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
