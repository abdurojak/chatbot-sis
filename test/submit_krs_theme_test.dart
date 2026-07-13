import 'dart:async';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/submit_krs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SubmitKrsScreen summary panel uses dark theme colors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(
      const MaterialApp(home: SubmitKrsScreen(idSemester: '773')),
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

  testWidgets('Drop KRS OTP dialog disables drop button while submitting', (
    tester,
  ) async {
    final completer = Completer<void>();
    var submitCount = 0;

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
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDropKrsOtpSheet(
                    context: context,
                    selectedItems: const [course],
                    onSubmit: (_) {
                      submitCount++;
                      return completer.future;
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Drop MK'), findsOneWidget);
    expect(find.text('Algoritma'), findsOneWidget);
    expect(find.text('IF101 - Kelas A - 3 SKS'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Drop MK'));
    await tester.pump();
    await tester.tap(find.text('Memproses...'));

    expect(submitCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
