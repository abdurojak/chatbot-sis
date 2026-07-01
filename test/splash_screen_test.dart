import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('splash uses dark logo asset in dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(autoNavigate: false)),
    );

    final logo = tester.widget<Image>(find.byType(Image));
    final image = logo.image as AssetImage;

    expect(image.assetName, 'assets/images/logo_trisakti_black.png');
    expect(logo.color, isNull);
  });

  testWidgets('splash keeps white logo treatment in light mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(autoNavigate: false)),
    );

    final logo = tester.widget<Image>(find.byType(Image));
    final image = logo.image as AssetImage;

    expect(image.assetName, 'assets/images/logo_trisakti.png');
    expect(logo.color, Colors.white);
  });
}
