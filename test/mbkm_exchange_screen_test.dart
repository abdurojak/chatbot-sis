import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/mbkm_exchange_screen.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);
  });

  testWidgets('renders compact exchange dashboard without hero description', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MbkmExchangePage(
          skipInitialLoad: true,
          initialSemesterId: '20261',
          initialData: _sampleData(),
        ),
      ),
    );

    expect(find.text('MBKM Pertukaran Mahasiswa'), findsOneWidget);
    expect(
      find.text(
        'Pilih mata kuliah internal atau external, pantau pengajuan, lalu cek jadwal sebelum mengirim pilihan berikutnya.',
      ),
      findsNothing,
    );
    expect(find.text('Pertukaran Mahasiswa'), findsOneWidget);
    expect(find.text('Diajukan'), findsWidgets);
    expect(find.text('Internal'), findsOneWidget);
    expect(find.text('External'), findsOneWidget);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Human Computer Interaction'), findsOneWidget);
    expect(find.text('Dr. Ratna Dewi'), findsOneWidget);
  });

  testWidgets('uses themed card surfaces in dark mode', (tester) async {
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      MaterialApp(
        home: MbkmExchangePage(
          skipInitialLoad: true,
          initialSemesterId: '20261',
          initialData: _sampleData(),
        ),
      ),
    );

    final courseContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Human Computer Interaction'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = courseContainer.decoration! as BoxDecoration;

    expect(decoration.color, AppThemePalette.surface);
  });

  testWidgets('shows registration closed message from API response', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MbkmExchangePage(
          skipInitialLoad: true,
          initialSemesterId: '20261',
          initialData: const MbkmExchangeCourseData(
            appliedCourses: [],
            internalCourses: [],
            externalCourses: [],
            message: 'Pendaftaran pertukaran mahasiswa belum dibuka',
          ),
        ),
      ),
    );

    expect(
      find.text('Pendaftaran pertukaran mahasiswa belum dibuka'),
      findsOneWidget,
    );
    expect(find.text('Pertukaran Mahasiswa'), findsNothing);
    expect(find.text('Belum ada mata kuliah yang diajukan'), findsNothing);
  });
}

MbkmExchangeCourseData _sampleData() {
  return const MbkmExchangeCourseData(
    appliedCourses: [
      MbkmExchangeAppliedCourse(
        idCourseTaggingGroup: 'G1',
        idSubject: 'S1',
        groupCode: 'A',
        lecturerId: 'L1',
        day: 'Senin',
        startTime: '09:00',
        endTime: '11:30',
        programName: 'Sistem Informasi',
        subjectCode: 'IF302',
        subjectName: 'Human Computer Interaction',
        creditHours: '3',
        appliedCount: 4,
        approval: '0',
        isIn: '1',
        lecturer: 'Dr. Ratna Dewi',
        idMa: 'MA1',
        approvalStatus: 'Menunggu',
        status: 'Diajukan',
        remark: '-',
        semesterId: '20261',
      ),
    ],
    internalCourses: [
      MbkmExchangeCourse(
        idCourseTaggingGroup: 'G2',
        idSubject: 'S2',
        groupCode: 'C',
        lecturerId: 'L2',
        day: 'Jumat',
        startTime: '08:00',
        endTime: '10:30',
        programName: 'Manajemen',
        subjectCode: 'MKU105',
        subjectName: 'Entrepreneurship and Innovation',
        creditHours: '3',
        appliedCount: 12,
        approval: '0',
        isIn: '0',
        lecturer: 'Arief Nugroho',
      ),
    ],
    externalCourses: [
      MbkmExchangeCourse(
        idCourseTaggingGroup: 'G3',
        idSubject: 'S3',
        groupCode: 'B',
        lecturerId: 'L3',
        day: 'Rabu',
        startTime: '13:00',
        endTime: '14:40',
        programName: 'Teknik Informatika',
        subjectCode: 'SI221',
        subjectName: 'Data Visualization',
        creditHours: '2',
        appliedCount: 7,
        approval: '0',
        isIn: '0',
        lecturer: 'Dina Lestari',
      ),
    ],
  );
}
