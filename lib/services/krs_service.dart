import 'dart:convert';

import 'package:chatbot/models/krs_models.dart';
import 'package:http/http.dart' as http;

class KrsService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<KrsRequirementResponse> getRequirements({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/krs-requirement',
      body: {'IdLogin': idLogin, 'token': token},
    );
    return KrsRequirementResponse.fromJson(response);
  }

  static Future<List<SemesterInfo>> getSemesters({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/get-semester',
      body: {'IdLogin': idLogin, 'token': token},
    );

    return ((response['body']?['semester'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => SemesterInfo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<KrsEnrollment>> getKrs({
    required String idLogin,
    required String token,
    required String idSemester,
  }) async {
    final response = await _post(
      '/get-krs',
      body: {'IdLogin': idLogin, 'token': token, 'IdSemester': idSemester},
    );

    return KrsEnrollment.listFromJson(
      (response['body']?['kelas'] as List?) ?? const [],
    );
  }

  static Future<List<Subject>> getSubjects({
    required String idLogin,
    required String token,
    required String idSemester,
    int level = 0,
  }) async {
    final response = await _post(
      '/subject',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'IdSemester': idSemester,
        'level': level,
      },
    );

    return ((response['body']?['subjects'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Subject.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<SubjectClassOption>> getCourseSchedules({
    required String idLogin,
    required String token,
    required String idSemester,
    required String idSubject,
  }) async {
    final response = await _post(
      '/course-schedule',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'IdSemester': idSemester,
        'IdSubject': idSubject,
      },
    );

    final bodyList = response['body'] as List? ?? const [];
    if (bodyList.isEmpty || bodyList.first is! Map) {
      return const [];
    }

    final firstMap = Map<String, dynamic>.from(bodyList.first as Map);
    final results = <SubjectClassOption>[];
    for (final entry in firstMap.entries) {
      final value = entry.value;
      if (value is Map) {
        results.add(
          SubjectClassOption.fromJson(Map<String, dynamic>.from(value)),
        );
      }
    }

    return results;
  }

  static Future<RegisterCourseResult> registerCourse({
    required String idLogin,
    required String token,
    required String idCourse,
    required int maxSks,
  }) async {
    final response = await _post(
      '/register',
      body: {
        'token': token,
        'IdLogin': idLogin,
        'IdCourse': idCourse,
        'sksmaks': maxSks.toString(),
      },
    );

    final isSuccess = response['body']?['status proses'] == '1';
    return RegisterCourseResult(
      isSuccess: isSuccess,
      message: (response['message'] ?? response['status'] ?? '').toString(),
    );
  }

  static Future<SendOtpResult?> sendOtp({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/send-otp',
      body: {'IdLogin': idLogin, 'token': token},
    );

    final idOtp = response['body']?['id_otp']?.toString();
    if (idOtp == null || idOtp.isEmpty) {
      return null;
    }

    return SendOtpResult(idOtp: idOtp);
  }

  static Future<CancelCourseResult> cancelCourses({
    required String idLogin,
    required String token,
    required String otp,
    required String idOtp,
    required List<String> courses,
  }) async {
    final response = await _post(
      '/cancel-course',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'otp': otp,
        'id_otp': idOtp,
        'courses': courses,
      },
    );

    final isSuccess = response['status'] == 200 || response['body'] != null;
    return CancelCourseResult(
      isSuccess: isSuccess,
      message: (response['message'] ?? '').toString(),
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

    return json.decode(response.body) as Map<String, dynamic>;
  }
}
