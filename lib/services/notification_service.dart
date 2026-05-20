import 'dart:convert';

import 'package:chatbot/models/notification_models.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<NotificationResult> openNotifications({
    required String idLogin,
    required String token,
    http.Client? client,
  }) async {
    final response = await _post(
      '/open-notification',
      body: {'IdLogin': idLogin, 'token': token},
      client: client,
    );

    return NotificationResult.fromJson(response);
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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
