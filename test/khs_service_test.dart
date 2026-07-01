import 'dart:convert';

import 'package:chatbot/services/khs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'fetchPageData still requests KHS when default semester fails',
    () async {
      final requestedPaths = <String>[];
      final client = MockClient((request) async {
        requestedPaths.add(request.url.path);

        if (request.url.path == '/api/get-semester') {
          return http.Response(
            jsonEncode({
              'body': {
                'semester': [
                  {
                    'IdSemesterMaster': '20241',
                    'SemesterMainName': 'Ganjil 2024/2025',
                  },
                ],
              },
            }),
            200,
          );
        }

        if (request.url.path == '/api/krs-requirement') {
          return http.Response('server error', 500);
        }

        if (request.url.path == '/api/get-khs') {
          expect(jsonDecode(request.body), {
            'IdLogin': 'student-1',
            'token': 'secret-token',
            'IdSemester': '20241',
          });

          return http.Response(
            jsonEncode({
              'body': {
                'kinerja': {
                  'ips': '3.50',
                  'ipk': '3.40',
                  'sks_sem': '20',
                  'sks_lulus': '100',
                },
                'detail': [],
              },
            }),
            200,
          );
        }

        return http.Response('not found', 404);
      });

      final pageData = await KhsService.fetchPageData(
        idLogin: 'student-1',
        token: 'secret-token',
        client: client,
      );

      expect(pageData.defaultSemesterId, '20241');
      expect(pageData.khs.performance.ips, '3.50');
      expect(
        requestedPaths,
        containsAllInOrder(['/api/get-semester', '/api/get-khs']),
      );
    },
  );
}
