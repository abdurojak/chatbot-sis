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
  final int evidenceCount;

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
    required this.evidenceCount,
  });

  factory MbkmLogEntry.fromJson(Map<String, dynamic> json) {
    final evidences = json['bukti'] as List? ?? const [];

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
      evidenceCount: evidences.length,
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}
