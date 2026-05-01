class ConvocationResponse {
  final ConvocationData data;

  const ConvocationResponse({required this.data});

  factory ConvocationResponse.fromJson(Map<String, dynamic> json) {
    final body = json['body'];
    final bodyMap = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    final data = bodyMap['data'];
    final dataMap = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    return ConvocationResponse(data: ConvocationData.fromJson(dataMap));
  }
}

class ConvocationData {
  final String infoWisudaText;
  final ConvocationInfoWisuda? infoWisuda;
  final String yudisiumStatus;
  final String yudisiumDate;
  final String yudisiumPredicate;
  final String yudisiumIpk;
  final ConvocationApplicationSnapshot? applicationSnapshot;
  final dynamic aplikasi;
  final dynamic tagihan;
  final dynamic unggahPendamping;
  final dynamic buatUndangan;

  const ConvocationData({
    required this.infoWisudaText,
    required this.infoWisuda,
    required this.yudisiumStatus,
    required this.yudisiumDate,
    required this.yudisiumPredicate,
    required this.yudisiumIpk,
    required this.applicationSnapshot,
    required this.aplikasi,
    required this.tagihan,
    required this.unggahPendamping,
    required this.buatUndangan,
  });

  factory ConvocationData.fromJson(Map<String, dynamic> json) {
    final yudisium = json['Yudisium'];
    final yudisiumMap = yudisium is Map
        ? Map<String, dynamic>.from(yudisium)
        : const <String, dynamic>{};

    final infoWisudaRaw = json['InfoWisuda'];
    final infoWisudaMap = infoWisudaRaw is Map
        ? Map<String, dynamic>.from(infoWisudaRaw)
        : null;

    final aplikasiRaw = json['Aplikasi'];
    final aplikasiMap = aplikasiRaw is Map
        ? Map<String, dynamic>.from(aplikasiRaw)
        : null;

    return ConvocationData(
      infoWisudaText: infoWisudaRaw is String
          ? infoWisudaRaw
          : (infoWisudaRaw?.toString() ?? ''),
      infoWisuda: infoWisudaMap == null
          ? null
          : ConvocationInfoWisuda.fromJson(infoWisudaMap),
      yudisiumStatus: _resolveYudisiumStatus(yudisiumMap),
      yudisiumDate: yudisiumMap['tanggal']?.toString() ?? '',
      yudisiumPredicate: yudisiumMap['predikat']?.toString() ?? '',
      yudisiumIpk: yudisiumMap['ipk']?.toString() ?? '',
      applicationSnapshot: aplikasiMap == null
          ? null
          : ConvocationApplicationSnapshot.fromJson(aplikasiMap),
      aplikasi: aplikasiRaw,
      tagihan: json['Tagihan'],
      unggahPendamping: json['UnggahPendamping'],
      buatUndangan: json['BuatUndangan'],
    );
  }

  bool get hasInfoWisuda =>
      infoWisudaText.trim().isNotEmpty || infoWisuda != null;
  bool get hasApplication => _hasValue(aplikasi);
  bool get hasInvoice => _hasValue(tagihan);
  bool get hasCompanionUpload => _hasValue(unggahPendamping);
  bool get hasInvitation => _hasValue(buatUndangan);
  bool get hasYudisiumDetails =>
      yudisiumDate.trim().isNotEmpty ||
      yudisiumPredicate.trim().isNotEmpty ||
      yudisiumIpk.trim().isNotEmpty;

  bool get isYudisiumDone {
    final normalized = yudisiumStatus.trim().toLowerCase();
    if (normalized.isNotEmpty && normalized != 'belum yudisium') {
      return true;
    }
    return hasYudisiumDetails;
  }

  bool get canApply => isYudisiumDone && !hasApplication;
  bool get canCreateInvitation =>
      isYudisiumDone && hasApplication && hasInvoice;

  String get companionConvoId {
    final fromInvitation = _readNestedString(buatUndangan, 'c_id');
    if (fromInvitation.isNotEmpty) return fromInvitation;
    return _readFirstListItemString(unggahPendamping, 'c_id');
  }

  String get companionInvitationId {
    final fromInvitation = _readNestedString(buatUndangan, 'id_ci');
    if (fromInvitation.isNotEmpty) return fromInvitation;
    return _readFirstListItemString(unggahPendamping, 'id_ci');
  }

  String get displayInfoWisudaText {
    if (infoWisudaText.trim().isNotEmpty) {
      return infoWisudaText;
    }
    if (infoWisuda == null) {
      return '';
    }
    final parts = <String>[
      if (infoWisuda!.academicYear.isNotEmpty) infoWisuda!.academicYear,
      if (infoWisuda!.semester.isNotEmpty) infoWisuda!.semester,
      if (infoWisuda!.startRegistration.isNotEmpty &&
          infoWisuda!.endRegistration.isNotEmpty)
        'Pendaftaran ${infoWisuda!.startRegistration} - ${infoWisuda!.endRegistration}',
      if (infoWisuda!.paymentDeadline.isNotEmpty)
        'Batas bayar ${infoWisuda!.paymentDeadline}',
    ];
    return parts.join(' | ');
  }

  List<ConvocationStep> buildSteps() {
    final stepDoneFlags = <bool>[
      isYudisiumDone,
      hasApplication,
      hasInvoice,
      hasCompanionUpload,
      hasInvitation,
    ];

    const titles = <String>[
      'Yudisium',
      'Aplikasi',
      'Tagihan',
      'Unggah Pendamping',
      'Buat Undangan',
    ];

    const descriptions = <String>[
      'Pastikan status yudisium sudah memenuhi syarat untuk mendaftar wisuda.',
      'Lengkapi formulir pendaftaran wisuda setelah status yudisium dinyatakan siap.',
      'Tagihan akan tersedia setelah aplikasi wisuda berhasil diajukan.',
      'Unggah foto pendamping setelah tahap tagihan tersedia (opsional).',
      'Buat undangan setelah tagihan selesai.',
    ];

    final steps = <ConvocationStep>[];
    for (var index = 0; index < titles.length; index++) {
      final isDone = stepDoneFlags[index];
      final allPreviousDone = _allRequiredPreviousDone(index, stepDoneFlags);

      final state = isDone
          ? ConvocationStepState.done
          : allPreviousDone
          ? ConvocationStepState.current
          : ConvocationStepState.locked;

      steps.add(
        ConvocationStep(
          order: index + 1,
          title: titles[index],
          description: descriptions[index],
          state: state,
          statusText: _buildStatusText(index, state),
        ),
      );
    }

    return steps;
  }

  String _buildStatusText(int index, ConvocationStepState state) {
    switch (index) {
      case 0:
        return _buildYudisiumStatusText();
      case 1:
        return _statusText(
          state,
          aplikasi,
          completedText: 'Pendaftaran sudah diisi',
        );
      case 2:
        return _statusText(
          state,
          tagihan,
          completedText: 'Tagihan sudah tersedia',
        );
      case 3:
        if (!_hasValue(unggahPendamping)) {
          return state == ConvocationStepState.locked
              ? 'Menunggu tagihan tersedia'
              : 'Opsional - dapat dilewati';
        }
        return _statusText(
          state,
          unggahPendamping,
          completedText: 'Dokumen pendamping sudah diunggah',
        );
      case 4:
        return _statusText(
          state,
          buatUndangan,
          completedText: 'Undangan sudah dibuat',
        );
      default:
        return '';
    }
  }

  String _statusText(
    ConvocationStepState state,
    dynamic rawValue, {
    required String completedText,
  }) {
    if (_hasValue(rawValue)) {
      return completedText;
    }

    switch (state) {
      case ConvocationStepState.done:
        return completedText;
      case ConvocationStepState.current:
        return 'Siap diproses';
      case ConvocationStepState.locked:
        return 'Menunggu langkah sebelumnya';
    }
  }

  static bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return value.toString().trim().isNotEmpty;
  }

  String _buildYudisiumStatusText() {
    if (!isYudisiumDone) {
      return yudisiumStatus.trim().isEmpty ? 'Belum Yudisium' : yudisiumStatus;
    }

    final parts = <String>[
      if (yudisiumDate.trim().isNotEmpty) 'Tanggal: $yudisiumDate',
      if (yudisiumPredicate.trim().isNotEmpty) 'Predikat: $yudisiumPredicate',
      if (yudisiumIpk.trim().isNotEmpty) 'IPK: $yudisiumIpk',
    ];

    if (parts.isEmpty) {
      return yudisiumStatus.trim().isEmpty ? 'Sudah Yudisium' : yudisiumStatus;
    }

    return parts.join(' • ');
  }

  bool _allRequiredPreviousDone(int index, List<bool> doneFlags) {
    if (index == 0) return true;
    if (index == 4) {
      return doneFlags[0] && doneFlags[1] && doneFlags[2];
    }
    return doneFlags.take(index).every((item) => item);
  }

  String _readNestedString(dynamic value, String key) {
    if (value is Map) {
      return value[key]?.toString() ?? '';
    }
    return '';
  }

  String _readFirstListItemString(dynamic value, String key) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      final map = Map<String, dynamic>.from(value.first as Map);
      return map[key]?.toString() ?? '';
    }
    return '';
  }

  static String _resolveYudisiumStatus(Map<String, dynamic> yudisiumMap) {
    final status = yudisiumMap['status']?.toString() ?? '';
    if (status.trim().isNotEmpty) {
      return status;
    }

    final hasDate = (yudisiumMap['tanggal']?.toString() ?? '')
        .trim()
        .isNotEmpty;
    final hasPredicate = (yudisiumMap['predikat']?.toString() ?? '')
        .trim()
        .isNotEmpty;
    final hasIpk = (yudisiumMap['ipk']?.toString() ?? '').trim().isNotEmpty;

    if (hasDate || hasPredicate || hasIpk) {
      return 'Sudah Yudisium';
    }

    return '';
  }
}

class ConvocationStep {
  final int order;
  final String title;
  final String description;
  final String statusText;
  final ConvocationStepState state;

  const ConvocationStep({
    required this.order,
    required this.title,
    required this.description,
    required this.statusText,
    required this.state,
  });
}

enum ConvocationStepState { done, current, locked }

class ConvocationApplicationRequest {
  final String biaya;
  final String dateEnd;
  final String togaSize;
  final String receiver;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final String phone;

  const ConvocationApplicationRequest({
    required this.biaya,
    required this.dateEnd,
    required this.togaSize,
    required this.receiver,
    required this.address,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'biaya': biaya,
      'dateend': dateEnd,
      'togasize': togaSize,
      'penerima': receiver,
      'alamat': address,
      'kota': city,
      'propinsi': province,
      'kodepos': postalCode,
      'telepon': phone,
    };
  }
}

class ConvocationApplicationOptionRequest {
  final String photoPackage;
  final List<String> additions;
  final String paymentDeadline;

  const ConvocationApplicationOptionRequest({
    required this.photoPackage,
    required this.additions,
    required this.paymentDeadline,
  });

  Map<String, dynamic> toJson() {
    return {
      'option': {'paketphoto': photoPackage, 'addition': additions},
      'batas_pembayaran': paymentDeadline,
    };
  }
}

class ConvocationInfoWisuda {
  final String academicYear;
  final String semester;
  final String fee;
  final String day;
  final String paymentDeadline;
  final String startRegistration;
  final String endRegistration;
  final Map<String, String> togaSizes;
  final String period;
  final List<ConvocationPhotoPackageOption> photoPackages;
  final List<ConvocationPhotoAdditionOption> photoAdditions;

  const ConvocationInfoWisuda({
    required this.academicYear,
    required this.semester,
    required this.fee,
    required this.day,
    required this.paymentDeadline,
    required this.startRegistration,
    required this.endRegistration,
    required this.togaSizes,
    required this.period,
    required this.photoPackages,
    required this.photoAdditions,
  });

  factory ConvocationInfoWisuda.fromJson(Map<String, dynamic> json) {
    final ukuranToga = json['ukuran_toga'];
    final ukuranTogaMap = ukuranToga is Map
        ? Map<String, dynamic>.from(ukuranToga)
        : const <String, dynamic>{};

    final paketFoto = ((json['paket_foto'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final packages = <ConvocationPhotoPackageOption>[];
    final additions = <ConvocationPhotoAdditionOption>[];

    for (final item in paketFoto) {
      final members = ((item['member'] as List?) ?? const [])
          .whereType<Map>()
          .map((member) => Map<String, dynamic>.from(member))
          .toList();

      if (members.isNotEmpty) {
        for (final member in members) {
          final code = member['code']?.toString() ?? '';
          if (code.trim().isEmpty) continue;

          final memberName = member['member_name']?.toString() ?? code;
          final items = ((member['items'] as List?) ?? const [])
              .whereType<Map>()
              .map((row) => row['items_name']?.toString() ?? '')
              .where((text) => text.trim().isNotEmpty)
              .toSet()
              .toList();

          packages.add(
            ConvocationPhotoPackageOption(
              code: code,
              title: memberName,
              subtitle: items.isEmpty ? 'Paket foto wisuda' : items.first,
              priceLabel: _formatCurrency(member['price']?.toString()),
              isRecommended: code.toUpperCase() == 'B',
            ),
          );
        }
        continue;
      }

      final additionalCode = item['code']?.toString() ?? '';
      if (additionalCode.trim().isEmpty) continue;
      additions.add(
        ConvocationPhotoAdditionOption(
          id: additionalCode,
          title: item['detail_name']?.toString() ?? additionalCode,
          subtitle: _formatCurrency(item['price']?.toString()),
        ),
      );
    }

    return ConvocationInfoWisuda(
      academicYear: json['thn_akademik']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      fee: json['biaya']?.toString() ?? '',
      day: json['hari']?.toString() ?? '',
      paymentDeadline: json['batas_pembayaran']?.toString() ?? '',
      startRegistration: json['mulai_pendaftaran']?.toString() ?? '',
      endRegistration: json['batas_pendaftaran']?.toString() ?? '',
      togaSizes: ukuranTogaMap.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
      period: json['periode']?.toString() ?? '',
      photoPackages: packages,
      photoAdditions: additions,
    );
  }
}

class ConvocationApplicationSnapshot {
  final String togaSize;
  final List<String> photoAdditions;
  final String receiver;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final String phone;
  final String fee;

  const ConvocationApplicationSnapshot({
    required this.togaSize,
    required this.photoAdditions,
    required this.receiver,
    required this.address,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.phone,
    required this.fee,
  });

  factory ConvocationApplicationSnapshot.fromJson(Map<String, dynamic> json) {
    final kontakRaw = json['kontak'];
    final kontak = kontakRaw is Map
        ? Map<String, dynamic>.from(kontakRaw)
        : const <String, dynamic>{};

    final tambahan = ((json['paket_tambahan'] as List?) ?? const [])
        .map((item) => item?.toString() ?? '')
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return ConvocationApplicationSnapshot(
      togaSize: json['ukuran_toga']?.toString() ?? '',
      photoAdditions: tambahan,
      receiver: kontak['penerima']?.toString() ?? '',
      address: kontak['alamat']?.toString() ?? '',
      city: kontak['kota']?.toString() ?? '',
      province: kontak['propinsi']?.toString() ?? '',
      postalCode: kontak['kode_pos']?.toString() ?? '',
      phone: kontak['telpon']?.toString() ?? '',
      fee: json['biaya_wisuda']?.toString() ?? '',
    );
  }
}

class ConvocationTogaSizeOption {
  final String code;
  final String fitLabel;
  final String bodyHint;
  final List<String> details;

  const ConvocationTogaSizeOption({
    required this.code,
    required this.fitLabel,
    required this.bodyHint,
    required this.details,
  });
}

class ConvocationPhotoPackageOption {
  final String code;
  final String title;
  final String subtitle;
  final String priceLabel;
  final bool isRecommended;

  const ConvocationPhotoPackageOption({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.isRecommended = false,
  });
}

class ConvocationPhotoAdditionOption {
  final String id;
  final String title;
  final String subtitle;

  const ConvocationPhotoAdditionOption({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class ConvocationInvitationCard {
  final String convoId;
  final String invitationApiId;
  final String invitationId;
  final String createdAt;
  final String attendanceStatus;
  final String attendanceAt;
  final String invitationCardPath;
  final String photoPath;
  final String qrPath;

  const ConvocationInvitationCard({
    required this.convoId,
    required this.invitationApiId,
    required this.invitationId,
    required this.createdAt,
    required this.attendanceStatus,
    required this.attendanceAt,
    required this.invitationCardPath,
    required this.photoPath,
    required this.qrPath,
  });

  factory ConvocationInvitationCard.fromJson(Map<String, dynamic> json) {
    return ConvocationInvitationCard(
      convoId: (json['convoid'] ?? json['c_id'] ?? '').toString(),
      invitationApiId: (json['invitationId'] ?? json['id_ci'] ?? '').toString(),
      invitationId: (json['invitationId'] ?? json['id_ci'] ?? '').toString(),
      createdAt: json['created_dt']?.toString() ?? '',
      attendanceStatus: json['attendance_status']?.toString() ?? '',
      attendanceAt: json['attendance_dt']?.toString() ?? '',
      invitationCardPath: json['invitation_card']?.toString() ?? '',
      photoPath: json['photo']?.toString() ?? '',
      qrPath: (json['qr'] ?? json['qr_path'] ?? '').toString(),
    );
  }

  bool get isAttended => attendanceStatus == '1';

  String get attendanceLabel {
    if (attendanceStatus == '1') {
      return 'Sudah hadir';
    }
    if (attendanceStatus == '0') {
      return 'Belum hadir';
    }
    return 'Status belum tersedia';
  }
}

const List<ConvocationTogaSizeOption> convocationTogaSizes = [
  ConvocationTogaSizeOption(
    code: 'S',
    fitLabel: 'Compact Fit',
    bodyHint: 'Cocok untuk tubuh kecil hingga ramping.',
    details: [
      'Panjang toga: 97 cm',
      'Lebar pundak: 42 cm',
      'Panjang lengan: 52 cm',
    ],
  ),
  ConvocationTogaSizeOption(
    code: 'M',
    fitLabel: 'Regular Fit',
    bodyHint: 'Pilihan aman untuk postur sedang.',
    details: [
      'Panjang toga: 100 cm',
      'Lebar pundak: 44 cm',
      'Panjang lengan: 54 cm',
    ],
  ),
  ConvocationTogaSizeOption(
    code: 'L',
    fitLabel: 'Balanced Fit',
    bodyHint: 'Nyaman untuk postur sedang ke tinggi.',
    details: [
      'Panjang toga: 103 cm',
      'Lebar pundak: 46 cm',
      'Panjang lengan: 56 cm',
    ],
  ),
  ConvocationTogaSizeOption(
    code: 'XL',
    fitLabel: 'Relaxed Fit',
    bodyHint: 'Memberi ruang lebih pada bahu dan badan.',
    details: [
      'Panjang toga: 106 cm',
      'Lebar pundak: 48 cm',
      'Panjang lengan: 58 cm',
    ],
  ),
  ConvocationTogaSizeOption(
    code: 'XXL',
    fitLabel: 'Wide Fit',
    bodyHint: 'Cocok untuk postur besar dengan ruang gerak luas.',
    details: [
      'Panjang toga: 109 cm',
      'Lebar pundak: 50 cm',
      'Panjang lengan: 60 cm',
    ],
  ),
  ConvocationTogaSizeOption(
    code: 'XXXL',
    fitLabel: 'Extra Wide Fit',
    bodyHint: 'Pilihan paling lega untuk postur ekstra besar.',
    details: [
      'Panjang toga: 112 cm',
      'Lebar pundak: 52 cm',
      'Panjang lengan: 62 cm',
    ],
  ),
];

const String convocationPhotoPaymentDeadline = '25-04-2026';

const List<ConvocationPhotoPackageOption> convocationPhotoPackages = [
  ConvocationPhotoPackageOption(
    code: 'A',
    title: 'Paket A',
    subtitle: 'Pilihan dasar untuk sesi foto wisuda.',
    priceLabel: 'Rp350.000',
  ),
  ConvocationPhotoPackageOption(
    code: 'B',
    title: 'Paket B',
    subtitle: 'Opsi menengah dengan hasil dokumentasi lebih lengkap.',
    priceLabel: 'Rp550.000',
    isRecommended: true,
  ),
  ConvocationPhotoPackageOption(
    code: 'C',
    title: 'Paket C',
    subtitle: 'Paket premium untuk kebutuhan foto yang lebih fleksibel.',
    priceLabel: 'Rp850.000',
  ),
];

const List<ConvocationPhotoAdditionOption> convocationPhotoAdditions = [
  ConvocationPhotoAdditionOption(
    id: '53',
    title: 'Tambahan 53',
    subtitle: 'Label sementara menunggu referensi detail dari backend.',
  ),
  ConvocationPhotoAdditionOption(
    id: '56',
    title: 'Tambahan 56',
    subtitle: 'Label sementara menunggu referensi detail dari backend.',
  ),
];

String _formatCurrency(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty || text == 'null') {
    return '-';
  }

  final normalized = text.split('.').first.replaceAll(',', '');
  final number = int.tryParse(normalized);
  if (number == null) return text;

  final chars = number.toString().split('').reversed.toList();
  final chunks = <String>[];
  for (var i = 0; i < chars.length; i += 3) {
    final end = (i + 3).clamp(0, chars.length);
    chunks.add(chars.sublist(i, end).reversed.join());
  }
  return 'Rp${chunks.reversed.join('.')}';
}
