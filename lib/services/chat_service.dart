import 'dart:convert';

import 'package:chatbot/models/chat_models.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';
  static const String defaultCategory = 'Umum';
  static const String defaultDestType = '3';
  static const List<String> categories = [
    'Krs',
    'Keuangan',
    'Perkuliahan',
    'Ujian',
    'Nilai',
    'Wisuda',
    'Bimbingan',
    'Capstone',
    'Skripsi',
  ];

  static Future<List<ChatContact>> getContacts({
    required String idLogin,
    required String token,
    String category = '',
    http.Client? client,
  }) async {
    final response = await _post(
      '/chat-get-contact',
      body: {'IdLogin': idLogin, 'token': token, 'category': category},
      client: client,
    );

    return ChatContactResponse.fromJson(response).contacts;
  }

  static Future<List<ChatContact>> getContactsWithAutoGenerate({
    required String idLogin,
    required String token,
    String category = '',
    http.Client? client,
  }) async {
    final contacts = await getContacts(
      idLogin: idLogin,
      token: token,
      category: category,
      client: client,
    );
    if (contacts.isNotEmpty) {
      return contacts;
    }

    await generateContacts(idLogin: idLogin, token: token, client: client);
    return getContacts(
      idLogin: idLogin,
      token: token,
      category: category,
      client: client,
    );
  }

  static Future<List<ChatSearchResult>> searchContacts({
    required String idLogin,
    required String token,
    required String keyword,
    http.Client? client,
  }) async {
    final response = await _post(
      '/chat-search-contact',
      body: {'IdLogin': idLogin, 'token': token, 'keyword': keyword},
      client: client,
    );

    return ChatSearchResponse.fromJson(response).results;
  }

  static Future<List<ChatSearchResult>> searchContactsWithAutoGenerate({
    required String idLogin,
    required String token,
    required String keyword,
    http.Client? client,
  }) async {
    final results = await searchContacts(
      idLogin: idLogin,
      token: token,
      keyword: keyword,
      client: client,
    );
    if (results.isNotEmpty) {
      return results;
    }

    await generateContacts(idLogin: idLogin, token: token, client: client);
    return searchContacts(
      idLogin: idLogin,
      token: token,
      keyword: keyword,
      client: client,
    );
  }

  static Future<ChatActionResult> generateContacts({
    required String idLogin,
    required String token,
    http.Client? client,
  }) async {
    final response = await _post(
      '/chat-generate-contact',
      body: {'IdLogin': idLogin, 'token': token},
      client: client,
    );

    return ChatActionResult.fromJson(response);
  }

  static Future<List<ChatMessage>> getContactContent({
    required String idLogin,
    required String token,
    required String idReceiver,
    String destType = defaultDestType,
    http.Client? client,
  }) async {
    final response = await _post(
      '/chat-get-contact-content',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'IdReceiver': idReceiver,
        'desttype': destType,
      },
      client: client,
    );

    return ChatMessageResponse.fromJson(response).messages;
  }

  static Future<ChatActionResult> sendMessage({
    required String idLogin,
    required String token,
    required String idReceiver,
    String destType = defaultDestType,
    String category = defaultCategory,
    required String message,
    http.Client? client,
  }) async {
    final response = await _post(
      '/chat-message',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'IdReceiver': idReceiver,
        'desttype': destType,
        'category': category,
        'pesan': message,
      },
      client: client,
    );

    return ChatActionResult.fromJson(response);
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

    final decoded = jsonDecode(_extractJsonObject(response.body));
    return decoded as Map<String, dynamic>;
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
