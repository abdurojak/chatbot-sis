import 'dart:convert';

import 'package:chatbot/models/convocation_models.dart';
import 'package:http/http.dart' as http;

class ConvocationService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';
  static const String _sisBaseUrl = 'https://sis.trisakti.ac.id';

  static Future<ConvocationData> getConvocation({
    required String idLogin,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/convocation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdLogin': idLogin, 'token': token}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
        json['message']?.toString() ??
            json['status']?.toString() ??
            'Gagal mengambil data wisuda',
      );
    }

    return ConvocationResponse.fromJson(json).data;
  }

  static Future<String> submitApplication({
    required String idLogin,
    required String token,
    required ConvocationApplicationRequest request,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/convocation-application'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        ...request.toJson(),
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Aplikasi wisuda berhasil dikirim';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<String> submitApplicationOption({
    required String idLogin,
    required String token,
    required ConvocationApplicationOptionRequest request,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/convocation-application-option'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        ...request.toJson(),
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Paket foto berhasil disimpan';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<List<ConvocationInvitationCard>> getInvitationCards({
    required String idLogin,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/convocation-invitation-card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdLogin': idLogin, 'token': token}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
        json['message']?.toString() ??
            json['status']?.toString() ??
            'Gagal mengambil data undangan wisuda',
      );
    }

    final body = json['body'];
    final bodyMap = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    final list = (bodyMap['data'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ConvocationInvitationCard.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return list;
  }

  static Future<String> uploadCompanion({
    required String idLogin,
    required String token,
    required String convoid,
    required String invitationId,
    required String mime,
    required String base64Data,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/convocation-pendamping'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'convoid': convoid,
        'invitationId': invitationId,
        'file': {'mime': mime, 'data': base64Data},
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Unggah pendamping berhasil';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<void> generateInvitationCard({required String idLogin}) async {
    final response = await http.get(
      Uri.parse('$_sisBaseUrl/index/invitation-card-convo-pdf/idstd/$idLogin'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal generate undangan (HTTP ${response.statusCode})');
    }
  }
}
