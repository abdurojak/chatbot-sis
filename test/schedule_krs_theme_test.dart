import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/schedule_krs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('JadwalKrsScreen summary panel uses dark theme colors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: JadwalKrsScreen(idSemester: '773')),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final panel = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Semester to Register'),
            matching: find.byType(Container),
          )
          .last,
    );
    final valueChip = tester.widget<Container>(
      find.ancestor(of: find.text('-'), matching: find.byType(Container)).first,
    );
    final label = tester.widget<Text>(find.text('Semester to Register'));

    expect(scaffold.backgroundColor, AppThemePalette.background);
    expect((panel.decoration! as BoxDecoration).color, AppThemePalette.surface);
    expect(
      (valueChip.decoration! as BoxDecoration).color,
      AppThemePalette.accentAvatar,
    );
    expect(label.style?.color, AppThemePalette.textPrimary);
  });

  testWidgets('JadwalKrsScreen schedule table aligns header and time column', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: JadwalKrsScreen(idSemester: '773')),
    );
    await tester.pumpAndSettle();

    final timeHeader = tester.widget<Container>(
      find
          .ancestor(of: find.text('Time'), matching: find.byType(Container))
          .first,
    );
    final firstTimeCell = tester.widget<Container>(
      find
          .ancestor(of: find.text('07:00'), matching: find.byType(Container))
          .first,
    );

    expect(timeHeader.constraints?.maxWidth, 80);
    expect(firstTimeCell.constraints?.maxWidth, 80);
  });

  testWidgets('JadwalKrsScreen schedule table keeps bottom breathing room', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: JadwalKrsScreen(idSemester: '773')),
    );
    await tester.pumpAndSettle();

    final tableScroll = tester.widget<SingleChildScrollView>(
      find
          .ancestor(
            of: find.text('Time'),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );

    expect(tableScroll.padding, const EdgeInsets.fromLTRB(16, 0, 16, 24));
  });

  testWidgets('JadwalKrsScreen course badge shows course name and class', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    const course = KrsEnrollment(
      idRegister: '1',
      code: 'IF101',
      courseName: 'Algoritma',
      className: 'A',
      credits: '3',
      approvalStatus: '0',
      schedules: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: buildScheduleCourseCodeBadgeForTest(course)),
      ),
    );

    expect(find.text('Algoritma'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('IF101'), findsNothing);

    final badge = tester.widget<Container>(
      find
          .ancestor(of: find.text('Algoritma'), matching: find.byType(Container))
          .first,
    );

    expect(
      (badge.decoration! as BoxDecoration).color,
      AppThemePalette.accentAvatar,
    );
  });

  testWidgets('JadwalKrsScreen course badge opens readable detail sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    const course = KrsEnrollment(
      idRegister: '1',
      code: 'IF101',
      courseName: 'Algoritma',
      className: 'A',
      credits: '3',
      approvalStatus: '0',
      schedules: [
        KrsScheduleEntry(
          day: 'Monday',
          startTime: '08:00:00',
          endTime: '10:00:00',
          room: 'R101',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: buildScheduleCourseCodeBadgeForTest(course)),
      ),
    );

    await tester.tap(find.text('Algoritma'));
    await tester.pumpAndSettle();

    expect(find.text('Algoritma'), findsWidgets);
    expect(find.text('Kode MK'), findsOneWidget);
    expect(find.text('IF101'), findsOneWidget);
    expect(find.text('Kelas'), findsOneWidget);
    expect(find.text('A'), findsWidgets);
    expect(find.text('Senin, 08:00 - 10:00'), findsOneWidget);
    expect(find.text('R101'), findsOneWidget);
  });
}
