import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/convocation_application_screen.dart';
import 'package:chatbot/convocation_invitation_screen.dart';
import 'package:chatbot/convocation_screen.dart';
import 'package:chatbot/models/convocation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);
  });

  testWidgets('convocation timeline cards use dark themed surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConvocationPage(skipInitialLoad: true, initialData: _data()),
      ),
    );

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('convocation-step-card-1')),
    );
    final decoration = card.decoration! as BoxDecoration;

    expect(decoration.color, AppThemePalette.surface);
  });

  testWidgets('convocation application section cards use dark surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ConvocationApplicationPage(convocationData: _data())),
    );

    final card = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Informasi Utama'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = card.decoration! as BoxDecoration;

    expect(decoration.color, AppThemePalette.surface);
  });

  testWidgets('convocation invitation cards use dark surfaces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConvocationInvitationPage(
          skipInitialLoad: true,
          initialIdLogin: '064001900001',
          initialCards: [_invitationCard()],
        ),
      ),
    );

    final card = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Undangan #INV-1'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = card.decoration! as BoxDecoration;

    expect(decoration.color, AppThemePalette.surface);
  });
}

ConvocationData _data() {
  return const ConvocationData(
    infoWisudaText: 'Pendaftaran wisuda tersedia',
    infoWisuda: ConvocationInfoWisuda(
      academicYear: '2025/2026',
      semester: 'GENAP',
      fee: '2400000',
      day: 'Sabtu',
      paymentDeadline: '18-10-2026',
      startRegistration: '16-10-2026',
      endRegistration: '17-10-2026',
      togaSizes: {'M': 'Medium Size'},
      period: 'Oktober 2026',
      photoPackages: [
        ConvocationPhotoPackageOption(
          code: 'A',
          title: 'Paket A',
          subtitle: 'Foto standar',
          priceLabel: 'Rp250.000',
          isRecommended: true,
        ),
      ],
      photoAdditions: [
        ConvocationPhotoAdditionOption(
          id: '53',
          title: 'Cetak Tambahan',
          subtitle: 'Tambahan cetak foto',
        ),
      ],
    ),
    yudisiumStatus: 'Sudah Yudisium',
    yudisiumDate: '2026-08-05',
    yudisiumPredicate: 'Sangat Memuaskan',
    yudisiumIpk: '3.50',
    applicationSnapshot: null,
    aplikasi: '',
    tagihan: '',
    unggahPendamping: '',
    buatUndangan: '',
  );
}

ConvocationInvitationCard _invitationCard() {
  return const ConvocationInvitationCard(
    invitationId: 'INV-1',
    invitationApiId: 'CI-1',
    convoId: 'C-1',
    invitationCardPath: '/undangan.pdf',
    photoPath: '/photo.jpg',
    qrPath: '/qr.png',
    createdAt: '2026-10-10',
    attendanceAt: '',
    attendanceStatus: '0',
  );
}
