import 'dart:async';
import 'dart:convert';

import 'package:chatbot/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('NotificationService', () {
    test(
      'openNotifications posts auth payload and parses notification list',
      () async {
        final client = _RecordingClient([
          {
            'status': 200,
            'body': {
              'data': {
                'jumlah': '1',
                'detail': [
                  {
                    'id_notif': '1',
                    'message': 'percobaan',
                    'dt_created': '2026-05-13 14:41:31',
                    'dt_read': null,
                    'category': 'KRS',
                    'idsender': '1',
                    'url_dest': null,
                    'dest_id': '205040',
                    'dest_type': '1',
                  },
                ],
              },
            },
          },
        ]);

        final result = await NotificationService.openNotifications(
          idLogin: '205040',
          token: 'token',
          client: client,
        );

        expect(client.paths, ['/api/open-notification']);
        expect(client.requestBodies.single, {
          'IdLogin': '205040',
          'token': 'token',
        });
        expect(result.count, 1);
        expect(result.items.single.message, 'percobaan');
        expect(result.items.single.category, 'KRS');
        expect(result.items.single.isUnread, isTrue);
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
