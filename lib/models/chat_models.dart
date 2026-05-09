class ChatContact {
  final String idReceiver;
  final String name;
  final String lastDate;
  final int unreadCount;
  final String destType;
  final String sourceLabel;

  const ChatContact({
    required this.idReceiver,
    required this.name,
    required this.lastDate,
    required this.unreadCount,
    this.destType = '3',
    this.sourceLabel = '',
  });

  factory ChatContact.fromJson(
    Map<String, dynamic> json, {
    String sourceLabel = '',
    String? fallbackDestType,
  }) {
    final idReceiver = _readString(json['IdReceiver']);
    final name = _cleanText(json['name'], fallback: 'Kontak');
    return ChatContact(
      idReceiver: idReceiver,
      name: name,
      lastDate: _readString(json['dt_last']),
      unreadCount: int.tryParse(_readString(json['count_unread'])) ?? 0,
      destType: _readString(
        json['desttype'] ?? json['destType'],
        fallback:
            fallbackDestType ??
            _inferDestType(idReceiver: idReceiver, name: name),
      ),
      sourceLabel: sourceLabel,
    );
  }

  String get initials {
    final match = RegExp(r'[A-Za-z0-9]').firstMatch(name);
    return match?.group(0)?.toUpperCase() ?? '?';
  }

  String get lastTimeLabel {
    if (lastDate.length >= 16) {
      return lastDate.substring(11, 16);
    }
    return lastDate;
  }

  String get destTypeLabel {
    return switch (destType) {
      '1' => 'Mahasiswa',
      '2' => 'Dosen',
      '3' => 'Grup',
      _ => 'Kontak',
    };
  }
}

class ChatContactResponse {
  final List<ChatContact> contacts;

  const ChatContactResponse({required this.contacts});

  factory ChatContactResponse.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final rawContacts = body['data'] as List? ?? const [];
    return ChatContactResponse(
      contacts: rawContacts
          .whereType<Map>()
          .map((item) => ChatContact.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class ChatSearchResult {
  final ChatContact contact;
  final String sourceLabel;

  const ChatSearchResult({required this.contact, required this.sourceLabel});
}

class ChatSearchResponse {
  final List<ChatSearchResult> results;

  const ChatSearchResponse({required this.results});

  factory ChatSearchResponse.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final results = <ChatSearchResult>[];

    void collect(String groupKey, String typeKey, String label) {
      final section = data[groupKey] as Map<String, dynamic>? ?? const {};
      final rawItems = section[typeKey] as List? ?? const [];
      final fallbackDestType = typeKey == 'group' ? '3' : null;
      for (final item in rawItems.whereType<Map>()) {
        final contact = ChatContact.fromJson(
          Map<String, dynamic>.from(item),
          sourceLabel: label,
          fallbackDestType: fallbackDestType,
        );
        results.add(ChatSearchResult(contact: contact, sourceLabel: label));
      }
    }

    collect('kelas', 'group', 'Kelas - Group');
    collect('kelas', 'personal', 'Kelas - Personal');
    collect('pa', 'group', 'PA - Group');
    collect('pa', 'personal', 'PA - Personal');

    return ChatSearchResponse(results: results);
  }
}

class ChatMessage {
  final String idChat;
  final String message;
  final String idSender;
  final String sentType;
  final String idReceiver;
  final String destType;
  final String status;
  final String category;
  final String entryDate;
  final String readDate;
  final String senderName;

  const ChatMessage({
    required this.idChat,
    required this.message,
    required this.idSender,
    required this.sentType,
    required this.idReceiver,
    required this.destType,
    required this.status,
    required this.category,
    required this.entryDate,
    required this.readDate,
    required this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      idChat: _readString(json['IdChat']),
      message: _cleanText(json['chatMessage']),
      idSender: _readString(json['IdSender']),
      sentType: _readString(json['sentType']),
      idReceiver: _readString(json['IdReceiver']),
      destType: _readString(json['destType'], fallback: '3'),
      status: _readString(json['status']),
      category: _cleanText(json['Category'], fallback: 'kuliah'),
      entryDate: _readString(json['dt_entry']),
      readDate: _readString(json['dt_read']),
      senderName: _cleanText(json['name'], fallback: 'Pengirim'),
    );
  }

  bool isMine(String idLogin) => idSender == idLogin;

  static List<ChatMessage> filterByCategory(
    List<ChatMessage> messages,
    String? category,
  ) {
    final selectedCategory = _readString(category).toLowerCase();
    if (selectedCategory.isEmpty || selectedCategory == 'all') {
      return messages;
    }
    return messages
        .where((message) => message.category.toLowerCase() == selectedCategory)
        .toList();
  }

  String get timeLabel {
    if (entryDate.length >= 16) {
      return entryDate.substring(11, 16);
    }
    return entryDate;
  }
}

class ChatMessageResponse {
  final List<ChatMessage> messages;

  const ChatMessageResponse({required this.messages});

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final rawMessages = body['data'] as List? ?? const [];
    final messages =
        rawMessages
            .whereType<Map>()
            .map(
              (item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

    return ChatMessageResponse(messages: messages);
  }
}

class ChatActionResult {
  final String message;

  const ChatActionResult({required this.message});

  factory ChatActionResult.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? const {};
    final data = body['data'];
    return ChatActionResult(
      message: _cleanText(
        data ?? json['message'] ?? json['status'],
        fallback: 'Berhasil',
      ),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

String _cleanText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

String _inferDestType({required String idReceiver, required String name}) {
  final lowerName = name.toLowerCase();
  final looksLikeClassGroup =
      lowerName.contains(' genap ') ||
      lowerName.contains(' ganjil ') ||
      RegExp(r'-[a-z]{2,4}-\d{2}', caseSensitive: false).hasMatch(name);
  if (looksLikeClassGroup) {
    return '3';
  }

  final numericId = int.tryParse(idReceiver);
  if (numericId != null && idReceiver.length <= 5) {
    return '2';
  }

  return '1';
}
