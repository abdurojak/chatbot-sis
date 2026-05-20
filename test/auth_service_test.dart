import 'dart:async';
import 'dart:convert';

import 'package:chatbot/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AuthService', () {
    test('getRole posts IdLogin and parses role', () async {
      final client = _RecordingClient([
        {'role': 'STD'},
      ]);

      final role = await AuthService.getRole(idLogin: '214908', client: client);

      expect(role, 'STD');
      expect(client.paths, ['/api/get-role']);
      expect(client.requestBodies.single, {'IdLogin': '214908'});
    });

    test(
      'login fetches role when login response does not include it',
      () async {
        final client = _RecordingClient([
          {
            'token': 'login-token',
            'IdLogin': '214908',
            'userid': '214908',
            'nim': '214908',
            'id_otp': 'otp-id',
            'Active': '1',
          },
          {'role': 'STD'},
        ]);

        final result = await AuthService.login(
          user: '214908',
          password: 'secret',
          client: client,
        );

        expect(result.isSuccess, isTrue);
        expect(result.session?.role, 'STD');
        expect(client.paths, ['/api/login', '/api/get-role']);
        expect(client.requestBodies[1], {'IdLogin': '214908'});
      },
    );

    test('login stays successful when fallback role lookup fails', () async {
      final client = _RecordingClient([
        {
          'token': 'login-token',
          'IdLogin': '214908',
          'userid': '214908',
          'nim': '214908',
          'id_otp': 'otp-id',
          'Active': '1',
        },
        'not json',
      ]);

      final result = await AuthService.login(
        user: '214908',
        password: 'secret',
        client: client,
      );

      expect(result.isSuccess, isTrue);
      expect(result.session?.role, isNull);
      expect(client.paths, ['/api/login', '/api/get-role']);
    });
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
