import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/kpu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);
  });

  testWidgets('renders exam slips as scannable cards with explicit actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExamSlipPage(
          skipInitialFetch: true,
          initialExamData: [
            {
              'SemesterName': 'Semester Genap 2025/2026',
              'exam_name': 'UTS',
              'nim': '064001900001',
              'name': 'Mahasiswa Contoh',
              'prodi': 'Teknik Informatika',
              'detail': [
                {
                  'kodemk': 'IF101',
                  'namamk': 'Basis Data',
                  'date': '16 Mar 2026',
                  'start': '08:00',
                  'room': 'F-401',
                },
                {
                  'kodemk': 'IF203',
                  'namamk': 'Pemrograman Mobile',
                  'date': '18 Mar 2026',
                  'start': '10:00',
                  'room': 'F-502',
                },
              ],
            },
          ],
        ),
      ),
    );

    expect(find.text('Periode Ujian'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('periode tersedia'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('mata kuliah'), findsOneWidget);
    expect(find.text('UTS'), findsOneWidget);
    expect(find.text('Semester Genap 2025/2026'), findsOneWidget);
    expect(find.text('Kartu PDF'), findsOneWidget);
    expect(find.text('QR Ujian'), findsOneWidget);
  });

  testWidgets('renders friendly empty state when there are no exam slips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExamSlipPage(skipInitialFetch: true, initialExamData: []),
      ),
    );

    expect(find.text('Belum ada kartu ujian'), findsOneWidget);
    expect(find.text('Muat Ulang'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
  });
}
