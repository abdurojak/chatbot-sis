class Subject {
  final String idSubject;
  final String namaMk;
  final String kodeMk;
  final String sks;
  final List<SubjectStatus> status;

  Subject({
    required this.idSubject,
    required this.namaMk,
    required this.kodeMk,
    required this.sks,
    required this.status,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      idSubject: json['IdSubject'] ?? '',
      namaMk: json['namamk'] ?? '',
      kodeMk: json['kodemk'] ?? '',
      sks: json['sks'] ?? '0',
      status: (json['status'] as List? ?? [])
          .map((e) => SubjectStatus.fromJson(e))
          .toList(),
    );
  }

  /// TRUE kalau boleh diambil
  bool get isAvailable =>
      !status.any((e) => e.status == "1" || e.status == "3");

  /// Ambil pesan status (Prasyarat / Kelas Penuh)
  String? get statusMessage {
    final s = status.firstWhere(
      (e) => e.status == "1" || e.status == "3",
      orElse: () => SubjectStatus(status: "2", msgStatus: null),
    );

    return s.msgStatus;
  }
}

class SubjectStatus {
  final String status;
  final String? msgStatus;

  SubjectStatus({required this.status, required this.msgStatus});

  factory SubjectStatus.fromJson(Map<String, dynamic> json) {
    return SubjectStatus(
      status: json['status'] ?? '',
      msgStatus: json['msg_status'],
    );
  }
}
