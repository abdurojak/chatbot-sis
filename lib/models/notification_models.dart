class NotificationResult {
  final int count;
  final List<AppNotification> items;

  const NotificationResult({required this.count, required this.items});

  factory NotificationResult.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final rawItems = data['detail'] as List? ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return NotificationResult(
      count: items.where((item) => item.isUnread).length,
      items: items,
    );
  }
}

class AppNotification {
  final String id;
  final String message;
  final String createdAt;
  final String? readAt;
  final String category;
  final String idSender;
  final String? urlDestination;
  final String destinationId;
  final String destinationType;

  const AppNotification({
    required this.id,
    required this.message,
    required this.createdAt,
    this.readAt,
    required this.category,
    required this.idSender,
    this.urlDestination,
    required this.destinationId,
    required this.destinationType,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _readString(json['id_notif']),
      message: _cleanText(json['message'], fallback: 'Notifikasi'),
      createdAt: _readString(json['dt_created']),
      readAt: _readNullableString(json['dt_read']),
      category: _cleanText(json['category'], fallback: 'Umum'),
      idSender: _readString(json['idsender']),
      urlDestination: _readNullableString(json['url_dest']),
      destinationId: _readString(json['dest_id']),
      destinationType: _readString(json['dest_type']),
    );
  }

  bool get isUnread => readAt == null;
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

String? _readNullableString(dynamic value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

String _cleanText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}
