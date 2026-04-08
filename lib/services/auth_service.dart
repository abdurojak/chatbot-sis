import 'dart:convert';

import 'package:chatbot/models/auth_models.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<LoginResult> login({
    required String user,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user': user, 'password': password}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult.fromJson(json, statusCode: response.statusCode);
  }

  static Future<OtpVerificationResult> verifyOtp({
    required String idOtp,
    required String otpCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/otp-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_otp': idOtp, 'kode_otp': otpCode}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OtpVerificationResult.fromJson(
      json,
      statusCode: response.statusCode,
    );
  }
}
