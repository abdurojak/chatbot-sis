import 'dart:async';
import 'dart:convert';

import 'package:chatbot/services/krs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('registerCourse parses JSON after PHP notice output', () async {
    final client = _RecordingClient(
      '<br />'
      '<b>Notice</b>: Undefined index: AdvisorDefaultApprove<br />'
      '{"status":200,"headers":{"Content-Type":"application/json"},"body":{"status proses":"0","messages":""}}',
    );

    final result = await KrsService.registerCourse(
      idLogin: '245811',
      token: 'token',
      idCourse: '406360',
      maxSks: 24,
      client: client,
    );

    expect(result.isSuccess, isFalse);
    expect(client.requestBodies.single, {
      'token': 'token',
      'IdLogin': '245811',
      'IdCourse': '406360',
      'sksmaks': '24',
    });
  });
}

class _RecordingClient extends http.BaseClient {
  final String responseBody;
  final requestBodies = <Map<String, dynamic>>[];

  _RecordingClient(this.responseBody);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}
