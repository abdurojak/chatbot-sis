import 'dart:convert';

import 'package:chatbot/models/skpi_models.dart';
import 'package:http/http.dart' as http;

class SkpiPageData {
  final List<SkpiOrganization> organizations;
  final List<SkpiLanguage> languages;
  final List<SkpiSoftskill> softskills;
  final List<SkpiHonor> honors;

  const SkpiPageData({
    required this.organizations,
    required this.languages,
    required this.softskills,
    required this.honors,
  });
}

class SkpiService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<List<SkpiOrganization>> getOrganizations({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-organisasi',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiResponseData<SkpiOrganization>.fromJson(
      response,
      SkpiOrganization.fromJson,
    ).items;
  }

  static Future<List<SkpiLanguage>> getLanguages({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-language',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiResponseData<SkpiLanguage>.fromJson(
      response,
      SkpiLanguage.fromJson,
    ).items;
  }

  static Future<List<SkpiSoftskill>> getSoftskills({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-softskill',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiResponseData<SkpiSoftskill>.fromJson(
      response,
      SkpiSoftskill.fromJson,
    ).items;
  }

  static Future<List<SkpiHonor>> getHonors({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-honors',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiResponseData<SkpiHonor>.fromJson(
      response,
      SkpiHonor.fromJson,
    ).items;
  }

  static Future<SkpiFetchedEvidence> getEvidence({
    required String idLogin,
    required String token,
    required String idFile,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/skpi-get-file-evidence'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdLogin': idLogin, 'token': token, 'idfile': idFile}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
        json['message']?.toString() ??
            json['status']?.toString() ??
            'Gagal mengambil file evidence',
      );
    }

    final base64Data = json['body']?['data']?.toString() ?? '';
    if (base64Data.isEmpty) {
      throw Exception('Data file evidence kosong');
    }

    return SkpiFetchedEvidence.fromBase64(
      base64Data,
      fallbackName: 'Evidence_$idFile',
    );
  }

  static Future<SkpiHonorReferenceData> getHonorReferences({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-reference-honors',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiHonorReferenceData.fromJson(response);
  }

  static Future<SkpiTransactionResult> addHonor({
    required String idLogin,
    required String token,
    required String title,
    required String titleBahasa,
    required String dateOfHonor,
    required String givenBy,
    required String level,
    required String field,
  }) async {
    final response = await _post(
      '/skpi-transaction-honors',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': 'add',
        'idHonor': '',
        'title': title,
        'title_bahasa': titleBahasa,
        'date_of_honor': dateOfHonor,
        'given_by': givenBy,
        'level': level,
        'field': field,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiPageData> fetchPageData({
    required String idLogin,
    required String token,
  }) async {
    final results = await Future.wait([
      getOrganizations(idLogin: idLogin, token: token),
      getLanguages(idLogin: idLogin, token: token),
      getSoftskills(idLogin: idLogin, token: token),
      getHonors(idLogin: idLogin, token: token),
    ]);

    return SkpiPageData(
      organizations: results[0] as List<SkpiOrganization>,
      languages: results[1] as List<SkpiLanguage>,
      softskills: results[2] as List<SkpiSoftskill>,
      honors: results[3] as List<SkpiHonor>,
    );
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
