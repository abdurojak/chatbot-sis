import 'package:chatbot/models/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatContactResponse', () {
    test('parses contact list with default desttype', () {
      final response = {
        'status': 200,
        'body': {
          'data': [
            {
              'IdReceiver': '3',
              'dt_last': '2026-05-04 12:47:45',
              'count_unread': '2',
              'name': 'Pemrograman Web-IKG6405-TIF-01 Genap 2025/2026 (R)',
            },
          ],
        },
      };

      final result = ChatContactResponse.fromJson(response);

      expect(result.contacts, hasLength(1));
      expect(result.contacts.first.idReceiver, '3');
      expect(result.contacts.first.destType, '3');
      expect(result.contacts.first.unreadCount, 2);
      expect(result.contacts.first.initials, 'P');
    });
  });

  group('ChatSearchResponse', () {
    test('flattens kelas and pa group/personal results', () {
      final response = {
        'status': 200,
        'body': {
          'data': {
            'kelas': {
              'group': [
                {'IdReceiver': '12', 'name': 'Kelas A'},
              ],
              'personal': [],
            },
            'pa': {
              'group': [
                {'IdReceiver': '13', 'name': 'Dian Pratiwi'},
              ],
              'personal': [
                {'IdReceiver': '3041', 'name': 'Dian Pratiwi'},
              ],
            },
          },
        },
      };

      final result = ChatSearchResponse.fromJson(response);

      expect(result.results, hasLength(3));
      expect(result.results.map((item) => item.sourceLabel), [
        'Kelas - Group',
        'PA - Group',
        'PA - Personal',
      ]);
      expect(result.results.map((item) => item.contact.destType), [
        '3',
        '3',
        '2',
      ]);
    });

    test('infers personal student desttype from student-sized receiver id', () {
      final response = {
        'status': 200,
        'body': {
          'data': {
            'kelas': {'group': [], 'personal': []},
            'pa': {
              'group': [],
              'personal': [
                {'IdReceiver': '241150', 'name': 'AHMAD ARDIANSYAH'},
              ],
            },
          },
        },
      };

      final result = ChatSearchResponse.fromJson(response);

      expect(result.results.single.contact.destType, '1');
    });
  });

  group('ChatMessageResponse', () {
    test('parses and sorts messages ascending by entry date', () {
      final response = {
        'status': 200,
        'body': {
          'data': [
            {
              'IdChat': '2',
              'chatMessage': 'Pesan kedua',
              'IdSender': '241149',
              'sentType': '1',
              'IdReceiver': '3',
              'destType': '3',
              'status': '1',
              'Category': 'Perkuliahan',
              'dt_entry': '2026-05-04 12:45:47',
              'dt_read': null,
              'name': 'JORDANE',
            },
            {
              'IdChat': '1',
              'chatMessage': 'Pesan pertama',
              'IdSender': '3',
              'sentType': '1',
              'IdReceiver': '241149',
              'destType': '3',
              'status': '1',
              'Category': 'Perkuliahan',
              'dt_entry': '2026-05-04 12:40:48',
              'dt_read': null,
              'name': 'Dian Pratiwi',
            },
          ],
        },
      };

      final result = ChatMessageResponse.fromJson(response);

      expect(result.messages, hasLength(2));
      expect(result.messages.first.message, 'Pesan pertama');
      expect(result.messages.last.isMine('241149'), isTrue);
    });

    test('filters messages by selected category', () {
      final messages = [
        ChatMessage(
          idChat: '1',
          message: 'KRS dibuka kapan?',
          idSender: '241149',
          sentType: '1',
          idReceiver: '3',
          destType: '3',
          status: '1',
          category: 'krs',
          entryDate: '2026-05-04 12:40:48',
          readDate: '',
          senderName: 'JORDANE',
        ),
        ChatMessage(
          idChat: '2',
          message: 'Ada kelas hari ini?',
          idSender: '241149',
          sentType: '1',
          idReceiver: '3',
          destType: '3',
          status: '1',
          category: 'kuliah',
          entryDate: '2026-05-04 12:45:47',
          readDate: '',
          senderName: 'JORDANE',
        ),
      ];

      expect(ChatMessage.filterByCategory(messages, 'krs'), hasLength(1));
      expect(ChatMessage.filterByCategory(messages, 'all'), hasLength(2));
      expect(ChatMessage.filterByCategory(messages, null), hasLength(2));
    });
  });
}
