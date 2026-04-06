import 'package:chatbot/component/authentication.dart';
import 'package:flutter/material.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  Color _primaryColor = AppThemePalette.fallbackPrimary;

  Color get primaryColor => _primaryColor;

  Future<void> loadSavedColor() async {
    final storedColor = await AuthStorage.getColor();
    _setPrimaryColor(AppThemePalette.parseHex(storedColor), notify: false);
  }

  void updatePrimaryColor(String? hexColor) {
    _setPrimaryColor(AppThemePalette.parseHex(hexColor));
  }

  ThemeData get themeData {
    final primaryColor = _primaryColor;
    final onPrimary = AppThemePalette.onPrimary(primaryColor);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryColor,
          secondary: primaryColor,
          onPrimary: onPrimary,
          surface: Colors.white,
        );

    return ThemeData(
      useMaterial3: false,
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primaryColor.withAlpha(115),
          disabledForegroundColor: onPrimary.withAlpha(217),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setPrimaryColor(Color color, {bool notify = true}) {
    if (_primaryColor.toARGB32() == color.toARGB32()) return;

    _primaryColor = color;
    if (notify) {
      notifyListeners();
    }
  }
}

class AppThemePalette {
  static const Color fallbackPrimary = Color(0xFF1E73BE);

  static Color get primary => AppThemeController.instance.primaryColor;

  static Color parseHex(String? hexColor) {
    final cleaned = hexColor?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return fallbackPrimary;
    }

    final normalized = cleaned.replaceFirst('#', '');
    final isValid = RegExp(
      r'^[0-9a-fA-F]{6}$|^[0-9a-fA-F]{8}$',
    ).hasMatch(normalized);
    if (!isValid) {
      return fallbackPrimary;
    }

    final buffer = StringBuffer();
    if (normalized.length == 6) {
      buffer.write('FF');
    }
    buffer.write(normalized.toUpperCase());

    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static Color onPrimary([Color? color]) {
    final target = color ?? primary;
    return ThemeData.estimateBrightnessForColor(target) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  static Color soft([double amount = 0.85]) {
    return Color.lerp(primary, Colors.white, amount) ?? primary;
  }

  static Color dark([double amount = 0.2]) {
    return Color.lerp(primary, Colors.black, amount) ?? primary;
  }

  static LinearGradient screenGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primary, Colors.white],
    );
  }

  static LinearGradient cardGradient() {
    return LinearGradient(colors: [primary, soft(0.72)]);
  }
}
