import 'dart:convert';

import 'package:chatbot/models/invoice_models.dart';
import 'package:http/http.dart' as http;

class NoDokuInvoiceException implements Exception {
  final String message;

  const NoDokuInvoiceException([this.message = 'Tidak ada tagihan']);

  @override
  String toString() => message;
}

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

  static Future<String> getDokuPaymentUrl({
    required String idLogin,
    required String token,
  }) async {
    final response = await _post(
      '/doku-get-payment-url',
      body: {'IdLogin': idLogin, 'token': token},
    );

    final responseStatus = response['status']?.toString();
    final responseMessage =
        response['data']?.toString() ??
        response['body']?['data']?.toString() ??
        '';
    if (responseStatus == '400' &&
        responseMessage.toLowerCase().contains('tidak ada tagihan')) {
      throw NoDokuInvoiceException(responseMessage);
    }

    final url = _parseDokuPaymentUrl(response);
    if (url.isEmpty) {
      throw const FormatException('URL pembayaran DOKU tidak ditemukan.');
    }
    return url;
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

    final parsedBody = _extractJsonObject(response.body);
    return json.decode(parsedBody) as Map<String, dynamic>;
  }

  static String _extractJsonObject(String responseBody) {
    final startIndex = responseBody.indexOf('{');
    final endIndex = responseBody.lastIndexOf('}');
    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return responseBody;
    }
    return responseBody.substring(startIndex, endIndex + 1);
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

  static String _parseDokuPaymentUrl(Map<String, dynamic> json) {
    final candidates = [
      json['payment']?['url'],
      json['body']?['payment']?['url'],
      json['body']?['data']?['payment']?['url'],
      json['body']?['data']?['response']?['payment']?['url'],
      json['body']?['data']?['url'],
      json['data']?['payment']?['url'],
      json['data']?['response']?['payment']?['url'],
      json['data']?['url'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.startsWith('http')) {
        return value;
      }
    }

    return _findHttpUrl(json);
  }

  static String _findHttpUrl(dynamic source) {
    if (source is Map) {
      for (final entry in source.entries) {
        if (entry.key.toString().toLowerCase() == 'url') {
          final value = entry.value?.toString().trim() ?? '';
          if (value.startsWith('http')) {
            return value;
          }
        }

        final nested = _findHttpUrl(entry.value);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    if (source is List) {
      for (final item in source) {
        final nested = _findHttpUrl(item);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return '';
  }
}
