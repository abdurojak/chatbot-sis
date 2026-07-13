class SemesterInfo {
  final String idSemesterMaster;
  final String semesterMainName;

  const SemesterInfo({
    required this.idSemesterMaster,
    required this.semesterMainName,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      idSemesterMaster: _readString(json['IdSemesterMaster']),
      semesterMainName: _readString(json['SemesterMainName']),
    );
  }
}

class KrsRequirement {
  final String id;
  final String description;
  final int status;

  const KrsRequirement({
    required this.id,
    required this.description,
    required this.status,
  });

  factory KrsRequirement.fromJson(Map<String, dynamic> json) {
    return KrsRequirement(
      id: _readString(json['req_id']),
      description: _readString(json['description']),
      status: int.tryParse(json['status'].toString()) ?? 0,
    );
  }
}

class KrsRequirementResponse {
  final List<KrsRequirement> requirements;
  final String idSemester;
  final int maxSks;

  const KrsRequirementResponse({
    required this.requirements,
    required this.idSemester,
    required this.maxSks,
  });

  factory KrsRequirementResponse.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final rawRequirements = body['requirements'] as List? ?? const [];

    return KrsRequirementResponse(
      requirements: rawRequirements
          .whereType<Map>()
          .map(
            (item) => KrsRequirement.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      idSemester: _readString(body['IdSemesterMain']),
      maxSks: int.tryParse(body['maks_sks'].toString()) ?? 0,
    );
  }
}

class KrsScheduleEntry {
  final String day;
  final String startTime;
  final String endTime;
  final String room;

  const KrsScheduleEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory KrsScheduleEntry.fromJson(Map<String, dynamic> json) {
    return KrsScheduleEntry(
      day: _readString(json['hari']),
      startTime: _readString(json['mulai']),
      endTime: _readString(json['selesai']),
      room: _readString(json['ruang']),
    );
  }

  String get startTimeShort =>
      startTime.length >= 5 ? startTime.substring(0, 5) : startTime;

  String get endTimeShort =>
      endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
}

class KrsEnrollment {
  final String idRegister;
  final String code;
  final String courseName;
  final String className;
  final String credits;
  final String approvalStatus;
  final List<KrsScheduleEntry> schedules;

  const KrsEnrollment({
    required this.idRegister,
    required this.code,
    required this.courseName,
    required this.className,
    required this.credits,
    required this.approvalStatus,
    required this.schedules,
  });

  factory KrsEnrollment.fromJson(Map<String, dynamic> json) {
    return KrsEnrollment._fromJson(json, _readScheduleEntries(json['jadwal']));
  }

  static List<KrsEnrollment> listFromJson(List<dynamic> rawItems) {
    final enrollments = <KrsEnrollment>[];
    var previousRawSchedules = <KrsScheduleEntry>[];

    for (final item in rawItems.whereType<Map>()) {
      final json = Map<String, dynamic>.from(item);
      final rawSchedules = _readScheduleEntries(json['jadwal']);
      var courseSchedules = rawSchedules;

      if (rawSchedules.length > previousRawSchedules.length &&
          _startsWithSchedules(rawSchedules, previousRawSchedules)) {
        courseSchedules = rawSchedules.sublist(previousRawSchedules.length);
      }

      enrollments.add(KrsEnrollment._fromJson(json, courseSchedules));
      previousRawSchedules = rawSchedules;
    }

    return enrollments;
  }

  static KrsEnrollment _fromJson(
    Map<String, dynamic> json,
    List<KrsScheduleEntry> schedules,
  ) {
    return KrsEnrollment(
      idRegister: _readString(json['IdRegister']),
      code: _readString(json['kodemk']),
      courseName: _readString(json['namamk']),
      className: _readString(json['namakelas']),
      credits: _readString(json['sks']),
      approvalStatus: _readString(json['persetujuan']),
      schedules: schedules,
    );
  }

  int get creditsValue => int.tryParse(credits) ?? 0;
  bool get isApproved => approvalStatus == '1';
}

class SubjectStatus {
  final String status;
  final String? msgStatus;

  const SubjectStatus({required this.status, required this.msgStatus});

  factory SubjectStatus.fromJson(Map<String, dynamic> json) {
    return SubjectStatus(
      status: _readString(json['status']),
      msgStatus: json['msg_status']?.toString(),
    );
  }
}

class Subject {
  final String idSubject;
  final String namaMk;
  final String kodeMk;
  final String sks;
  final List<SubjectStatus> status;

  const Subject({
    required this.idSubject,
    required this.namaMk,
    required this.kodeMk,
    required this.sks,
    required this.status,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      idSubject: _readString(json['IdSubject']),
      namaMk: _readString(json['namamk']),
      kodeMk: _readString(json['kodemk']),
      sks: _readString(json['sks']),
      status: (json['status'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SubjectStatus.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  bool get isAvailable =>
      !status.any((item) => item.status == '1' || item.status == '3');

  String? get statusMessage {
    for (final item in status) {
      if (item.status == '1' || item.status == '3') {
        return item.msgStatus;
      }
    }
    return null;
  }
}

class SubjectClassOption {
  final String idCourse;
  final String className;
  final int capacity;
  final int enrolled;
  final List<KrsScheduleEntry> schedules;

  const SubjectClassOption({
    required this.idCourse,
    required this.className,
    required this.capacity,
    required this.enrolled,
    required this.schedules,
  });

  factory SubjectClassOption.fromJson(Map<String, dynamic> json) {
    final rawSchedules = json['jadwal'] as List? ?? const [];

    return SubjectClassOption(
      idCourse: _readString(json['IdCourse']),
      className: _readString(json['namakelas']),
      capacity: int.tryParse(json['kapasitas'].toString()) ?? 0,
      enrolled: int.tryParse(json['terisi'].toString()) ?? 0,
      schedules: rawSchedules
          .whereType<Map>()
          .map(
            (item) =>
                KrsScheduleEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  bool get isFull => enrolled >= capacity && capacity > 0;
}

class RegisterCourseResult {
  final bool isSuccess;
  final String message;

  const RegisterCourseResult({required this.isSuccess, required this.message});

  factory RegisterCourseResult.fromJson(Map<String, dynamic> json) {
    final body = json['body'];
    final bodyMap = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    final processStatus = _readNormalizedProcessStatus(bodyMap);
    final message = _readString(
      json['message'] ??
          json['messages'] ??
          bodyMap['message'] ??
          bodyMap['messages'],
    );
    final normalizedMessage = message.toLowerCase();

    final explicitSuccess =
        processStatus == '1' ||
        processStatus == 'true' ||
        processStatus == 'success' ||
        processStatus == 'berhasil';

    final messageSuccess =
        normalizedMessage.contains('berhasil') ||
        normalizedMessage.contains('success');

    return RegisterCourseResult(
      isSuccess: explicitSuccess || messageSuccess,
      message: message,
    );
  }
}

class SendOtpResult {
  final String idOtp;

  const SendOtpResult({required this.idOtp});
}

class CancelCourseResult {
  final bool isSuccess;
  final String message;

  const CancelCourseResult({required this.isSuccess, required this.message});
}

String _readString(dynamic value) => value?.toString() ?? '';

List<KrsScheduleEntry> _readScheduleEntries(dynamic rawSchedules) {
  if (rawSchedules is Map) {
    return [KrsScheduleEntry.fromJson(Map<String, dynamic>.from(rawSchedules))];
  }

  if (rawSchedules is List) {
    return rawSchedules
        .whereType<Map>()
        .map(
          (item) => KrsScheduleEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  return const [];
}

bool _startsWithSchedules(
  List<KrsScheduleEntry> schedules,
  List<KrsScheduleEntry> prefix,
) {
  if (prefix.isEmpty) {
    return true;
  }

  if (schedules.length < prefix.length) {
    return false;
  }

  for (var index = 0; index < prefix.length; index += 1) {
    if (!_sameSchedule(schedules[index], prefix[index])) {
      return false;
    }
  }

  return true;
}

bool _sameSchedule(KrsScheduleEntry left, KrsScheduleEntry right) {
  return left.day == right.day &&
      left.startTime == right.startTime &&
      left.endTime == right.endTime &&
      left.room == right.room;
}

String _readNormalizedProcessStatus(Map<String, dynamic> body) {
  for (final entry in body.entries) {
    final normalizedKey = entry.key.toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );

    if (normalizedKey == 'statusproses' || normalizedKey == 'statusprocess') {
      return _readString(entry.value).toLowerCase();
    }
  }

  return '';
}
