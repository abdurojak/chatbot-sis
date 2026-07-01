import 'dart:convert';

import 'package:chatbot/models/khs_models.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:http/http.dart' as http;

class KhsService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<String?> getDefaultSemester({
    required String idLogin,
    required String token,
    http.Client? client,
  }) async {
    final response = await _post(
      '/krs-requirement',
      body: {'IdLogin': idLogin, 'token': token},
      client: client,
    );

    return response['body']?['IdSemesterMain']?.toString();
  }

  static Future<List<SemesterInfo>> getSemesters({
    required String idLogin,
    required String token,
    http.Client? client,
  }) async {
    final response = await _post(
      '/get-semester',
      body: {'IdLogin': idLogin, 'token': token},
      client: client,
    );

    return ((response['body']?['semester'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => SemesterInfo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<KhsResponseData> getKhs({
    required String idLogin,
    required String token,
    required String idSemester,
    http.Client? client,
  }) async {
    final response = await _post(
      '/get-khs',
      body: {'IdLogin': idLogin, 'token': token, 'IdSemester': idSemester},
      client: client,
    );

    return KhsResponseData.fromJson(response);
  }

  static Future<KhsPageData> fetchPageData({
    required String idLogin,
    required String token,
    http.Client? client,
  }) async {
    final semesters = await getSemesters(
      idLogin: idLogin,
      token: token,
      client: client,
    );

    String? defaultSemesterId;
    try {
      defaultSemesterId = await getDefaultSemester(
        idLogin: idLogin,
        token: token,
        client: client,
      );
    } catch (_) {
      defaultSemesterId = null;
    }

    final resolvedSemesterId =
        semesters.any(
          (semester) => semester.idSemesterMaster == defaultSemesterId,
        )
        ? defaultSemesterId
        : semesters.isNotEmpty
        ? semesters.first.idSemesterMaster
        : null;

    final khs = resolvedSemesterId == null
        ? const KhsResponseData(
            performance: KhsPerformance(
              ips: '0.00',
              ipk: '0.00',
              sksSemester: '0',
              sksLulus: '0',
            ),
            details: [],
          )
        : await getKhs(
            idLogin: idLogin,
            token: token,
            idSemester: resolvedSemesterId,
            client: client,
          );

    return KhsPageData(
      defaultSemesterId: resolvedSemesterId,
      semesters: semesters,
      khs: khs,
    );
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

    return json.decode(response.body) as Map<String, dynamic>;
  }
}
