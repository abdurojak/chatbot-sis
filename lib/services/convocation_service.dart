import 'dart:convert';

import 'package:chatbot/models/convocation_models.dart';
import 'package:http/http.dart' as http;

class ConvocationService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

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
}
