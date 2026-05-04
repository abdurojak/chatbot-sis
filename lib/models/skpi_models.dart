import 'dart:convert';
import 'dart:typed_data';

class SkpiResponseData<T> {
  final List<T> items;

  const SkpiResponseData({required this.items});

  factory SkpiResponseData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) fromJson,
  ) {
    final body = json['body'];
    final bodyMap = body is Map
        ? Map<String, dynamic>.from(body)
        : <String, dynamic>{};
    final rawItems = bodyMap['data'] as List? ?? const [];

    return SkpiResponseData(
      items: rawItems
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class SkpiOrganization {
  final String id;
  final String evidenceFileId;
  final String title;
  final String titleEnglish;
  final String level;
  final String category;
  final String occupation;
  final String yearStart;
  final String yearStop;

  const SkpiOrganization({
    required this.id,
    required this.evidenceFileId,
    required this.title,
    required this.titleEnglish,
    required this.level,
    required this.category,
    required this.occupation,
    required this.yearStart,
    required this.yearStop,
  });

  factory SkpiOrganization.fromJson(Map<String, dynamic> json) {
    return SkpiOrganization(
      id: _readString(json['idOrganisasi']),
      evidenceFileId: _readString(json['idfile']),
      title: _cleanText(json['title']),
      titleEnglish: _cleanText(json['title_bahasa']),
      level: _cleanText(json['level'], fallback: '-'),
      category: _cleanText(json['category'], fallback: '-'),
      occupation: _cleanText(
        json['occupacy'] ?? json['occupation'],
        fallback: '-',
      ),
      yearStart: _readString(json['year_start']),
      yearStop: _readString(json['year_stop']),
    );
  }

  String get displayTitle => title.isNotEmpty ? title : titleEnglish;

  String get periodLabel {
    if (yearStart.isEmpty && yearStop.isEmpty) {
      return '-';
    }
    if (yearStart == yearStop || yearStop.isEmpty) {
      return yearStart;
    }
    return '$yearStart - $yearStop';
  }
}

class SkpiLanguage {
  final String id;
  final String evidenceFileId;
  final String languageCode;
  final String languageName;
  final String standardCode;
  final String standardName;
  final String score;
  final String takenDate;

  const SkpiLanguage({
    required this.id,
    required this.evidenceFileId,
    required this.languageCode,
    required this.languageName,
    required this.standardCode,
    required this.standardName,
    required this.score,
    required this.takenDate,
  });

  factory SkpiLanguage.fromJson(Map<String, dynamic> json) {
    return SkpiLanguage(
      id: _readString(json['idLanguage']),
      evidenceFileId: _readString(json['idfile']),
      languageCode: _cleanText(json['Language']),
      languageName: _cleanText(
        json['Bahasa'] ?? json['Language'],
        fallback: '-',
      ),
      standardCode: _readString(json['Standartid']),
      standardName: _cleanText(
        json['Standart'] ?? json['Language_standart'],
        fallback: '-',
      ),
      score: _readString(json['Skore'], fallback: '-'),
      takenDate: _readString(json['date_of_taken'], fallback: '-'),
    );
  }

  String get takenDateLabel => takenDate;
}

class SkpiSoftskill {
  final String id;
  final String evidenceFileId;
  final String title;
  final String titleEnglish;
  final String givenBy;
  final String hours;
  final String dateStart;
  final String dateStop;

  const SkpiSoftskill({
    required this.id,
    required this.evidenceFileId,
    required this.title,
    required this.titleEnglish,
    required this.givenBy,
    required this.hours,
    required this.dateStart,
    required this.dateStop,
  });

  factory SkpiSoftskill.fromJson(Map<String, dynamic> json) {
    return SkpiSoftskill(
      id: _readString(json['idSoftskill']),
      evidenceFileId: _readString(json['idfile']),
      title: _cleanText(json['title']),
      titleEnglish: _cleanText(json['title_bahasa']),
      givenBy: _cleanText(json['given_by'], fallback: '-'),
      hours: _readString(json['hours'], fallback: '0'),
      dateStart: _readString(json['datestart']),
      dateStop: _readString(json['datestop']),
    );
  }

  String get displayTitle => title.isNotEmpty ? title : titleEnglish;

  String get hoursLabel {
    final normalized = hours.endsWith('.00')
        ? hours.substring(0, hours.length - 3)
        : hours;
    return '$normalized jam';
  }

  String get periodLabel {
    if (dateStart.isEmpty && dateStop.isEmpty) {
      return '-';
    }
    if (dateStart == dateStop || dateStop.isEmpty) {
      return dateStart;
    }
    return '$dateStart - $dateStop';
  }
}

class SkpiInternship {
  final String id;
  final String evidenceFileId;
  final String title;
  final String titleEnglish;
  final String dateStart;
  final String dateStop;
  final String position;
  final String positionEnglish;

  const SkpiInternship({
    required this.id,
    required this.evidenceFileId,
    required this.title,
    required this.titleEnglish,
    required this.dateStart,
    required this.dateStop,
    required this.position,
    required this.positionEnglish,
  });

  factory SkpiInternship.fromJson(Map<String, dynamic> json) {
    return SkpiInternship(
      id: _readString(json['idInternship']),
      evidenceFileId: _readString(json['idfile']),
      title: _cleanText(json['title'] ?? json['title_internship']),
      titleEnglish: _cleanText(
        json['title_bahasa'] ?? json['title_bahasa_internship'],
      ),
      dateStart: _readString(json['datestart'] ?? json['datestart_internship']),
      dateStop: _readString(json['datestop'] ?? json['datestop_internship']),
      position: _cleanText(
        json['position'] ?? json['position_internship'],
        fallback: '-',
      ),
      positionEnglish: _cleanText(
        json['position_bahasa'] ??
            json['positioneng'] ??
            json['position_internshipeng'],
        fallback: '-',
      ),
    );
  }

  String get displayTitle => title.isNotEmpty ? title : titleEnglish;

  String get displayPosition => position != '-' ? position : positionEnglish;

  String get periodLabel {
    if (dateStart.isEmpty && dateStop.isEmpty) {
      return '-';
    }
    if (dateStart == dateStop || dateStop.isEmpty) {
      return dateStart;
    }
    return '$dateStart - $dateStop';
  }
}

class SkpiHonor {
  final String id;
  final String evidenceFileId;
  final String title;
  final String titleEnglish;
  final String honorDate;
  final String givenBy;
  final String field;
  final String level;

  const SkpiHonor({
    required this.id,
    required this.evidenceFileId,
    required this.title,
    required this.titleEnglish,
    required this.honorDate,
    required this.givenBy,
    required this.field,
    required this.level,
  });

  factory SkpiHonor.fromJson(Map<String, dynamic> json) {
    return SkpiHonor(
      id: _readString(json['idHonors']),
      evidenceFileId: _readString(json['idfile']),
      title: _cleanText(json['title']),
      titleEnglish: _cleanText(json['title_bahasa']),
      honorDate: _readString(json['date_of_honor'], fallback: '-'),
      givenBy: _cleanText(json['given_by'], fallback: '-'),
      field: _cleanText(json['field'], fallback: '-'),
      level: _cleanText(json['level'], fallback: '-'),
    );
  }

  String get displayTitle => title.isNotEmpty ? title : titleEnglish;

  String get honorDateLabel => honorDate;
}

class SkpiFetchedEvidence {
  final String base64Data;
  final Uint8List bytes;
  final String mime;
  final String fileName;

  const SkpiFetchedEvidence({
    required this.base64Data,
    required this.bytes,
    required this.mime,
    required this.fileName,
  });

  factory SkpiFetchedEvidence.fromBase64(
    String rawBase64, {
    String fallbackName = 'Evidence',
  }) {
    final sanitized = rawBase64.contains(',')
        ? rawBase64.substring(rawBase64.indexOf(',') + 1)
        : rawBase64;
    final bytes = base64Decode(sanitized);
    final mime = _detectMime(bytes);
    final extension = _extensionForMime(mime);

    return SkpiFetchedEvidence(
      base64Data: sanitized,
      bytes: bytes,
      mime: mime,
      fileName: extension.isEmpty ? fallbackName : '$fallbackName.$extension',
    );
  }

  bool get isPdf => mime.contains('pdf');

  bool get isImage => mime.startsWith('image/');
}

class SkpiReferenceOption {
  final String key;
  final String value;
  final String idDefType;

  const SkpiReferenceOption({
    required this.key,
    required this.value,
    required this.idDefType,
  });

  factory SkpiReferenceOption.fromJson(Map<String, dynamic> json) {
    return SkpiReferenceOption(
      key: _readString(json['key']),
      value: _cleanText(json['value'], fallback: '-'),
      idDefType: _readString(json['idDefType']),
    );
  }
}

class SkpiHonorReferenceData {
  final List<SkpiReferenceOption> levels;
  final List<SkpiReferenceOption> fields;

  const SkpiHonorReferenceData({required this.levels, required this.fields});

  factory SkpiHonorReferenceData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final rawLevels = data['level'] as List? ?? const [];
    final rawFields = data['field'] as List? ?? const [];

    return SkpiHonorReferenceData(
      levels: rawLevels
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      fields: rawFields
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class SkpiOrganizationReferenceData {
  final List<SkpiReferenceOption> levels;
  final List<SkpiReferenceOption> occupacies;
  final List<SkpiReferenceOption> categories;
  final List<String> years;

  const SkpiOrganizationReferenceData({
    required this.levels,
    required this.occupacies,
    required this.categories,
    required this.years,
  });

  factory SkpiOrganizationReferenceData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final rawLevels = data['level'] as List? ?? const [];
    final rawOccupacies = data['occupacy'] as List? ?? const [];
    final rawCategories = data['category'] as List? ?? const [];
    final rawYears = data['year'] as List? ?? const [];

    return SkpiOrganizationReferenceData(
      levels: rawLevels
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      occupacies: rawOccupacies
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      categories: rawCategories
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      years: rawYears
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class SkpiLanguageReferenceData {
  final List<SkpiReferenceOption> languages;
  final List<SkpiReferenceOption> standards;

  const SkpiLanguageReferenceData({
    required this.languages,
    required this.standards,
  });

  factory SkpiLanguageReferenceData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final rawLanguages = data['language'] as List? ?? const [];
    final rawStandards = data['standar'] as List? ?? const [];

    return SkpiLanguageReferenceData(
      languages: rawLanguages
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      standards: rawStandards
          .whereType<Map>()
          .map(
            (item) =>
                SkpiReferenceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class SkpiTransactionResult {
  final String id;
  final String message;

  const SkpiTransactionResult({required this.id, required this.message});

  factory SkpiTransactionResult.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'];

    if (data is String) {
      return SkpiTransactionResult(id: '', message: _cleanText(data));
    }

    final dataMap = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};

    return SkpiTransactionResult(
      id: _readString(dataMap['id']),
      message: _cleanText(dataMap['pesan'], fallback: 'Transaksi berhasil'),
    );
  }
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
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }
  return text;
}

String _cleanText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }
  return text;
}
