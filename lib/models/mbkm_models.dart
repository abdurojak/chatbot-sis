import 'dart:convert';
import 'dart:typed_data';

class MbkmBiodata {
  final String name;
  final String nim;

  const MbkmBiodata({required this.name, required this.nim});

  factory MbkmBiodata.fromJson(Map<String, dynamic> json) {
    return MbkmBiodata(
      name: _readString(json['name'], fallback: '-'),
      nim: _readString(json['nim'], fallback: '-'),
    );
  }
}

class MbkmCompetency {
  final String competency;
  final String learningSource;
  final String assessmentModel;
  final String learningExperience;
  final String durationInHour;

  const MbkmCompetency({
    required this.competency,
    required this.learningSource,
    required this.assessmentModel,
    required this.learningExperience,
    required this.durationInHour,
  });

  factory MbkmCompetency.fromJson(Map<String, dynamic> json) {
    return MbkmCompetency(
      competency: _readString(json['competency'], fallback: '-'),
      learningSource: _readString(json['learning_source'], fallback: '-'),
      assessmentModel: _readString(json['assessment_model'], fallback: '-'),
      learningExperience: _readString(
        json['learning_experience'],
        fallback: '-',
      ),
      durationInHour: _readString(json['duration_in_hour'], fallback: '0'),
    );
  }
}

class MbkmApplication {
  final String idApplication;
  final String title;
  final String companyName;
  final String semesterName;
  final String activityType;
  final String scaleName;
  final String description;
  final String moreInfoUrl;
  final String startDate;
  final String endDate;
  final String selectionDate;
  final String resultDate;
  final String internalMentorName;
  final List<MbkmCompetency> competencies;

  const MbkmApplication({
    required this.idApplication,
    required this.title,
    required this.companyName,
    required this.semesterName,
    required this.activityType,
    required this.scaleName,
    required this.description,
    required this.moreInfoUrl,
    required this.startDate,
    required this.endDate,
    required this.selectionDate,
    required this.resultDate,
    required this.internalMentorName,
    required this.competencies,
  });

  factory MbkmApplication.fromJson(Map<String, dynamic> json) {
    final rawCompetencies = json['competency'] as List? ?? const [];

    return MbkmApplication(
      idApplication: _readString(json['id_ma']),
      title: _readString(json['title'], fallback: '-'),
      companyName: _readString(json['company_name'], fallback: '-'),
      semesterName: _readString(json['SemesterMainName'], fallback: '-'),
      activityType: _readString(json['jenis_aktivitas'], fallback: '-'),
      scaleName: _readString(json['skalaname'], fallback: '-'),
      description: _readString(json['description'], fallback: '-'),
      moreInfoUrl: _readString(json['more_info']),
      startDate: _readString(json['date_start'], fallback: '-'),
      endDate: _readString(json['date_end'], fallback: '-'),
      selectionDate: _readString(json['date_selection'], fallback: '-'),
      resultDate: _readString(json['date_result'], fallback: '-'),
      internalMentorName: _readString(
        json['mentor_internal_name'],
        fallback: '-',
      ),
      competencies: rawCompetencies
          .whereType<Map>()
          .map(
            (item) => MbkmCompetency.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  bool get hasMoreInfo => moreInfoUrl.isNotEmpty;
}

class MbkmResponseData {
  final MbkmBiodata biodata;
  final List<MbkmApplication> applications;

  const MbkmResponseData({required this.biodata, required this.applications});

  factory MbkmResponseData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final rawApplications = data['application'] as List? ?? const [];

    return MbkmResponseData(
      biodata: MbkmBiodata.fromJson(
        Map<String, dynamic>.from(
          data['biodata'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      applications: rawApplications
          .whereType<Map>()
          .map(
            (item) => MbkmApplication.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class MbkmPartnerOption {
  final String id;
  final String label;
  final String address;
  final String field;
  final String scaleKey;
  final String companyType;
  final String numberOfEmployees;
  final String website;
  final String contactPerson;
  final String email;
  final String phone;

  const MbkmPartnerOption({
    required this.id,
    required this.label,
    required this.address,
    required this.field,
    required this.scaleKey,
    required this.companyType,
    required this.numberOfEmployees,
    required this.website,
    required this.contactPerson,
    required this.email,
    required this.phone,
  });

  factory MbkmPartnerOption.fromJson(Map<String, dynamic> json) {
    final id = _readString(
      json['partner'] ??
          json['id_partner'] ??
          json['id_mm'] ??
          json['id'] ??
          json['key'],
    );
    final label = _readString(
      json['partner_name'] ??
          json['name'] ??
          json['label'] ??
          json['value'] ??
          json['company_name'],
      fallback: id.isEmpty ? '-' : id,
    );

    return MbkmPartnerOption(
      id: id,
      label: label,
      address: _readString(json['address'], fallback: '-'),
      field: _readString(json['bidang'], fallback: '-'),
      scaleKey: _readString(json['skala']),
      companyType: _readString(json['company_type']),
      numberOfEmployees: _readString(json['n_of_employee']),
      website: _readString(json['web_site']),
      contactPerson: _readString(json['contact_person'], fallback: '-'),
      email: _readString(json['email'], fallback: '-'),
      phone: _readString(json['phone'], fallback: '-'),
    );
  }

  bool get hasWebsite => website.isNotEmpty;
}

class MbkmActivityTypeOption {
  final String id;
  final String name;
  final String shortName;

  const MbkmActivityTypeOption({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory MbkmActivityTypeOption.fromJson(Map<String, dynamic> json) {
    return MbkmActivityTypeOption(
      id: _readString(json['id_jns_akt_mhs']),
      name: _readString(json['nm_jns_akt_mhs'], fallback: '-'),
      shortName: _readString(json['ShortName'], fallback: '-'),
    );
  }
}

class MbkmCompanyScaleOption {
  final String key;
  final String value;

  const MbkmCompanyScaleOption({required this.key, required this.value});

  factory MbkmCompanyScaleOption.fromJson(Map<String, dynamic> json) {
    return MbkmCompanyScaleOption(
      key: _readString(json['key']),
      value: _readString(json['value'], fallback: '-'),
    );
  }
}

class MbkmApplyFormData {
  final String idSemester;
  final List<MbkmPartnerOption> partners;
  final List<MbkmActivityTypeOption> activityTypes;
  final List<MbkmCompanyScaleOption> scales;

  const MbkmApplyFormData({
    required this.idSemester,
    required this.partners,
    required this.activityTypes,
    required this.scales,
  });
}

class MbkmExchangeCourseData {
  final List<MbkmExchangeCourse> internalCourses;
  final List<MbkmExchangeCourse> externalCourses;
  final List<MbkmExchangeAppliedCourse> appliedCourses;
  final String message;

  const MbkmExchangeCourseData({
    required this.internalCourses,
    required this.externalCourses,
    required this.appliedCourses,
    this.message = '',
  });

  bool get isUnavailable =>
      message.isNotEmpty &&
      internalCourses.isEmpty &&
      externalCourses.isEmpty &&
      appliedCourses.isEmpty;

  factory MbkmExchangeCourseData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final message = _readString(body['message']);
    final rawData = body['data'];
    final data = rawData is Map<String, dynamic> ? rawData : const {};

    return MbkmExchangeCourseData(
      message: message,
      internalCourses: ((data['internal'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                MbkmExchangeCourse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      externalCourses: ((data['external'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                MbkmExchangeCourse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      appliedCourses: ((data['subjectapplied'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => MbkmExchangeAppliedCourse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class MbkmExchangeCourse {
  final String idCourseTaggingGroup;
  final String idSubject;
  final String groupCode;
  final String lecturerId;
  final String day;
  final String startTime;
  final String endTime;
  final String programName;
  final String subjectCode;
  final String subjectName;
  final String creditHours;
  final int appliedCount;
  final String approval;
  final String isIn;
  final String lecturer;

  const MbkmExchangeCourse({
    required this.idCourseTaggingGroup,
    required this.idSubject,
    required this.groupCode,
    required this.lecturerId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.programName,
    required this.subjectCode,
    required this.subjectName,
    required this.creditHours,
    required this.appliedCount,
    required this.approval,
    required this.isIn,
    required this.lecturer,
  });

  factory MbkmExchangeCourse.fromJson(Map<String, dynamic> json) {
    return MbkmExchangeCourse(
      idCourseTaggingGroup: _readString(json['IdCourseTaggingGroup']),
      idSubject: _readString(json['IdSubject']),
      groupCode: _readString(json['GroupCode'], fallback: '-'),
      lecturerId: _readString(json['IdLecturer']),
      day: _readString(json['sc_day'], fallback: '-'),
      startTime: _normalizeTime(
        _readString(json['sc_start_time'], fallback: '-'),
      ),
      endTime: _normalizeTime(_readString(json['sc_end_time'], fallback: '-')),
      programName: _readString(json['programname'], fallback: '-'),
      subjectCode: _readString(
        json['SubCode'] ?? json['subject_code'],
        fallback: '-',
      ),
      subjectName: _readString(
        json['SubjectName'] ?? json['subject_name'],
        fallback: '-',
      ),
      creditHours: _readString(json['CreditHours'], fallback: '0'),
      appliedCount: int.tryParse(_readString(json['jml'], fallback: '0')) ?? 0,
      approval: _readString(json['approval'], fallback: '0'),
      isIn: _readString(json['isin'], fallback: '0'),
      lecturer: _readString(json['lecturer'], fallback: '-'),
    );
  }

  String get scheduleLabel => '$day • $startTime - $endTime';
}

class MbkmExchangeAppliedCourse extends MbkmExchangeCourse {
  final String idMa;
  final String approvalStatus;
  final String status;
  final String remark;
  final String semesterId;

  const MbkmExchangeAppliedCourse({
    required super.idCourseTaggingGroup,
    required super.idSubject,
    required super.groupCode,
    required super.lecturerId,
    required super.day,
    required super.startTime,
    required super.endTime,
    required super.programName,
    required super.subjectCode,
    required super.subjectName,
    required super.creditHours,
    required super.appliedCount,
    required super.approval,
    required super.isIn,
    required super.lecturer,
    required this.idMa,
    required this.approvalStatus,
    required this.status,
    required this.remark,
    required this.semesterId,
  });

  factory MbkmExchangeAppliedCourse.fromJson(Map<String, dynamic> json) {
    final base = MbkmExchangeCourse.fromJson(json);
    return MbkmExchangeAppliedCourse(
      idCourseTaggingGroup: base.idCourseTaggingGroup,
      idSubject: base.idSubject,
      groupCode: base.groupCode,
      lecturerId: base.lecturerId,
      day: base.day,
      startTime: base.startTime,
      endTime: base.endTime,
      programName: base.programName,
      subjectCode: base.subjectCode,
      subjectName: base.subjectName,
      creditHours: base.creditHours,
      appliedCount: base.appliedCount,
      approval: base.approval,
      isIn: base.isIn,
      lecturer: base.lecturer,
      idMa: _readString(json['id_ma']),
      approvalStatus: _readString(json['approval_status'], fallback: '-'),
      status: _readString(json['status'], fallback: '-'),
      remark: _readString(json['remark'], fallback: '-'),
      semesterId: _readString(json['IdSemester'] ?? json['idsemester']),
    );
  }

  bool get canDelete {
    final approvalText = approvalStatus.toLowerCase();
    final statusText = status.toLowerCase();
    return approvalText.contains('not approved yet') ||
        approvalText == '0' ||
        statusText.contains('not approved yet');
  }
}

class MbkmLogEntry {
  final String idLog;
  final String startDate;
  final String endDate;
  final String activity;
  final String evaluation;
  final String action;
  final String mentorRemark;
  final String entryDate;
  final String approvalStatus;
  final String idMa;
  final List<MbkmLogEvidence> evidences;

  const MbkmLogEntry({
    required this.idLog,
    required this.startDate,
    required this.endDate,
    required this.activity,
    required this.evaluation,
    required this.action,
    required this.mentorRemark,
    required this.entryDate,
    required this.approvalStatus,
    required this.idMa,
    required this.evidences,
  });

  factory MbkmLogEntry.fromJson(Map<String, dynamic> json) {
    final rawEvidences = json['bukti'] as List? ?? const [];

    return MbkmLogEntry(
      idLog: _readString(json['id_log']),
      startDate: _readString(json['dt_mulai'], fallback: '-'),
      endDate: _readString(json['dt_selesai'], fallback: '-'),
      activity: _readString(json['aktivitas'], fallback: '-'),
      evaluation: _readString(json['evaluasi'], fallback: '-'),
      action: _readString(json['tindakan'], fallback: '-'),
      mentorRemark: _readString(json['remark_mentor'], fallback: '-'),
      entryDate: _readString(json['dt_entry'], fallback: '-'),
      approvalStatus: _readString(json['approval_status'], fallback: '-'),
      idMa: _readString(json['id_ma']),
      evidences: rawEvidences
          .whereType<Map>()
          .map(
            (item) => MbkmLogEvidence.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  int get evidenceCount => evidences.length;
}

class MbkmLogEvidence {
  final String idFile;
  final String remark;
  final String fileName;

  const MbkmLogEvidence({
    required this.idFile,
    required this.remark,
    required this.fileName,
  });

  factory MbkmLogEvidence.fromJson(Map<String, dynamic> json) {
    final idFile = _readString(json['idfile'] ?? json['id_file']);
    return MbkmLogEvidence(
      idFile: idFile,
      remark: _readString(
        json['remark'] ?? json['keterangan'] ?? json['description'],
        fallback: '-',
      ),
      fileName: _readString(
        json['file_name'] ?? json['filename'] ?? json['name'],
        fallback: idFile.isEmpty ? 'Bukti' : 'Bukti #$idFile',
      ),
    );
  }
}

class MbkmFetchedEvidence {
  final String base64Data;
  final Uint8List bytes;
  final String mime;
  final String fileName;

  const MbkmFetchedEvidence({
    required this.base64Data,
    required this.bytes,
    required this.mime,
    required this.fileName,
  });

  factory MbkmFetchedEvidence.fromBase64(
    String rawBase64, {
    String fallbackName = 'Bukti',
  }) {
    final sanitized = rawBase64.contains(',')
        ? rawBase64.substring(rawBase64.indexOf(',') + 1)
        : rawBase64;
    final bytes = base64Decode(sanitized);
    final mime = _detectMime(bytes);
    final extension = _extensionForMime(mime);

    return MbkmFetchedEvidence(
      base64Data: sanitized,
      bytes: bytes,
      mime: mime,
      fileName: extension.isEmpty ? fallbackName : '$fallbackName.$extension',
    );
  }

  bool get isPdf => mime.contains('pdf');

  bool get isImage => mime.startsWith('image/');
}

String _detectMime(Uint8List bytes) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46) {
    return 'application/pdf';
  }

  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }

  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }

  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }

  return 'application/octet-stream';
}

String _extensionForMime(String mime) {
  switch (mime) {
    case 'application/pdf':
      return 'pdf';
    case 'image/png':
      return 'png';
    case 'image/jpeg':
      return 'jpg';
    case 'image/webp':
      return 'webp';
    default:
      return '';
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

String _normalizeTime(String value) {
  if (value == '-' || value.isEmpty) {
    return value;
  }

  final compact = value.replaceAll(' ', '');
  final match = RegExp(r'^(\d{2}):(\d{2})(?::\d{2})?$').firstMatch(compact);
  if (match == null) {
    return compact;
  }

  return '${match.group(1)}:${match.group(2)}';
}
