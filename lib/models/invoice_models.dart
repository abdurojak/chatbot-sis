class InvoiceResponseData {
  final InvoiceRecord? singleInvoice;
  final List<InvoiceRecord> detailInvoices;
  final List<InvoiceRecord> camabaInvoices;

  const InvoiceResponseData({
    required this.singleInvoice,
    required this.detailInvoices,
    required this.camabaInvoices,
  });

  factory InvoiceResponseData.fromJson(Map<String, dynamic> json) {
    final data = json['body']?['data'] as Map<String, dynamic>?;

    return InvoiceResponseData(
      singleInvoice: data?['single_invoice'] is Map<String, dynamic>
          ? InvoiceRecord.fromJson(data!['single_invoice'])
          : null,
      detailInvoices: _mapInvoiceList(data?['detail']),
      camabaInvoices: _mapInvoiceList(data?['invoice_camaba']),
    );
  }

  static List<InvoiceRecord> _mapInvoiceList(dynamic source) {
    if (source is! List) return const [];

    return source
        .whereType<Map>()
        .map((item) => InvoiceRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class InvoiceRecord {
  final String description;
  final String billNumber;
  final String va;
  final String billAmount;
  final String billBalance;
  final String idInvoice;
  final String statusCalculate;

  const InvoiceRecord({
    required this.description,
    required this.billNumber,
    required this.va,
    required this.billAmount,
    required this.billBalance,
    required this.idInvoice,
    required this.statusCalculate,
  });

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceRecord(
      description: _readString(json['Description']),
      billNumber: _readString(json['bill_number']),
      va: _readString(json['va']),
      billAmount: _readString(json['bill_amount']),
      billBalance: _readString(json['bill_balance']),
      idInvoice: _readString(json['id_invoice']),
      statusCalculate: _readString(json['status_calculate']),
    );
  }

  InvoicePreviewData toPreviewData() {
    return InvoicePreviewData(
      description: description,
      billNumber: billNumber,
      va: va,
      billAmount: billAmount,
    );
  }

  double get billAmountValue => double.tryParse(billAmount) ?? 0;
  double get billBalanceValue => double.tryParse(billBalance) ?? 0;
  bool get isCalculated => statusCalculate == '1';
}

class InvoicePreviewData {
  final String description;
  final String billNumber;
  final String va;
  final String billAmount;

  const InvoicePreviewData({
    required this.description,
    required this.billNumber,
    required this.va,
    required this.billAmount,
  });
}

class OpenInvoiceAction {
  final String idSemester;
  final String idActivity;

  const OpenInvoiceAction({required this.idSemester, required this.idActivity});

  factory OpenInvoiceAction.fromJson(Map<String, dynamic> json) {
    return OpenInvoiceAction(
      idSemester: _readString(json['IdSemester']),
      idActivity: _readString(json['id_activity']),
    );
  }
}

class PaymentHistoryEntry {
  final String description;
  final String billNumber;
  final String billAmount;
  final String billPaid;
  final List<PaymentDiscount> discounts;
  final List<PaymentMethodInfo> payments;

  const PaymentHistoryEntry({
    required this.description,
    required this.billNumber,
    required this.billAmount,
    required this.billPaid,
    required this.discounts,
    required this.payments,
  });

  factory PaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryEntry(
      description: _readString(json['Description']),
      billNumber: _readString(json['bill_number']),
      billAmount: _readString(json['bill_amount']),
      billPaid: _readString(json['bill_paid']),
      discounts: _mapDiscounts(json['cn']),
      payments: _mapPayments(json['payment']),
    );
  }

  static List<PaymentDiscount> _mapDiscounts(dynamic source) {
    if (source is! List) return const [];

    return source
        .whereType<Map>()
        .map(
          (item) => PaymentDiscount.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static List<PaymentMethodInfo> _mapPayments(dynamic source) {
    if (source is! List) return const [];

    return source
        .whereType<Map>()
        .map(
          (item) => PaymentMethodInfo.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

class PaymentDiscount {
  final String description;
  final String amount;

  const PaymentDiscount({required this.description, required this.amount});

  factory PaymentDiscount.fromJson(Map<String, dynamic> json) {
    return PaymentDiscount(
      description: _readString(json['cn_desc']),
      amount: _readString(json['amount']),
    );
  }
}

class PaymentMethodInfo {
  final String paymentMode;
  final String paymentDate;

  const PaymentMethodInfo({
    required this.paymentMode,
    required this.paymentDate,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      paymentMode: _readString(json['payment_mode']),
      paymentDate: _readString(json['payment_date']),
    );
  }
}

String _readString(dynamic value) => value?.toString() ?? '';
