import 'dart:convert';

import 'package:chatbot/models/invoice_models.dart';
import 'package:http/http.dart' as http;

class InvoiceDashboardData {
  final InvoiceResponseData invoices;
  final List<PaymentHistoryEntry> paymentHistory;
  final OpenInvoiceAction? openInvoiceAction;

  const InvoiceDashboardData({
    required this.invoices,
    required this.paymentHistory,
    required this.openInvoiceAction,
  });
}

class InvoiceService {
  static const String _baseUrl = 'https://sismob.trisakti.ac.id/api';

  static Future<InvoiceDashboardData> fetchDashboard({
    required String idLogin,
    required String token,
  }) async {
    final responses = await Future.wait([
      _post('/get-invoice', body: {'IdLogin': idLogin, 'token': token}),
      _post('/get-payment', body: {'IdLogin': idLogin, 'token': token}),
      _post('/cek-open-invoice', body: {'IdLogin': idLogin, 'token': token}),
    ]);

    final invoiceResponse = responses[0];
    final paymentResponse = responses[1];
    final openInvoiceResponse = responses[2];

    final invoices = InvoiceResponseData.fromJson(invoiceResponse);
    final paymentHistory = _parsePaymentHistory(paymentResponse);
    final openInvoiceAction = _parseOpenInvoice(openInvoiceResponse);

    return InvoiceDashboardData(
      invoices: invoices,
      paymentHistory: paymentHistory,
      openInvoiceAction: openInvoiceAction,
    );
  }

  static Future<bool> recalculateInvoice({
    required String idLogin,
    required String token,
    required List<String> invoiceIds,
  }) async {
    final response = await _post(
      '/recalculate-invoice',
      body: {'IdLogin': idLogin, 'token': token, 'idset': invoiceIds.join(',')},
    );

    return response['status'] == 200 && response['body'] != null;
  }

  static Future<GeneratedInvoiceBundle?> generateInvoice({
    required String idLogin,
    required String token,
    required String idSemester,
    required String idActivity,
  }) async {
    final response = await _post(
      '/generate-invoice',
      body: {
        'IdLogin': idLogin,
        'token': token,
        'IdSemester': idSemester,
        'idactivity': idActivity,
        'cuti': '',
      },
    );

    final result = GeneratedInvoiceResult.fromJson(
      Map<String, dynamic>.from(response['body'] ?? const {}),
    );
    return result.firstBundle;
  }

  static Future<ApproveInvoiceResponse> approveInvoice({
    required ApproveInvoiceRequest request,
  }) async {
    final response = await _post('/approve-invoice', body: request.toJson());

    return ApproveInvoiceResponse.fromJson(response);
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return json.decode(response.body) as Map<String, dynamic>;
  }

  static List<PaymentHistoryEntry> _parsePaymentHistory(
    Map<String, dynamic> json,
  ) {
    return ((json['body']?['data'] as List?) ?? [])
        .whereType<Map>()
        .map(
          (item) =>
              PaymentHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static OpenInvoiceAction? _parseOpenInvoice(Map<String, dynamic> json) {
    if (json['status'] == 200 && json['body'] != null) {
      return OpenInvoiceAction.fromJson(
        Map<String, dynamic>.from(json['body']),
      );
    }

    return null;
  }
}
