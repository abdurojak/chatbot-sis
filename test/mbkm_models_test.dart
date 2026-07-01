import 'package:chatbot/models/mbkm_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MbkmExchangeCourseData', () {
    test(
      'parses registration closed response with message and empty courses',
      () {
        final result = MbkmExchangeCourseData.fromJson({
          'status': 200,
          'headers': {'Content-Type': 'application/json'},
          'body': {
            'data': '',
            'message': 'Pendaftaran pertukaran mahasiswa belum dibuka',
          },
        });

        expect(result.appliedCourses, isEmpty);
        expect(result.internalCourses, isEmpty);
        expect(result.externalCourses, isEmpty);
        expect(result.message, 'Pendaftaran pertukaran mahasiswa belum dibuka');
        expect(result.isUnavailable, isTrue);
      },
    );
  });
}
