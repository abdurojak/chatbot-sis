import 'dart:convert';

import 'package:chatbot/models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevAccountCredential {
  final String idLogin;
  final String token;

  const DevAccountCredential({required this.idLogin, required this.token});

  Map<String, dynamic> toJson() => {'idLogin': idLogin, 'token': token};

  factory DevAccountCredential.fromJson(Map<String, dynamic> json) {
    return DevAccountCredential(
      idLogin: json['idLogin']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}

class AuthStorage {
  static const _keyToken = 'token';
  static const _keyIdLogin = 'idLogin';
  static const _keyUserId = 'userid';
  static const _keyNim = 'nim';
  static const _keyStudentName = 'stdname';
  static const _keyColor = 'color';
  static const _keyDarkMode = 'dark_mode';
  static const _keyPhoto = 'photo';
  static const _keyActive = 'active';
  static const _keyRole = 'role';
  static const _keyDevAccounts = 'dev_accounts';

  static Future<void> saveAuth({
    required String token,
    required String idLogin,
    required String userId,
    required String nim,
    String studentName = '',
    String? color,
    String? photoBase64,
    String? active,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyIdLogin, idLogin);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyNim, nim);
    await prefs.setString(_keyStudentName, studentName);

    if (color != null) await prefs.setString(_keyColor, color);
    if (photoBase64 != null) await prefs.setString(_keyPhoto, photoBase64);
    if (active != null) await prefs.setString(_keyActive, active);
    if (role != null) await prefs.setString(_keyRole, role);
  }

  static Future<void> saveSession(AuthSession session) async {
    await saveAuth(
      token: session.token,
      idLogin: session.idLogin,
      userId: session.userId,
      nim: session.nim,
      studentName: session.studentName,
      color: session.color,
      photoBase64: session.photoBase64,
      active: session.active,
      role: session.role,
    );
  }

  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final idLogin = prefs.getString(_keyIdLogin);
    final userId = prefs.getString(_keyUserId);
    final nim = prefs.getString(_keyNim);
    final studentName = prefs.getString(_keyStudentName) ?? '';

    if (token == null || idLogin == null || userId == null || nim == null) {
      return null;
    }

    return AuthSession(
      token: token,
      idLogin: idLogin,
      userId: userId,
      nim: nim,
      studentName: studentName,
      color: prefs.getString(_keyColor),
      photoBase64: prefs.getString(_keyPhoto),
      active: prefs.getString(_keyActive),
      role: prefs.getString(_keyRole),
    );
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

  static Future<void> saveColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColor, color);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
  }

  static Future<String?> getPhotoBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoto);
  }

  static Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActive) == '1';
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyIdLogin);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyNim);
    await prefs.remove(_keyStudentName);
    await prefs.remove(_keyColor);
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyPhoto);
    await prefs.remove(_keyActive);
    await prefs.remove(_keyRole);
  }

  static Future<void> saveManualSession({
    required String idLogin,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyIdLogin, idLogin);
    await prefs.setString(_keyUserId, idLogin);
    await prefs.setString(_keyNim, idLogin);
    await prefs.setString(_keyStudentName, idLogin);
    await prefs.remove(_keyColor);
    await prefs.remove(_keyPhoto);
    await prefs.setString(_keyActive, '1');
    await prefs.setString(_keyRole, 'STD');
  }

  static Future<void> saveDevAccountHistory({
    required String idLogin,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadDevAccountHistory();
    final next = <DevAccountCredential>[
      DevAccountCredential(idLogin: idLogin, token: token),
      ...current.where(
        (item) => !(item.idLogin == idLogin && item.token == token),
      ),
    ];
    final jsonList = next.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_keyDevAccounts, jsonList);
  }

  static Future<List<DevAccountCredential>> loadDevAccountHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyDevAccounts) ?? const [];
    return raw
        .map((item) {
          try {
            final json = jsonDecode(item);
            if (json is Map<String, dynamic>) {
              return DevAccountCredential.fromJson(json);
            }
            if (json is Map) {
              return DevAccountCredential.fromJson(
                Map<String, dynamic>.from(json),
              );
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<DevAccountCredential>()
        .where(
          (item) =>
              item.idLogin.trim().isNotEmpty && item.token.trim().isNotEmpty,
        )
        .toList();
  }
}
