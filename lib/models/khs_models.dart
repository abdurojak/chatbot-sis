import 'package:chatbot/models/krs_models.dart';

class KhsPerformance {
  final String ips;
  final String ipk;
  final String sksSemester;
  final String sksLulus;

  const KhsPerformance({
    required this.ips,
    required this.ipk,
    required this.sksSemester,
    required this.sksLulus,
  });

  factory KhsPerformance.fromJson(Map<String, dynamic> json) {
    return KhsPerformance(
      ips: _readString(json['ips'], fallback: '0.00'),
      ipk: _readString(json['ipk'], fallback: '0.00'),
      sksSemester: _readString(json['sks_sem'], fallback: '0'),
      sksLulus: _readString(json['sks_lulus'], fallback: '0'),
    );
  }
}

class KhsCourseDetail {
  final String courseName;
  final String courseCode;
  final String className;
  final String credits;
  final String gradeLetter;
  final String gradePoint;
  final String passStatus;

  const KhsCourseDetail({
    required this.courseName,
    required this.courseCode,
    required this.className,
    required this.credits,
    required this.gradeLetter,
    required this.gradePoint,
    required this.passStatus,
  });

  factory KhsCourseDetail.fromJson(Map<String, dynamic> json) {
    return KhsCourseDetail(
      courseName: _readString(json['namamk']),
      courseCode: _readString(json['kodemk']),
      className: _readString(json['namakelas']),
      credits: _readString(json['sks'], fallback: '0'),
      gradeLetter: _readString(json['nilai'], fallback: '-'),
      gradePoint: _readString(json['nilai_angka'], fallback: '-'),
      passStatus: _readString(json['pass'], fallback: 'N/A'),
    );
  }

  bool get isPassed => passStatus.toLowerCase() == 'pass';
}

class KhsResponseData {
  final KhsPerformance performance;
  final List<KhsCourseDetail> details;

  const KhsResponseData({required this.performance, required this.details});

  factory KhsResponseData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final rawDetails = body['detail'] as List? ?? const [];

    return KhsResponseData(
      performance: KhsPerformance.fromJson(
        Map<String, dynamic>.from(
          body['kinerja'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      details: rawDetails
          .whereType<Map>()
          .map(
            (item) => KhsCourseDetail.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class KhsPageData {
  final String? defaultSemesterId;
  final List<SemesterInfo> semesters;
  final KhsResponseData khs;

  const KhsPageData({
    required this.defaultSemesterId,
    required this.semesters,
    required this.khs,
  });
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return fallback;
  }
  return text;
}
