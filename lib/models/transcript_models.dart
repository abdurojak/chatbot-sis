class TranscriptData {
  final String filePath;

  const TranscriptData({required this.filePath});

  factory TranscriptData.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return TranscriptData(filePath: _readString(data['file_path']));
  }
}

String _readString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') {
    return '';
  }
  return text;
}
