import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyToken = 'token';
  static const _keyIdLogin = 'idLogin';
  static const _keyUserId = 'userid';
  static const _keyNim = 'nim';
  static const _keyColor = 'color';
  static const _keyPhoto = 'photo';
  static const _keyActive = 'active';

  static Future<void> saveAuth({
    required String token,
    required String idLogin,
    required String userId,
    required String nim,
    String? color,
    String? photoBase64,
    String? active,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyIdLogin, idLogin);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyNim, nim);

    if (color != null) await prefs.setString(_keyColor, color);
    if (photoBase64 != null) await prefs.setString(_keyPhoto, photoBase64);
    if (active != null) await prefs.setString(_keyActive, active);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getIdLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIdLogin);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getNim() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNim);
  }

  static Future<String?> getColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyColor);
  }

  static Future<String?> getPhotoBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoto);
  }

  static Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActive) == '1';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyIdLogin);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyNim);
    await prefs.remove(_keyColor);
    await prefs.remove(_keyPhoto);
    await prefs.remove(_keyActive);
  }
}
