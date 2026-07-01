import 'dart:async';
import 'dart:convert';

import 'package:chatbot/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ChatService', () {
    test('sendMessage sends desttype and kuliah default category', () async {
      final client = _RecordingClient([
        {
          'status': 200,
          'body': {
            'data': {'pesan': 'pesan terkirim'},
          },
        },
      ]);

      await ChatService.sendMessage(
        idLogin: '241149',
        token: 'token',
        idReceiver: '3',
        message: 'Apakah ada kelas hari ini?',
        client: client,
      );

      expect(client.paths, ['/api/chat-message']);
      expect(client.requestBodies.single, {
        'IdLogin': '241149',
        'token': 'token',
        'IdReceiver': '3',
        'desttype': '3',
        'category': ChatService.defaultCategory,
        'pesan': 'Apakah ada kelas hari ini?',
      });
    });

    test('getContacts sends empty category for all contacts', () async {
      final client = _RecordingClient([
        {
          'status': 200,
          'body': {'data': []},
        },
      ]);

      await ChatService.getContacts(
        idLogin: '241149',
        token: 'token',
        category: '',
        client: client,
      );

      expect(client.requestBodies.single, {
        'IdLogin': '241149',
        'token': 'token',
        'category': '',
      });
    });

    test('getContacts sends selected discussion category', () async {
      final client = _RecordingClient([
        {
          'status': 200,
          'body': {'data': []},
        },
      ]);

      await ChatService.getContacts(
        idLogin: '241149',
        token: 'token',
        category: 'Krs',
        client: client,
      );

      expect(client.requestBodies.single['category'], 'Krs');
    });

    test('getContacts parses JSON after temporary PHP notice output', () async {
      final client = _RecordingClient([
        '<br />'
            '<b>Notice</b>: Undefined index: category<br />'
            '{"status":200,"headers":{"Content-Type":"application/json"},"body":{"data":[{"IdReceiver":"241149","dt_last":"2026-05-07 11:14:17","count_unread":"0","name":"064102400001 JORDANE"}]}}',
      ]);

      final contacts = await ChatService.getContacts(
        idLogin: '241149',
        token: 'token',
        category: '',
        client: client,
      );

      expect(contacts, hasLength(1));
      expect(contacts.single.idReceiver, '241149');
    });

    test(
      'sendMessage can send selected category from discussion list',
      () async {
        final client = _RecordingClient([
          {
            'status': 200,
            'body': {
              'data': {'pesan': 'pesan terkirim'},
            },
          },
        ]);

        await ChatService.sendMessage(
          idLogin: '241149',
          token: 'token',
          idReceiver: '3',
          category: 'krs',
          message: 'KRS dibuka kapan?',
          client: client,
        );

        expect(client.requestBodies.single['category'], 'krs');
      },
    );

    test('getContactsWithAutoGenerate generates contacts when empty', () async {
      final client = _RecordingClient([
        {
          'status': 200,
          'body': {'data': []},
        },
        {
          'status': 200,
          'body': {'data': 'generated'},
        },
        {
          'status': 200,
          'body': {
            'data': [
              {
                'IdReceiver': '3',
                'dt_last': '2026-05-04 12:47:45',
                'count_unread': '0',
                'name': 'Pemrograman Web',
              },
            ],
          },
        },
      ]);

      final contacts = await ChatService.getContactsWithAutoGenerate(
        idLogin: '241149',
        token: 'token',
        category: 'Krs',
        client: client,
      );

      expect(contacts, hasLength(1));
      expect(contacts.first.idReceiver, '3');
      expect(client.paths, [
        '/api/chat-get-contact',
        '/api/chat-generate-contact',
        '/api/chat-get-contact',
      ]);
      expect(client.requestBodies.first['category'], 'Krs');
      expect(client.requestBodies.last['category'], 'Krs');
    });

    test(
      'searchContactsWithAutoGenerate generates contacts when empty',
      () async {
        final client = _RecordingClient([
          {
            'status': 200,
            'body': {'data': {}},
          },
          {
            'status': 200,
            'body': {'data': 'generated'},
          },
          {
            'status': 200,
            'body': {
              'data': {
                'kelas': {
                  'group': [
                    {
                      'IdReceiver': '241149',
                      'dt_last': '2026-05-04 12:47:45',
                      'count_unread': '0',
                      'name': '064102400001 JORDANE',
                    },
                  ],
                },
              },
            },
          },
        ]);

        final results = await ChatService.searchContactsWithAutoGenerate(
          idLogin: '241149',
          token: 'token',
          keyword: 'jordane',
          client: client,
        );

        expect(results, hasLength(1));
        expect(results.first.contact.idReceiver, '241149');
        expect(client.paths, [
          '/api/chat-search-contact',
          '/api/chat-generate-contact',
          '/api/chat-search-contact',
        ]);
        expect(client.requestBodies.first['keyword'], 'jordane');
        expect(client.requestBodies.last['keyword'], 'jordane');
      },
    );
  });
}

class _RecordingClient extends http.BaseClient {
  final List<Object> _responses;
  final paths = <String>[];
  final requestBodies = <Map<String, dynamic>>[];

  _RecordingClient(this._responses);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    paths.add(request.url.path);

    if (request is http.Request) {
      requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
    }

    final response = _responses.removeAt(0);
    final body = response is String ? response : jsonEncode(response);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}
