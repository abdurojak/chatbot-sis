import 'dart:convert';

import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:http/http.dart' as http;

class MbkmService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<MbkmResponseData> getMbkm({
    required String idLogin,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get-mbkm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdLogin': idLogin, 'token': token}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MbkmResponseData.fromJson(json);
  }

  static Future<String> addCompetency({
    required String idLogin,
    required String token,
    required String competency,
    required String learningSource,
    required String assessmentModel,
    required String learningExperience,
    required String durationInHour,
    required String idMaCompetency,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-add-competency'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'competency': competency,
        'learning_source': learningSource,
        'assessment_model': assessmentModel,
        'learning_experience': learningExperience,
        'duration_in_hour': durationInHour,
        'id_ma_competency': idMaCompetency,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Kompetensi berhasil ditambahkan';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<List<MbkmLogEntry>> getMbkmLog({
    required String idLogin,
    required String token,
    required String idMa,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-get-log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdLogin': idLogin, 'token': token, 'id_ma': idMa}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
        json['message']?.toString() ??
            json['status']?.toString() ??
            'Gagal mengambil log MBKM',
      );
    }

    return ((json['body']?['data'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => MbkmLogEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<String> saveMbkmLog({
    required String idLogin,
    required String token,
    required String startDate,
    required String endDate,
    required String activity,
    required String evaluation,
    required String action,
    required String mentorRemark,
    required String idMa,
    String? idLog,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'dt_mulai': startDate,
        'dt_selesai': endDate,
        'aktivitas': activity,
        'evaluasi': evaluation,
        'tindakan': action,
        'remark_mentor': mentorRemark,
        'id_ma': idMa,
        'id_log': idLog,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Log MBKM berhasil disimpan';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<String> uploadLogEvidence({
    required String idLogin,
    required String token,
    required String idLog,
    required String remark,
    required String mime,
    required String base64Data,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-log-evidence'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'id_log': idLog,
        'remark': remark,
        'file': {'mime': mime, 'data': base64Data},
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Bukti berhasil diunggah';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<MbkmExchangeCourseData> getExchangeCourses({
    required String idLogin,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-get-courses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdLogin': idLogin, 'token': token}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
        json['message']?.toString() ??
            json['status']?.toString() ??
            'Gagal mengambil data pertukaran mahasiswa',
      );
    }

    return MbkmExchangeCourseData.fromJson(json);
  }

  static Future<String> getActiveSemesterId({
    required String idLogin,
    required String token,
  }) async {
    final requirement = await KrsService.getRequirements(
      idLogin: idLogin,
      token: token,
    );
    return requirement.idSemester;
  }

  static Future<String> saveExchangeCourse({
    required String idLogin,
    required String token,
    required String outbound,
    required String idSemesterMain,
    required List<String> kelas,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-save-courses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'outbound': outbound,
        'IdSemesterMain': idSemesterMain,
        'kelas': kelas,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Mata kuliah berhasil diajukan';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<String> deleteExchangeCourse({
    required String idLogin,
    required String token,
    required String outbound,
    required String idSemesterMain,
    required List<String> kelas,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-delete-courses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'outbound': outbound,
        'IdSemesterMain': idSemesterMain,
        'kelas': kelas,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Mata kuliah berhasil dihapus';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
  }

  static Future<List<MbkmPartnerOption>> getPartners({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/get-partner',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return ((response['body']?['data'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => MbkmPartnerOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<List<MbkmActivityTypeOption>> getActivityTypes({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/get-jenis-mbkm',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return ((response['body']?['data'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              MbkmActivityTypeOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<List<MbkmCompanyScaleOption>> getCompanyScales({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/get-company-scale',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return ((response['body']?['data'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              MbkmCompanyScaleOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<MbkmApplyFormData> getApplyFormData({
    required String idLogin,
    required String token,
  }) async {
    final results = await Future.wait([
      getPartners(idLogin: idLogin, token: token),
      getActivityTypes(idLogin: idLogin, token: token),
      getCompanyScales(idLogin: idLogin, token: token),
      KrsService.getRequirements(idLogin: idLogin, token: token),
    ]);

    return MbkmApplyFormData(
      partners: results[0] as List<MbkmPartnerOption>,
      activityTypes: results[1] as List<MbkmActivityTypeOption>,
      scales: results[2] as List<MbkmCompanyScaleOption>,
      idSemester: (results[3] as dynamic).idSemester as String,
    );
  }

  static Future<String> applyMbkm({
    required String idLogin,
    required String token,
    required String idSemester,
    required String activityTypeId,
    required String partner,
    required String title,
    required String companyName,
    required String description,
    required String moreInfo,
    required String companyType,
    required String scale,
    required String numberOfEmployees,
    required String dateStart,
    required String dateEnd,
    required String dateSelection,
    required String dateResult,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mbkm-apply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdLogin': idLogin,
        'token': token,
        'IdSemester': idSemester,
        'jns_aktivitas': activityTypeId,
        'partner': partner,
        'title': title,
        'company_name': companyName,
        'description': description,
        'more_info': moreInfo,
        'company_type': companyType,
        'skala': scale,
        'n_of_employee': numberOfEmployees,
        'date_start': dateStart,
        'date_end': dateEnd,
        'date_selection': dateSelection,
        'date_result': dateResult,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        json['message']?.toString() ??
        json['status']?.toString() ??
        'Pengajuan MBKM berhasil dikirim';

    if (response.statusCode != 200) {
      throw Exception(message);
    }

    return message;
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
