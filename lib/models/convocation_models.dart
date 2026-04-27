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
  final String infoWisuda;
  final String yudisiumStatus;
  final dynamic aplikasi;
  final dynamic tagihan;
  final dynamic unggahPendamping;
  final dynamic buatUndangan;

  const ConvocationData({
    required this.infoWisuda,
    required this.yudisiumStatus,
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

    return ConvocationData(
      infoWisuda: json['InfoWisuda']?.toString() ?? '',
      yudisiumStatus: yudisiumMap['status']?.toString() ?? '',
      aplikasi: json['Aplikasi'],
      tagihan: json['Tagihan'],
      unggahPendamping: json['UnggahPendamping'],
      buatUndangan: json['BuatUndangan'],
    );
  }

  bool get hasInfoWisuda => infoWisuda.trim().isNotEmpty;

  bool get isYudisiumDone {
    final normalized = yudisiumStatus.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'belum yudisium';
  }

  List<ConvocationStep> buildSteps() {
    final stepDoneFlags = <bool>[
      isYudisiumDone,
      _hasValue(aplikasi),
      _hasValue(tagihan),
      _hasValue(unggahPendamping),
      _hasValue(buatUndangan),
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
      'Unggah foto pendamping setelah tahap tagihan tersedia.',
      'Buat undangan setelah seluruh langkah sebelumnya selesai.',
    ];

    final steps = <ConvocationStep>[];
    for (var index = 0; index < titles.length; index++) {
      final isDone = stepDoneFlags[index];
      final allPreviousDone =
          index == 0 || stepDoneFlags.take(index).every((item) => item);

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
        return isYudisiumDone
            ? yudisiumStatus
            : (yudisiumStatus.trim().isEmpty
                  ? 'Belum tersedia'
                  : yudisiumStatus);
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
