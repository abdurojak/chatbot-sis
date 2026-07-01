import 'dart:convert';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/invoice_models.dart';
import 'package:chatbot/services/invoice_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur salin VA
import 'package:intl/intl.dart'; // Untuk format rupiah
import 'package:webview_flutter/webview_flutter.dart';

class InvoicePage extends StatefulWidget {
  final bool skipInitialLoad;
  final InvoiceDashboardData? initialDashboard;

  const InvoicePage({
    super.key,
    this.skipInitialLoad = false,
    this.initialDashboard,
  });

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  Color get primaryBlue => AppThemePalette.primary;
  bool isLoading = true;
  List invoiceList = [];
  // --- TAMBAHKAN INI ---
  bool canGenerateInvoice = false;
  bool isLoadingDoku = false;
  OpenInvoiceAction? openInvoiceData;
  InvoiceRecord? singleInvoice;
  List<InvoiceRecord> detailInvoices = [];
  List<InvoiceRecord> camabaInvoices = [];
  List<PaymentHistoryEntry> paymentHistory =
      []; // Untuk menyimpan data dari api/get-payment-history
  List<int> selectedDetailIndexes =
      []; // Menyimpan index dari detailInvoices yang dicentang
  // --------------------

  @override
  void initState() {
    super.initState();
    final dashboard = widget.initialDashboard;
    if (dashboard != null) {
      _applyDashboard(dashboard);
    }
    if (widget.skipInitialLoad) {
      isLoading = false;
    } else {
      fetchInvoices();
    }
  }

  void _applyDashboard(InvoiceDashboardData dashboard) {
    singleInvoice = dashboard.invoices.singleInvoice;
    detailInvoices = dashboard.invoices.detailInvoices;
    camabaInvoices = dashboard.invoices.camabaInvoices;
    paymentHistory = dashboard.paymentHistory;
    openInvoiceData = dashboard.openInvoiceAction;
    canGenerateInvoice = dashboard.openInvoiceAction != null;

    selectedDetailIndexes = [
      for (int i = 0; i < detailInvoices.length; i++)
        if (detailInvoices[i].isCalculated) i,
    ];
  }

  Future<void> fetchInvoices() async {
    setState(() => isLoading = true);
    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final dashboard = await InvoiceService.fetchDashboard(
        idLogin: session.idLogin,
        token: session.token,
      );
      if (!mounted) return;

      setState(() => _applyDashboard(dashboard));
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Menghitung total Debit dari item yang dicentang
  double get totalSelectedDebit {
    double total = 0;
    for (int index in selectedDetailIndexes) {
      total += detailInvoices[index].billAmountValue;
    }
    return total;
  }

  // Menghitung total Balance dari item yang dicentang
  double get totalSelectedBalance {
    double total = 0;
    for (int index in selectedDetailIndexes) {
      total += detailInvoices[index].billBalanceValue;
    }
    return total;
  }

  bool get hasActiveInvoice =>
      singleInvoice != null || camabaInvoices.isNotEmpty;

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // User tidak bisa menutup modal dengan klik di luar
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppThemePalette.surface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: CircularProgressIndicator(
            color:
                primaryBlue, // Ganti ke primaryRed jika kamu masih pakai variabel merah
          ),
        ),
      ),
    );
  }

  Future<void> _handleRecalculate() async {
    _showLoading(); // Tampilkan loading spinner

    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar("Sesi login tidak ditemukan");
      return;
    }

    List<String> selectedInvoiceIds = selectedDetailIndexes.map((index) {
      return detailInvoices[index].idInvoice;
    }).toList();

    try {
      final success = await InvoiceService.recalculateInvoice(
        idLogin: session.idLogin,
        token: session.token,
        invoiceIds: selectedInvoiceIds,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading spinner

      if (success) {
        await fetchInvoices();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("VA Berhasil Diperbarui"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar("Gagal memperbarui VA");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar("Terjadi kesalahan jaringan");
    }
  }

  // Helper untuk pesan error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryBlue),
    );
  }

  Future<void> _openDokuCheckout() async {
    if (isLoadingDoku) return;

    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      _showErrorSnackBar("Sesi login tidak ditemukan");
      return;
    }

    setState(() => isLoadingDoku = true);

    try {
      final paymentUrl = await InvoiceService.getDokuPaymentUrl(
        idLogin: session.idLogin,
        token: session.token,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _DokuCheckoutDialog(paymentUrl: paymentUrl),
      );
    } on NoDokuInvoiceException catch (e) {
      if (!mounted) return;
      _showInfoSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("Gagal membuka pembayaran DOKU: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingDoku = false);
      }
    }
  }

  Widget _buildMainInvoiceCard() {
    // Tentukan apakah kita pakai data akumulasi atau data default
    bool hasSelection = selectedDetailIndexes.isNotEmpty;

    String displayDebit = hasSelection
        ? formatRupiah(totalSelectedDebit)
        : formatRupiah(0);

    String displayBalance = hasSelection
        ? formatRupiah(totalSelectedBalance)
        : formatRupiah(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        border: Border.all(color: primaryBlue.withAlpha(128)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppThemePalette.shadow, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  singleInvoice!.description.isEmpty
                      ? "-"
                      : singleInvoice!.description,
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: AppThemePalette.divider,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowInfo("Invoice", singleInvoice!.billNumber),
                    // Tampilan yang otomatis update
                    _rowInfo("Debit Amount", displayDebit),
                    _rowInfo("Balance", displayBalance),
                    // TOMBOL HITUNG SINGLE VA
                    ElevatedButton(
                      onPressed: () {
                        final accumulationData = InvoicePreviewData(
                          description: 'Accumulated Single VA',
                          billNumber: singleInvoice!.billNumber,
                          va: singleInvoice!.va,
                          billAmount: totalSelectedDebit.toString(),
                        );

                        _showDetailModal(
                          hasSelection
                              ? accumulationData
                              : singleInvoice!.toPreviewData(),
                          title: "Rincian Pembayaran VA",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue.withValues(alpha: 220),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(Icons.preview, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            "Tampilkan VA",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(
            detailInvoices.length,
            (index) => _buildDetailItemCard(detailInvoices[index], index),
          ),
          const SizedBox(height: 15),

          // TOMBOL HITUNG ULANG VA
          ElevatedButton(
            onPressed: selectedDetailIndexes.isEmpty
                ? null // Nonaktifkan jika tidak ada yang dicentang
                : () => _handleRecalculate(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate, size: 16),
                const SizedBox(width: 6),
                const Text(
                  "Hitung Ulang VA",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ubah pemanggilan di dalam build() atau ganti fungsi _checkOpenInvoice menjadi ini:
  void _handleCreateInvoice() {
    if (openInvoiceData != null) {
      _generateInvoice(
        openInvoiceData!.idSemester,
        openInvoiceData!.idActivity,
      );
    }
  }

  Future<void> _generateInvoice(String idSemester, String idActivity) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar("Sesi login tidak ditemukan");
      return;
    }

    try {
      final result = await InvoiceService.generateInvoice(
        idLogin: session.idLogin,
        token: session.token,
        idSemester: idSemester,
        idActivity: idActivity,
      );

      if (mounted) Navigator.pop(context); // Tutup loading
      if (!mounted) return;

      if (result != null) {
        _showResultModal(true, "Rincian biaya berhasil ditarik", result);
      } else {
        _showResultModal(false, "Rincian biaya tidak ditemukan", null);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error Generate: $e");
    }
  }

  /// Fungsi untuk menyetujui tagihan (Hit API approve-invoice)
  Future<void> _approveInvoice(GeneratedInvoiceBundle invoiceData) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar("Sesi login tidak ditemukan");
      return;
    }

    final requestBody = ApproveInvoiceRequest.fromGeneratedBundle(
      bundle: invoiceData,
      token: session.token,
      idLogin: session.idLogin,
    );

    try {
      final resData = await InvoiceService.approveInvoice(request: requestBody);

      if (mounted) Navigator.pop(context);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resData.message.isEmpty
                ? "Tagihan Berhasil Dibuat!"
                : resData.message,
          ),
          backgroundColor: Colors.green,
        ),
      );
      fetchInvoices();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error Approve: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailModal(
    InvoicePreviewData data, {
    String title = "Rincian Tagihan",
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                fontSize: 16,
              ),
            ),
            Divider(color: AppThemePalette.divider),
            _rowModal("Deskripsi", data.description),
            _rowModal("No. Invoice", data.billNumber),

            const SizedBox(height: 10),
            // --- BAGIAN VA YANG DI HIGHLIGHT ---
            Text(
              "Virtual Account",
              style: TextStyle(
                fontSize: 10,
                color: AppThemePalette.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            _buildCopyableVA(data.va),

            const SizedBox(height: 10),
            _rowModal("Total", formatRupiah(data.billAmount)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                child: const Text(
                  "Tutup",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowModal(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppThemePalette.textTertiary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppThemePalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showResultModal(
    bool isSuccess,
    String message,
    GeneratedInvoiceBundle? invoiceData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Agar modal bisa menyesuaikan tinggi isi rincian
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bundleItems = invoiceData?.bundleItems ?? const [];
        final totalAmount = invoiceData?.totalAmount ?? 0;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              color: AppThemePalette.surface,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppThemePalette.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      isSuccess
                          ? Icons.receipt_long
                          : Icons.warning_amber_rounded,
                      size: 50,
                      color: isSuccess ? primaryBlue : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSuccess ? "Rincian Tagihan Baru" : "Informasi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppThemePalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemePalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      isSuccess == true
                          ? (invoiceData?.semesterMainName.isNotEmpty ?? false)
                                ? invoiceData!.semesterMainName
                                : "-"
                          : "-",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemePalette.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Divider(height: 32, color: AppThemePalette.divider),

                    if (isSuccess && invoiceData != null) ...[
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: bundleItems.length,
                          itemBuilder: (context, index) {
                            final item = bundleItems[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.fiName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppThemePalette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(item.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppThemePalette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(color: AppThemePalette.divider),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Estimasi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppThemePalette.textPrimary,
                            ),
                          ),
                          Text(
                            formatRupiah(totalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup modal rincian
                          // LANGKAH 3: Jalankan Approve dengan mengirim data lengkap invoiceData
                          _approveInvoice(invoiceData);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Setujui Tagihan"),
                      ),
                    ] else ...[
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Kembali",
                          style: TextStyle(color: primaryBlue),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String formatRupiah(dynamic amount) {
    final number = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppThemePalette.background,
        appBar: AppBar(
          title: const Text("Account Statement"),
          backgroundColor: AppThemePalette.topBar,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white, // Warna garis bawah tab aktif
            labelColor: Colors.white, // Warna teks saat tab dipilih
            unselectedLabelColor: Colors
                .white70, // Warna teks saat tab tidak dipilih (agak pudar)
            indicatorWeight: 3, // Ketebalan garis bawah (opsional)
            tabs: [
              Tab(text: "Tagihan Aktif"),
              Tab(text: "Riwayat"),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : TabBarView(
                children: [
                  // TAB 1: TAGIHAN AKTIF (Kode yang sudah kita buat sebelumnya)
                  _buildActiveInvoiceTab(),

                  // TAB 2: RIWAYAT PEMBAYARAN
                  _buildHistoryTab(),
                ],
              ),
        bottomNavigationBar: canGenerateInvoice ? _buildBottomAction() : null,
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (paymentHistory.isEmpty) {
      return Center(
        child: Text(
          "Belum ada riwayat pembayaran",
          style: TextStyle(color: AppThemePalette.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final item = paymentHistory[index];
        final cnList = item.discounts;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppThemePalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBlue.withAlpha(128)),
            boxShadow: [
              BoxShadow(
                color: AppThemePalette.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.description.isEmpty ? "-" : item.description,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppThemePalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: AppThemePalette.divider),
              _rowHistoryDetail("No. Tagihan", item.billNumber),
              _rowHistoryDetail("Total Tagihan", formatRupiah(item.billAmount)),

              // TAMPILKAN CN (POTONGAN) JIKA ADA
              if (cnList.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "Potongan / Beasiswa:",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppThemePalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                // Looping semua isi CN
                ...cnList.map(
                  (cn) => _rowHistoryDetail(
                    cn.description.isEmpty ? "Potongan" : cn.description,
                    "- ${formatRupiah(cn.amount)}",
                    color: Colors.red,
                  ),
                ),
              ],

              Divider(height: 24, color: AppThemePalette.divider),
              _rowHistoryDetail(
                "Total Dibayar",
                formatRupiah(item.billPaid),
                isBold: true,
                color: Colors.green,
              ),

              if (item.payments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Metode: ${item.payments.first.paymentMode} • ${item.payments.first.paymentDate.split(' ').first}",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppThemePalette.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _rowHistoryDetail(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppThemePalette.textTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? AppThemePalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppThemePalette.surface,
      child: ElevatedButton(
        onPressed: _handleCreateInvoice,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text("Buat Tagihan Baru"),
      ),
    );
  }

  // Widget untuk baris informasi (Tanggal, Invoice, dll)
  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: AppThemePalette.textSecondary),
          children: [
            TextSpan(
              text: "$label : ",
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppThemePalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk item rincian dengan checkbox (BPP Pokok, SKS, dll)
  Widget _buildActiveInvoiceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (hasActiveInvoice) ...[
          _buildDokuPaymentCard(),
          const SizedBox(height: 16),
        ],
        if (singleInvoice != null) _buildMainInvoiceCard(),
        if (camabaInvoices.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...camabaInvoices.map((item) => _buildCamabaCard(item)),
        ],
        if (singleInvoice == null && camabaInvoices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Text(
                "Tidak ada tagihan aktif",
                style: TextStyle(color: AppThemePalette.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDokuPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppThemePalette.soft(0.82),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.payments_rounded, color: primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bayar via DOKU",
                  style: TextStyle(
                    color: AppThemePalette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Buka checkout DOKU dalam popup.",
                  style: TextStyle(
                    color: AppThemePalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isLoadingDoku ? null : _openDokuCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: isLoadingDoku
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Bayar",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableVA(String? va) {
    final String vaText = (va == null || va.isEmpty) ? "-" : va;
    bool isAvailable = vaText != "-";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppThemePalette.soft(0.84)
            : AppThemePalette.mutedSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAvailable
              ? primaryBlue.withAlpha(77)
              : AppThemePalette.divider,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SelectableText(
            vaText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isAvailable ? primaryBlue : AppThemePalette.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          if (isAvailable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: vaText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("VA berhasil disalin!"),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Icon(Icons.copy, size: 18, color: primaryBlue),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItemCard(InvoiceRecord item, int index) {
    bool isSelected = selectedDetailIndexes.contains(index);

    return GestureDetector(
      onTap: () =>
          _showDetailModal(item.toPreviewData()), // Klik teks/kartu buka modal
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemePalette.surfaceAlt,
          border: Border.all(color: primaryBlue.withAlpha(77)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: AppThemePalette.shadow, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: primaryBlue,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedDetailIndexes.add(index);
                  } else {
                    selectedDetailIndexes.remove(index);
                  }
                });
              },
            ),
            Expanded(
              child: Text(
                item.description,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppThemePalette.textPrimary,
                ),
              ),
            ),
            Text(
              formatRupiah(item.billAmount),
              style: TextStyle(
                fontSize: 10,
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamabaCard(InvoiceRecord item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.description.isEmpty ? "Paket Camaba" : item.description,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppThemePalette.divider,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowInfo("Invoice", item.billNumber),
                _rowInfo("Balance", formatRupiah(item.billBalance)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DokuCheckoutDialog extends StatefulWidget {
  final String paymentUrl;

  const _DokuCheckoutDialog({required this.paymentUrl});

  @override
  State<_DokuCheckoutDialog> createState() => _DokuCheckoutDialogState();
}

class _DokuCheckoutDialogState extends State<_DokuCheckoutDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadHtmlString(_buildCheckoutHtml(widget.paymentUrl));
  }

  Future<void> _refreshCheckout() async {
    setState(() => _isLoading = true);
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      backgroundColor: AppThemePalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.76,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                color: AppThemePalette.surface,
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: AppThemePalette.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pembayaran DOKU',
                        style: TextStyle(
                          color: AppThemePalette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _refreshCheckout,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: AppThemePalette.textSecondary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppThemePalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppThemePalette.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildCheckoutHtml(String paymentUrl) {
    final encodedUrl = jsonEncode(paymentUrl);
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://sandbox.doku.com/jokul-checkout-js/v1/jokul-checkout-1.0.0.js"></script>
    <style>
      html, body {
        margin: 0;
        min-height: 100%;
        font-family: Arial, sans-serif;
        background: #f6f8fc;
      }
      .wrap {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        box-sizing: border-box;
      }
      .card {
        width: 100%;
        max-width: 360px;
        padding: 28px 22px;
        border-radius: 22px;
        background: white;
        box-shadow: 0 16px 40px rgba(15, 23, 42, 0.14);
        text-align: center;
      }
      h3 {
        margin: 0 0 8px;
        color: #111827;
      }
      p {
        margin: 0 0 22px;
        color: #64748b;
        line-height: 1.45;
        font-size: 14px;
      }
      #checkout-button {
        width: 100%;
        border: 0;
        border-radius: 14px;
        padding: 15px 18px;
        color: white;
        background: #0f62fe;
        font-size: 15px;
        font-weight: 700;
      }
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="card">
        <h3>DOKU Checkout</h3>
        <p>Tekan tombol di bawah untuk melanjutkan pembayaran melalui DOKU.</p>
        <button id="checkout-button">Checkout Now</button>
      </div>
    </div>
    <script type="text/javascript">
      var checkoutButton = document.getElementById('checkout-button');
      checkoutButton.addEventListener('click', function () {
        loadJokulCheckout($encodedUrl);
      });
    </script>
  </body>
</html>
''';
  }
}
