import 'package:chatbot/component/authentication.dart';
import 'package:flutter/material.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  Color _primaryColor = AppThemePalette.fallbackPrimary;
  bool _isDarkMode = false;

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadSavedColor() async {
    final storedColor = await AuthStorage.getColor();
    _isDarkMode = await AuthStorage.getDarkMode();
    _setPrimaryColor(AppThemePalette.parseHex(storedColor), notify: false);
  }

  void updatePrimaryColor(String? hexColor) {
    _setPrimaryColor(AppThemePalette.parseHex(hexColor));
  }

  Future<void> updateDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) return;
    _isDarkMode = enabled;
    await AuthStorage.saveDarkMode(enabled);
    notifyListeners();
  }

  ThemeData get themeData {
    final primaryColor = _primaryColor;
    final onPrimary = AppThemePalette.onPrimary(primaryColor);
    final brightness = _isDarkMode ? Brightness.dark : Brightness.light;
    final background = AppThemePalette.background;
    final surface = AppThemePalette.surface;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primaryColor,
          secondary: primaryColor,
          onPrimary: onPrimary,
          surface: surface,
        );

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
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
      iconTheme: IconThemeData(color: AppThemePalette.textSecondary),
      dividerColor: AppThemePalette.divider,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: TextStyle(
          color: AppThemePalette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: AppThemePalette.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppThemePalette.fieldFill,
        hintStyle: TextStyle(color: AppThemePalette.textTertiary),
        labelStyle: TextStyle(color: AppThemePalette.textSecondary),
        prefixIconColor: AppThemePalette.textSecondary,
        suffixIconColor: AppThemePalette.textSecondary,
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: AppThemePalette.textPrimary,
        displayColor: AppThemePalette.textPrimary,
      ),
      primaryTextTheme: ThemeData(brightness: brightness).primaryTextTheme,
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
  static bool get isDark => AppThemeController.instance.isDarkMode;
  static Color get background =>
      isDark ? const Color(0xFF0F172A) : Colors.white;
  static Color get surface => isDark ? const Color(0xFF172033) : Colors.white;
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF7F9FC);
  static Color get fieldFill =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F5FA);
  static Color get mutedSurface =>
      isDark ? const Color(0xFF273449) : const Color(0xFFF2F2F2);
  static Color get textPrimary =>
      isDark ? const Color(0xFFF8FAFC) : Colors.black87;
  static Color get textSecondary =>
      isDark ? const Color(0xFFCBD5E1) : Colors.black54;
  static Color get textTertiary =>
      isDark ? const Color(0xFF94A3B8) : Colors.black45;
  static Color get divider =>
      isDark ? Colors.white.withAlpha(24) : Colors.black.withAlpha(18);
  static Color get shadow =>
      isDark ? Colors.black.withAlpha(80) : Colors.black.withAlpha(18);

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
    final target = isDark ? const Color(0xFF0F172A) : Colors.white;
    return Color.lerp(primary, target, amount) ?? primary;
  }

  static Color negative([Color? color]) {
    final target = color ?? primary;
    final hsl = HSLColor.fromColor(target);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }

  static Color negativeSoft([double amount = 0.72]) {
    final target = isDark ? const Color(0xFF0F172A) : Colors.white;
    return Color.lerp(negative(), target, amount) ?? negative();
  }

  static Color dark([double amount = 0.2]) {
    return Color.lerp(primary, Colors.black, amount) ?? primary;
  }

  static LinearGradient screenGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primary, background],
    );
  }

  static LinearGradient cardGradient() {
    return LinearGradient(colors: [primary, soft(0.72)]);
  }
}
