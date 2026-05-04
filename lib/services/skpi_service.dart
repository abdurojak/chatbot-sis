import 'dart:convert';

import 'package:chatbot/models/skpi_models.dart';
import 'package:http/http.dart' as http;

class SkpiPageData {
  final List<SkpiOrganization> organizations;
  final List<SkpiLanguage> languages;
  final List<SkpiSoftskill> softskills;
  final List<SkpiInternship> internships;
  final List<SkpiHonor> honors;

  const SkpiPageData({
    required this.organizations,
    required this.languages,
    required this.softskills,
    required this.internships,
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

  static Future<List<SkpiInternship>> getInternships({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-internship',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiResponseData<SkpiInternship>.fromJson(
      response,
      SkpiInternship.fromJson,
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

  static Future<SkpiTransactionResult> uploadEvidence({
    required String idLogin,
    required String token,
    required String itemsId,
    required String documentName,
    required String mime,
    required String base64Data,
  }) async {
    final response = await _post(
      '/skpi-evidence',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'items_id': itemsId,
        'document_name': documentName,
        'file': {'mime': mime, 'data': base64Data},
      },
    );

    return SkpiTransactionResult.fromJson(response);
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

  static Future<SkpiOrganizationReferenceData> getOrganizationReferences({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-reference-organisasi',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiOrganizationReferenceData.fromJson(response);
  }

  static Future<SkpiLanguageReferenceData> getLanguageReferences({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/skpi-get-reference-language',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return SkpiLanguageReferenceData.fromJson(response);
  }

  static Future<SkpiTransactionResult> addLanguage({
    required String idLogin,
    required String token,
    required String languageId,
    required String languageStandard,
    required String dateOfTaken,
    required String score,
  }) async {
    return saveLanguage(
      idLogin: idLogin,
      token: token,
      act: 'add',
      idLanguage: '',
      languageId: languageId,
      languageStandard: languageStandard,
      dateOfTaken: dateOfTaken,
      score: score,
    );
  }

  static Future<SkpiTransactionResult> updateLanguage({
    required String idLogin,
    required String token,
    required String idLanguage,
    required String languageId,
    required String languageStandard,
    required String dateOfTaken,
    required String score,
  }) async {
    return saveLanguage(
      idLogin: idLogin,
      token: token,
      act: 'update',
      idLanguage: idLanguage,
      languageId: languageId,
      languageStandard: languageStandard,
      dateOfTaken: dateOfTaken,
      score: score,
    );
  }

  static Future<SkpiTransactionResult> deleteLanguage({
    required String idLogin,
    required String token,
    required String idLanguage,
  }) async {
    final response = await _post(
      '/skpi-transaction-language',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': 'delete',
        'idLanguage': idLanguage,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> saveLanguage({
    required String idLogin,
    required String token,
    required String act,
    required String idLanguage,
    required String languageId,
    required String languageStandard,
    required String dateOfTaken,
    required String score,
  }) async {
    final response = await _post(
      '/skpi-transaction-language',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': act,
        'idLanguage': idLanguage,
        'languageid': languageId,
        'language_standart': languageStandard,
        'date_of_taken': dateOfTaken,
        'Skore': score,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> addSoftskill({
    required String idLogin,
    required String token,
    required String title,
    required String titleBahasa,
    required String dateStart,
    required String dateStop,
    required String hours,
    required String givenBy,
  }) async {
    return saveSoftskill(
      idLogin: idLogin,
      token: token,
      act: 'add',
      idSoftskill: '',
      title: title,
      titleBahasa: titleBahasa,
      dateStart: dateStart,
      dateStop: dateStop,
      hours: hours,
      givenBy: givenBy,
    );
  }

  static Future<SkpiTransactionResult> updateSoftskill({
    required String idLogin,
    required String token,
    required String idSoftskill,
    required String title,
    required String titleBahasa,
    required String dateStart,
    required String dateStop,
    required String hours,
    required String givenBy,
  }) async {
    return saveSoftskill(
      idLogin: idLogin,
      token: token,
      act: 'update',
      idSoftskill: idSoftskill,
      title: title,
      titleBahasa: titleBahasa,
      dateStart: dateStart,
      dateStop: dateStop,
      hours: hours,
      givenBy: givenBy,
    );
  }

  static Future<SkpiTransactionResult> deleteSoftskill({
    required String idLogin,
    required String token,
    required String idSoftskill,
  }) async {
    final response = await _post(
      '/skpi-transaction-softskill',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': 'delete',
        'idSoftskill': idSoftskill,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> addInternship({
    required String idLogin,
    required String token,
    required String title,
    required String titleBahasa,
    required String dateStart,
    required String dateStop,
    required String position,
    required String positionEnglish,
  }) async {
    return saveInternship(
      idLogin: idLogin,
      token: token,
      act: 'add',
      idInternship: '',
      title: title,
      titleBahasa: titleBahasa,
      dateStart: dateStart,
      dateStop: dateStop,
      position: position,
      positionEnglish: positionEnglish,
    );
  }

  static Future<SkpiTransactionResult> updateInternship({
    required String idLogin,
    required String token,
    required String idInternship,
    required String title,
    required String titleBahasa,
    required String dateStart,
    required String dateStop,
    required String position,
    required String positionEnglish,
  }) async {
    return saveInternship(
      idLogin: idLogin,
      token: token,
      act: 'update',
      idInternship: idInternship,
      title: title,
      titleBahasa: titleBahasa,
      dateStart: dateStart,
      dateStop: dateStop,
      position: position,
      positionEnglish: positionEnglish,
    );
  }

  static Future<SkpiTransactionResult> deleteInternship({
    required String idLogin,
    required String token,
    required String idInternship,
  }) async {
    final response = await _post(
      '/skpi-transaction-internship',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': 'delete',
        'idInternship': idInternship,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> saveInternship({
    required String idLogin,
    required String token,
    required String act,
    required String idInternship,
    required String title,
    required String titleBahasa,
    required String dateStart,
    required String dateStop,
    required String position,
    required String positionEnglish,
  }) async {
    final response = await _post(
      '/skpi-transaction-internship',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': act,
        'idInternship': idInternship,
        'title_internship': title,
        'title_bahasa_internship': titleBahasa,
        'datestart_internship': dateStart,
        'datestop_internship': dateStop,
        'position_internship': position,
        'position_internshipeng': positionEnglish,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> saveSoftskill({
    required String idLogin,
    required String token,
    required String act,
    required String idSoftskill,
    required String title,
    required String titleBahasa,
    required String dateStart,
    required String dateStop,
    required String hours,
    required String givenBy,
  }) async {
    final response = await _post(
      '/skpi-transaction-softskill',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': act,
        'idSoftskill': idSoftskill,
        'title_softskill': title,
        'title_bahasa_softskill': titleBahasa,
        'datestart': dateStart,
        'datestop': dateStop,
        'hours': hours,
        'given_by_softskill': givenBy,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> addOrganization({
    required String idLogin,
    required String token,
    required String title,
    required String titleBahasa,
    required String yearStart,
    required String yearStop,
    required String level,
    required String category,
    required String occupacy,
  }) async {
    return saveOrganization(
      idLogin: idLogin,
      token: token,
      act: 'add',
      idOrganization: '',
      title: title,
      titleBahasa: titleBahasa,
      yearStart: yearStart,
      yearStop: yearStop,
      level: level,
      category: category,
      occupacy: occupacy,
    );
  }

  static Future<SkpiTransactionResult> updateOrganization({
    required String idLogin,
    required String token,
    required String idOrganization,
    required String title,
    required String titleBahasa,
    required String yearStart,
    required String yearStop,
    required String level,
    required String category,
    required String occupacy,
  }) async {
    return saveOrganization(
      idLogin: idLogin,
      token: token,
      act: 'update',
      idOrganization: idOrganization,
      title: title,
      titleBahasa: titleBahasa,
      yearStart: yearStart,
      yearStop: yearStop,
      level: level,
      category: category,
      occupacy: occupacy,
    );
  }

  static Future<SkpiTransactionResult> deleteOrganization({
    required String idLogin,
    required String token,
    required String idOrganization,
  }) async {
    final response = await _post(
      '/skpi-transaction-organisasi',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': 'delete',
        'idOrganisasi': idOrganization,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> saveOrganization({
    required String idLogin,
    required String token,
    required String act,
    required String idOrganization,
    required String title,
    required String titleBahasa,
    required String yearStart,
    required String yearStop,
    required String level,
    required String category,
    required String occupacy,
  }) async {
    final response = await _post(
      '/skpi-transaction-organisasi',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': act,
        'idOrganisasi': idOrganization,
        'title_org': title,
        'title_bahasa_org': titleBahasa,
        'yearstart': yearStart,
        'yearstop': yearStop,
        'level_org': level,
        'category': category,
        'occupacy': occupacy,
      },
    );

    return SkpiTransactionResult.fromJson(response);
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
    return saveHonor(
      idLogin: idLogin,
      token: token,
      act: 'add',
      idHonor: '',
      title: title,
      titleBahasa: titleBahasa,
      dateOfHonor: dateOfHonor,
      givenBy: givenBy,
      level: level,
      field: field,
    );
  }

  static Future<SkpiTransactionResult> updateHonor({
    required String idLogin,
    required String token,
    required String idHonor,
    required String title,
    required String titleBahasa,
    required String dateOfHonor,
    required String givenBy,
    required String level,
    required String field,
  }) async {
    return saveHonor(
      idLogin: idLogin,
      token: token,
      act: 'update',
      idHonor: idHonor,
      title: title,
      titleBahasa: titleBahasa,
      dateOfHonor: dateOfHonor,
      givenBy: givenBy,
      level: level,
      field: field,
    );
  }

  static Future<SkpiTransactionResult> deleteHonor({
    required String idLogin,
    required String token,
    required String idHonor,
  }) async {
    final response = await _post(
      '/skpi-transaction-honors',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'act': 'delete',
        'idHonor': idHonor,
      },
    );

    return SkpiTransactionResult.fromJson(response);
  }

  static Future<SkpiTransactionResult> saveHonor({
    required String idLogin,
    required String token,
    required String act,
    required String idHonor,
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
        'act': act,
        'idHonor': idHonor,
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
      getInternships(idLogin: idLogin, token: token),
      getHonors(idLogin: idLogin, token: token),
    ]);

    return SkpiPageData(
      organizations: results[0] as List<SkpiOrganization>,
      languages: results[1] as List<SkpiLanguage>,
      softskills: results[2] as List<SkpiSoftskill>,
      internships: results[3] as List<SkpiInternship>,
      honors: results[4] as List<SkpiHonor>,
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
