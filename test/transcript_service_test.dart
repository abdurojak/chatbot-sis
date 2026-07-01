import 'dart:async';
import 'dart:convert';

import 'package:chatbot/services/transcript_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('getTranscript posts auth payload and parses file path', () async {
    final client = _RecordingClient({
      'status': 200,
      'body': {
        'data': {
          'file_path':
              'https://sis.trisakti.ac.id/documents/student/transcript/transcript_064102400002.pdf',
        },
      },
    });

    final result = await TranscriptService.getTranscript(
      idLogin: '241150',
      token: 'token',
      client: client,
    );

    expect(client.path, '/api/get-transkrip');
    expect(client.requestBody, {'IdLogin': '241150', 'token': 'token'});
    expect(
      result.filePath,
      'https://sis.trisakti.ac.id/documents/student/transcript/transcript_064102400002.pdf',
    );
  });
}

class _RecordingClient extends http.BaseClient {
  final Object _response;
  String? path;
  Map<String, dynamic>? requestBody;

  _RecordingClient(this._response);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    path = request.url.path;
    if (request is http.Request) {
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
    }

    final body = _response is String ? _response : jsonEncode(_response);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}
