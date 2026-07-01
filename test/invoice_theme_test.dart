import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/get_invoice.dart';
import 'package:chatbot/models/invoice_models.dart';
import 'package:chatbot/services/invoice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);
  });

  testWidgets('invoice active cards use dark themed surfaces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePage(
          skipInitialLoad: true,
          initialDashboard: _dashboardData(),
        ),
      ),
    );

    final mainCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('SPP Semester'),
            matching: find.byType(Container),
          )
          .last,
    );
    final mainDecoration = mainCard.decoration! as BoxDecoration;

    final detailCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Biaya SKS'),
            matching: find.byType(Container),
          )
          .first,
    );
    final detailDecoration = detailCard.decoration! as BoxDecoration;

    expect(mainDecoration.color, AppThemePalette.surface);
    expect(detailDecoration.color, AppThemePalette.surfaceAlt);
  });

  testWidgets('invoice history and bottom action use dark themed colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePage(
          skipInitialLoad: true,
          initialDashboard: _dashboardData(),
        ),
      ),
    );

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    final historyCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Pembayaran Semester'),
            matching: find.byType(Container),
          )
          .first,
    );
    final historyDecoration = historyCard.decoration! as BoxDecoration;
    final historyTitle = tester.widget<Text>(find.text('Pembayaran Semester'));
    final bottomAction = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Buat Tagihan Baru'),
            matching: find.byType(Container),
          )
          .last,
    );

    expect(historyDecoration.color, AppThemePalette.surface);
    expect(historyTitle.style?.color, AppThemePalette.textPrimary);
    expect(bottomAction.color, AppThemePalette.surface);
  });

  testWidgets('DOKU payment card is hidden when there is no active invoice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePage(
          skipInitialLoad: true,
          initialDashboard: _emptyDashboardData(),
        ),
      ),
    );

    expect(find.text('Bayar via DOKU'), findsNothing);
    expect(find.text('Tidak ada tagihan aktif'), findsOneWidget);
  });
}

InvoiceDashboardData _dashboardData() {
  return const InvoiceDashboardData(
    invoices: InvoiceResponseData(
      singleInvoice: InvoiceRecord(
        description: 'SPP Semester',
        billNumber: 'INV-1',
        va: '880812345678',
        billAmount: '2500000',
        billBalance: '2500000',
        idInvoice: 'I-1',
        statusCalculate: '1',
      ),
      detailInvoices: [
        InvoiceRecord(
          description: 'Biaya SKS',
          billNumber: 'INV-1-DETAIL',
          va: '880812345678',
          billAmount: '1500000',
          billBalance: '1500000',
          idInvoice: 'I-2',
          statusCalculate: '1',
        ),
      ],
      camabaInvoices: [
        InvoiceRecord(
          description: 'Paket Camaba',
          billNumber: 'CAM-1',
          va: '880800000001',
          billAmount: '500000',
          billBalance: '500000',
          idInvoice: 'C-1',
          statusCalculate: '0',
        ),
      ],
    ),
    paymentHistory: [
      PaymentHistoryEntry(
        description: 'Pembayaran Semester',
        billNumber: 'PAY-1',
        billAmount: '2500000',
        billPaid: '2500000',
        discounts: [PaymentDiscount(description: 'Beasiswa', amount: '250000')],
        payments: [
          PaymentMethodInfo(
            paymentMode: 'Virtual Account',
            paymentDate: '2026-06-10 08:00:00',
          ),
        ],
      ),
    ],
    openInvoiceAction: OpenInvoiceAction(idSemester: '20252', idActivity: '1'),
  );
}

InvoiceDashboardData _emptyDashboardData() {
  return const InvoiceDashboardData(
    invoices: InvoiceResponseData(
      singleInvoice: null,
      detailInvoices: [],
      camabaInvoices: [],
    ),
    paymentHistory: [],
    openInvoiceAction: null,
  );
}
