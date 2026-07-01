import 'dart:convert';
import 'dart:typed_data';

import 'package:chatbot/models/transcript_models.dart';
import 'package:http/http.dart' as http;

class TranscriptService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<TranscriptData> getTranscript({
    required String idLogin,
    required String token,
    http.Client? client,
  }) async {
    final response = await _post(
      '/get-transkrip',
      body: {'IdLogin': idLogin, 'token': token},
      client: client,
    );

    return TranscriptData.fromJson(response);
  }

  static Future<Uint8List> downloadTranscriptBytes(
    String filePath, {
    http.Client? client,
  }) async {
    final uri = Uri.parse(filePath);
    final response = client == null
        ? await http.get(uri)
        : await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal memuat PDF transkrip.');
    }
    return response.bodyBytes;
  }

  static Future<Map<String, dynamic>> _post(
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

    return jsonDecode(_extractJsonObject(response.body))
        as Map<String, dynamic>;
  }

  static String _extractJsonObject(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.startsWith('{')) {
      return trimmed;
    }

    final jsonStart = trimmed.indexOf('{');
    if (jsonStart == -1) {
      return trimmed;
    }
    return trimmed.substring(jsonStart);
  }
}
