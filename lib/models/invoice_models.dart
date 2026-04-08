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

class GeneratedInvoiceResult {
  final List<GeneratedInvoiceBundle> bundles;

  const GeneratedInvoiceResult({required this.bundles});

  factory GeneratedInvoiceResult.fromJson(Map<String, dynamic> json) {
    final rawBundles = json['data'];
    if (rawBundles is! List) {
      return const GeneratedInvoiceResult(bundles: []);
    }

    return GeneratedInvoiceResult(
      bundles: rawBundles
          .whereType<Map>()
          .map(
            (item) => GeneratedInvoiceBundle.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  GeneratedInvoiceBundle? get firstBundle =>
      bundles.isEmpty ? null : bundles.first;
}

class GeneratedInvoiceBundle {
  final String semesterMainName;
  final String idSemesterMaster;
  final String description;
  final String idActivity;
  final String fsId;
  final String idCalendar;
  final List<GeneratedInvoiceItem> bundleItems;

  const GeneratedInvoiceBundle({
    required this.semesterMainName,
    required this.idSemesterMaster,
    required this.description,
    required this.idActivity,
    required this.fsId,
    required this.idCalendar,
    required this.bundleItems,
  });

  factory GeneratedInvoiceBundle.fromJson(Map<String, dynamic> json) {
    final rawBundleDetail = json['bundledetail'];
    final items = <GeneratedInvoiceItem>[];

    if (rawBundleDetail is Map) {
      for (final entry in rawBundleDetail.entries) {
        final value = entry.value;
        if (value is Map) {
          items.add(
            GeneratedInvoiceItem.fromJson(Map<String, dynamic>.from(value)),
          );
        }
      }
    }

    return GeneratedInvoiceBundle(
      semesterMainName: _readString(json['SemesterMainName']),
      idSemesterMaster: _readString(json['IdSemesterMaster']),
      description: _readString(json['descriptiom']),
      idActivity: _readString(json['idActivity']),
      fsId: _readString(json['fs_id']),
      idCalendar: _readString(json['id_calendar']),
      bundleItems: items,
    );
  }

  double get totalAmount =>
      bundleItems.fold(0, (sum, item) => sum + item.amountValue);
}

class GeneratedInvoiceItem {
  final String fiId;
  final String fiName;
  final String fiNameShort;
  final String amount;

  const GeneratedInvoiceItem({
    required this.fiId,
    required this.fiName,
    required this.fiNameShort,
    required this.amount,
  });

  factory GeneratedInvoiceItem.fromJson(Map<String, dynamic> json) {
    return GeneratedInvoiceItem(
      fiId: _readString(json['fi_id']),
      fiName: _readString(json['fi_name']),
      fiNameShort: _readString(json['fi_name_short']),
      amount: _readString(json['amount']),
    );
  }

  double get amountValue => double.tryParse(amount) ?? 0;
}

class ApproveInvoiceRequest {
  final String token;
  final String idLogin;
  final String idSemester;
  final String description;
  final String close;
  final String idActivity;
  final String payment;
  final String idInvoice;
  final String fsId;
  final String idCalendar;
  final List<ApproveInvoiceItem> items;
  final List<ApproveInvoiceDiscount> discounts;

  const ApproveInvoiceRequest({
    required this.token,
    required this.idLogin,
    required this.idSemester,
    required this.description,
    required this.close,
    required this.idActivity,
    required this.payment,
    required this.idInvoice,
    required this.fsId,
    required this.idCalendar,
    required this.items,
    required this.discounts,
  });

  factory ApproveInvoiceRequest.fromGeneratedBundle({
    required GeneratedInvoiceBundle bundle,
    required String token,
    required String idLogin,
  }) {
    return ApproveInvoiceRequest(
      token: token,
      idLogin: idLogin,
      idSemester: bundle.idSemesterMaster,
      description: bundle.description,
      close: 'c',
      idActivity: bundle.idActivity,
      payment: '1',
      idInvoice: '',
      fsId: bundle.fsId,
      idCalendar: bundle.idCalendar.isEmpty ? '9527' : bundle.idCalendar,
      items: bundle.bundleItems
          .map(
            (item) => ApproveInvoiceItem(
              fiId: item.fiId,
              fiName: item.fiName,
              fiNameShort: item.fiNameShort,
              amount: item.amount,
            ),
          )
          .toList(),
      discounts: const [
        ApproveInvoiceDiscount(
          idDiscount: '1',
          items: [
            ApproveInvoiceDiscountItem(fiId: '2', amount: '2000'),
            ApproveInvoiceDiscountItem(fiId: '11', amount: '4000'),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'IdLogin': idLogin,
      'IdSemester': idSemester,
      'description': description,
      'close': close,
      'idactivity': idActivity,
      'payment': payment,
      'idinvoice': idInvoice,
      'fs_id': fsId,
      'id_calendar': idCalendar,
      'item': items.map((item) => item.toJson()).toList(),
      'discount': discounts.map((discount) => discount.toJson()).toList(),
    };
  }
}

class ApproveInvoiceItem {
  final String fiId;
  final String fiName;
  final String fiNameShort;
  final String amount;

  const ApproveInvoiceItem({
    required this.fiId,
    required this.fiName,
    required this.fiNameShort,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'fi_id': fiId,
      'fi_name': fiName,
      'fi_name_short': fiNameShort,
      'amount': amount,
    };
  }
}

class ApproveInvoiceDiscount {
  final String idDiscount;
  final List<ApproveInvoiceDiscountItem> items;

  const ApproveInvoiceDiscount({required this.idDiscount, required this.items});

  Map<String, dynamic> toJson() {
    return {
      'id_discount': idDiscount,
      'item': items.map((item) => item.toJson()).toList(),
    };
  }
}

class ApproveInvoiceDiscountItem {
  final String fiId;
  final String amount;

  const ApproveInvoiceDiscountItem({required this.fiId, required this.amount});

  Map<String, dynamic> toJson() {
    return {'fi_id': fiId, 'amount': amount};
  }
}

class ApproveInvoiceResponse {
  final String message;

  const ApproveInvoiceResponse({required this.message});

  factory ApproveInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return ApproveInvoiceResponse(
      message: _readString(json['body']?['message']),
    );
  }
}

String _readString(dynamic value) => value?.toString() ?? '';
