import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/mbkm_outbound_screen.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);
  });

  testWidgets('renders compact outbound dashboard with application actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MbkmOutboundPage(
          skipInitialLoad: true,
          initialData: _sampleData(),
        ),
      ),
    );

    expect(find.text('MBKM Outbound'), findsOneWidget);
    expect(
      find.text(
        'Pantau pengajuan, kompetensi, log kegiatan, dan tautan program dalam satu tempat.',
      ),
      findsNothing,
    );
    expect(find.text('Mahasiswa Contoh'), findsOneWidget);
    expect(find.text('064001900001'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('pengajuan'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('kompetensi'), findsOneWidget);
    expect(find.text('Ajukan MBKM'), findsOneWidget);
    expect(find.text('Frontend Engineer Internship'), findsOneWidget);
    expect(find.text('PT Mitra Digital Indonesia'), findsOneWidget);
    expect(find.text('01 Feb - 30 Jun'), findsWidgets);
    expect(find.text('Lihat Log'), findsWidgets);
    expect(find.text('Detail'), findsOneWidget);
  });

  testWidgets(
    'renders friendly empty state while keeping apply action visible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MbkmOutboundPage(
            skipInitialLoad: true,
            initialData: const MbkmResponseData(
              biodata: MbkmBiodata(
                name: 'Mahasiswa Contoh',
                nim: '064001900001',
              ),
              applications: [],
            ),
          ),
        ),
      );

      expect(find.text('Belum ada pengajuan MBKM'), findsOneWidget);
      expect(find.text('Ajukan MBKM'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    },
  );

  testWidgets('uses themed surfaces for compact cards in dark mode', (
    tester,
  ) async {
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      MaterialApp(
        home: MbkmOutboundPage(
          skipInitialLoad: true,
          initialData: _sampleData(),
        ),
      ),
    );

    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();

    final semesterStat = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Genap 2025/2026'),
            matching: find.byType(Container),
          )
          .first,
    );
    final statDecoration = semesterStat.decoration! as BoxDecoration;

    expect(statDecoration.color, AppThemePalette.surface);
  });
}

MbkmResponseData _sampleData() {
  return const MbkmResponseData(
    biodata: MbkmBiodata(name: 'Mahasiswa Contoh', nim: '064001900001'),
    applications: [
      MbkmApplication(
        idApplication: 'MA-1',
        title: 'Frontend Engineer Internship',
        companyName: 'PT Mitra Digital Indonesia',
        semesterName: 'Genap 2025/2026',
        activityType: 'Magang',
        scaleName: 'Nasional',
        description: 'Program magang frontend.',
        moreInfoUrl: 'https://example.com',
        startDate: '01 Feb',
        endDate: '30 Jun',
        selectionDate: '20 Jan',
        resultDate: '25 Jan',
        internalMentorName: 'Dr. Andi Saputra',
        competencies: [
          MbkmCompetency(
            competency: 'UI Implementation',
            learningSource: 'Project sprint',
            assessmentModel: 'Review mentor',
            learningExperience: 'Build feature',
            durationInHour: '120',
          ),
          MbkmCompetency(
            competency: 'Team Collaboration',
            learningSource: 'Daily standup',
            assessmentModel: 'Evaluasi performa',
            learningExperience: 'Kolaborasi tim',
            durationInHour: '80',
          ),
        ],
      ),
    ],
  );
}
