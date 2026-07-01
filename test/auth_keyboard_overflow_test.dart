import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/forgot_password_screen.dart';
import 'package:chatbot/login_screen.dart';
import 'package:chatbot/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LoginScreen scrolls when keyboard is visible', (tester) async {
    await _pumpWithKeyboard(tester, const LoginScreen());

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('LoginScreen submits from tablet keyboard done action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();

    expect(fields, hasLength(2));
    expect(fields.first.textInputAction, TextInputAction.next);
    expect(fields.last.textInputAction, TextInputAction.done);
    expect(fields.last.onSubmitted, isNotNull);
  });

  testWidgets('ForgotPasswordScreen scrolls when keyboard is visible', (
    tester,
  ) async {
    await _pumpWithKeyboard(tester, const ForgotPasswordScreen());

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('OtpVerificationScreen confirms from keyboard done action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(
      const MaterialApp(home: OtpVerificationScreen(idOtp: 'otp-id')),
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();

    expect(fields, hasLength(6));
    expect(fields.last.textInputAction, TextInputAction.done);
    expect(fields.last.onSubmitted, isNotNull);
  });
}

Future<void> _pumpWithKeyboard(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  await AppThemeController.instance.updateDarkMode(false);

  tester.view.physicalSize = const Size(390, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 320);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
}
