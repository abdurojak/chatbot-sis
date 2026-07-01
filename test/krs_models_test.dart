import 'package:chatbot/models/krs_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const firstSchedule = {
    'hari': 'Tuesday',
    'mulai': '10:10:00',
    'selesai': '12:40:00',
    'ruang': 'AE701',
  };

  const secondSchedule = {
    'hari': 'Monday',
    'mulai': '07:30:00',
    'selesai': '10:00:00',
    'ruang': 'AE701',
  };

  const thirdSchedule = {
    'hari': 'Thursday',
    'mulai': '07:30:00',
    'selesai': '10:00:00',
    'ruang': 'AE701',
  };

  const fourthSchedule = {
    'hari': 'Monday',
    'mulai': '13:10:00',
    'selesai': '15:40:00',
    'ruang': 'AE401',
  };

  Map<String, dynamic> enrollmentJson({
    required String code,
    required String courseName,
    required Object jadwal,
  }) {
    return {
      'IdRegister': code,
      'kodemk': code,
      'namamk': courseName,
      'namakelas': 'TIF-01',
      'sks': '3',
      'persetujuan': '1',
      'jadwal': jadwal,
    };
  }

  test('KrsEnrollment parses a single schedule object', () {
    final enrollment = KrsEnrollment.fromJson(
      enrollmentJson(
        code: 'IKL6441',
        courseName: 'Struktur Data dan Algoritma',
        jadwal: firstSchedule,
      ),
    );

    expect(enrollment.schedules, hasLength(1));
    expect(enrollment.schedules.single.day, 'Tuesday');
    expect(enrollment.schedules.single.startTimeShort, '10:10');
  });

  test(
    'KrsEnrollment list parser splits cumulative API schedules per course',
    () {
      final enrollments = KrsEnrollment.listFromJson([
        enrollmentJson(
          code: 'IKL6441',
          courseName: 'Struktur Data dan Algoritma',
          jadwal: firstSchedule,
        ),
        enrollmentJson(
          code: 'IKP6333',
          courseName: 'Cloud Computing',
          jadwal: [firstSchedule, secondSchedule, thirdSchedule],
        ),
        enrollmentJson(
          code: 'IKD6312',
          courseName: 'Manajemen Data dan Informasi',
          jadwal: [
            firstSchedule,
            secondSchedule,
            thirdSchedule,
            fourthSchedule,
          ],
        ),
      ]);

      expect(enrollments[0].schedules, hasLength(1));
      expect(enrollments[0].schedules.single.day, 'Tuesday');

      expect(enrollments[1].schedules, hasLength(2));
      expect(enrollments[1].schedules.map((schedule) => schedule.day), [
        'Monday',
        'Thursday',
      ]);

      expect(enrollments[2].schedules, hasLength(1));
      expect(enrollments[2].schedules.single.room, 'AE401');
    },
  );
}
