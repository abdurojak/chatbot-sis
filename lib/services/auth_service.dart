import 'dart:convert';

import 'package:chatbot/models/auth_models.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<LoginResult> login({
    required String user,
    required String password,
    http.Client? client,
  }) async {
    final response = await _post(
      '/login',
      body: {'user': user, 'password': password},
      client: client,
    );

    final result = LoginResult.fromJson(
      response.json,
      statusCode: response.statusCode,
    );

    final session = result.session;
    if (!result.isSuccess || session == null || session.role != null) {
      return result;
    }

    String? role;
    try {
      role = await getRole(idLogin: session.idLogin, client: client);
    } catch (_) {
      role = null;
    }
    return LoginResult(
      isSuccess: result.isSuccess,
      message: result.message,
      idOtp: result.idOtp,
      session: session.copyWith(role: role),
    );
  }

  static Future<String?> getRole({
    required String idLogin,
    http.Client? client,
  }) async {
    final response = await _post(
      '/get-role',
      body: {'IdLogin': idLogin},
      client: client,
    );

    return _readNullableString(response.json['role']);
  }

  static Future<OtpVerificationResult> verifyOtp({
    required String idOtp,
    required String otpCode,
    http.Client? client,
  }) async {
    final response = await _post(
      '/otp-verification',
      body: {'id_otp': idOtp, 'kode_otp': otpCode},
      client: client,
    );

    return OtpVerificationResult.fromJson(
      response.json,
      statusCode: response.statusCode,
    );
  }

  static Future<_JsonResponse> _post(
    String path, {
    required Map<String, dynamic> body,
    http.Client? client,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    final encodedBody = jsonEncode(body);
    final response = client == null
        ? await http.post(uri, headers: headers, body: encodedBody)
        : await client.post(uri, headers: headers, body: encodedBody);

    return _JsonResponse(
      statusCode: response.statusCode,
      json: jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class _JsonResponse {
  final int statusCode;
  final Map<String, dynamic> json;

  const _JsonResponse({required this.statusCode, required this.json});
}

String? _readNullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}
