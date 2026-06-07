import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class ExamSlipPage extends StatefulWidget {
  const ExamSlipPage({
    super.key,
    this.initialExamData,
    this.skipInitialFetch = false,
  });

  final List<dynamic>? initialExamData;
  final bool skipInitialFetch;

  @override
  State<ExamSlipPage> createState() => _ExamSlipPageState();
}

class _ExamSlipPageState extends State<ExamSlipPage> {
  List<dynamic> examData = [];
  bool isLoading = true;
  bool hasError = false;
  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    if (widget.initialExamData != null) {
      examData = widget.initialExamData!;
    }
    if (widget.skipInitialFetch) {
      isLoading = false;
    } else {
      fetchExamSlips();
    }
  }

  Future<void> fetchExamSlips() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final session = await AuthStorage.loadSession();
      if (session == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/exam-slip'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": session.idLogin, "token": session.token}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseData = (data['body'] as Map?)?['data'] ?? [];
        setState(() {
          examData = (responseData as List)
              .where((element) => element['detail'] != null)
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exam slips: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<(String?, String?)> _loadHeaderData() async {
    final session = await AuthStorage.loadSession();
    return (session?.photoBase64, session?.nim);
  }

  // --- REUSABLE PDF COMPONENTS ---
  // Fungsi ini supaya kita tidak menulis ulang header PDF di dua tempat berbeda
  Future<pw.Widget> _buildPdfHeaderComponent(pw.MemoryImage logo) async {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, width: 55, height: 55),
        pw.SizedBox(width: 15),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "FAKULTAS TEKNOLOGI INDUSTRI",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.Text(
              "UNIVERSITAS TRISAKTI",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.Text(
              "KAMPUS A, GEDUNG F&G LT. 4 KABAG TU FTI",
              style: pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              "Telp: 62-21-5663232, Email: fti@trisakti.ac.id",
              style: pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  // --- 1. GENERATE PDF KARTU (Standard) ---
  Future<void> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final headerInfo = await _loadHeaderData();
    final logoBytes = await rootBundle
        .load('assets/images/logo_trisakti_black.png')
        .then((d) => d.buffer.asUint8List());
    final logoImage = pw.MemoryImage(logoBytes);

    final photoBytes = _decodeBase64Image(headerInfo.$1);
    final pdfHeaderWidget = await _buildPdfHeaderComponent(logoImage);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pdfHeaderWidget,
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1.4),
            pw.SizedBox(height: 14),
            _buildPdfTitle("KARTU PESERTA UJIAN", _periodLabel(data)),
            pw.SizedBox(height: 14),
            _buildPdfStudentBox(data, photoBytes),
            pw.SizedBox(height: 18),
            _buildPdfTable(data),
            pw.Spacer(),
            _buildPdfSignature(),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // --- 2. GENERATE PDF QR CODE (Halaman Berbeda) ---
  Future<void> _generateQrPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final headerInfo = await _loadHeaderData();
    final logoBytes = await rootBundle
        .load('assets/images/logo_trisakti_black.png')
        .then((d) => d.buffer.asUint8List());
    final logoImage = pw.MemoryImage(logoBytes);
    final List<dynamic> details = data['detail'] ?? [];

    final photoBytes = _decodeBase64Image(headerInfo.$1);

    // Await the header widget before building the page
    final pdfHeaderWidget = await _buildPdfHeaderComponent(logoImage);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          children: [
            pdfHeaderWidget,
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 14),
            _buildPdfTitle("HALAMAN QR CODE UJIAN", _periodLabel(data)),
            pw.SizedBox(height: 15),
            _buildPdfStudentBox(data, photoBytes),
            pw.SizedBox(height: 20),

            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: details.map((e) {
                return _buildPdfQrCard(e);
              }).toList(),
            ),
            pw.Spacer(),
            _buildPdfSignature(),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // --- PDF HELPER WIDGETS ---
  pw.Widget _buildPdfStudentBox(
    Map<String, dynamic> data,
    Uint8List? photoBytes,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Row(
        children: [
          pw.Container(
            width: 80,
            height: 100,
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(width: 0.5)),
            ),
            child: photoBytes != null
                ? pw.Image(pw.MemoryImage(photoBytes), fit: pw.BoxFit.cover)
                : pw.Center(
                    child: pw.Text(
                      "FOTO",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Table(
                columnWidths: {0: const pw.FixedColumnWidth(80)},
                children: [
                  _pdfDataRow("NIM", data['nim'] ?? "-"),
                  _pdfDataRow("Nama", data['name'] ?? "-"),
                  _pdfDataRow("Program Studi", data['prodi'] ?? "-"),
                  _pdfDataRow("Periode", _periodLabel(data)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable(Map<String, dynamic> data) {
    return pw.TableHelper.fromTextArray(
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColor(0.93, 0.96, 1)),
      border: pw.TableBorder.all(width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      headers: [
        'No',
        'Kode',
        'Nama Matakuliah',
        'SKS',
        'Tanggal',
        'Waktu',
        'Ruang',
        'TTD',
      ],
      data: List.generate((data['detail'] as List? ?? []).length, (index) {
        final item = (data['detail'] as List)[index];
        return [
          "${index + 1}.",
          _safeText(item['kodemk']),
          _safeText(item['namamk']),
          _safeText(item['sks'], fallback: "3"),
          _safeText(item['date']),
          _safeText(item['start']),
          _safeText(item['room']),
          "",
        ];
      }),
    );
  }

  pw.TableRow _pdfDataRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Text(": $value", style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTitle(String title, String period) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.Text(
            period,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfQrCard(dynamic detail) {
    final qrBytes = _decodeBase64Image(detail['qr']?.toString());

    return pw.Container(
      width: 118,
      height: 142,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (qrBytes != null)
            pw.Image(pw.MemoryImage(qrBytes), width: 68, height: 68)
          else
            pw.Container(
              width: 68,
              height: 68,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                color: const PdfColor(0.95, 0.95, 0.95),
              ),
              child: pw.Center(
                child: pw.Text("QR", style: const pw.TextStyle(fontSize: 12)),
              ),
            ),
          pw.SizedBox(height: 6),
          pw.Text(
            _safeText(detail['kodemk']),
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _safeText(detail['namamk']),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            style: const pw.TextStyle(fontSize: 6),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            "${_safeText(detail['date'])} ${_safeText(detail['start'])}",
            style: const pw.TextStyle(fontSize: 5),
          ),
          pw.Text(
            _safeText(detail['room']),
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSignature() {
    final now = DateTime.now();
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 170,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              "Jakarta, ${now.day}/${now.month}/${now.year}",
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 48),
            pw.Container(height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(
              "Petugas Akademik",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text(
          "Kartu Peserta Ujian",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (hasError) {
      return _buildMessageState(
        icon: Icons.wifi_off_rounded,
        title: "Gagal memuat kartu ujian",
        message: "Periksa koneksi internet kamu, lalu coba muat ulang.",
      );
    }

    if (examData.isEmpty) {
      return _buildMessageState(
        icon: Icons.assignment_outlined,
        title: "Belum ada kartu ujian",
        message: "Kartu peserta ujian akan muncul saat periode ujian tersedia.",
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBand(),
          const SizedBox(height: 14),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          Text(
            "Periode Ujian",
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in examData) _buildExamCard(item),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 14),
          Text(
            "Memuat kartu ujian...",
            style: TextStyle(color: AppThemePalette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBand() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryBlue, AppThemePalette.dark()]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.assignment_turned_in_outlined, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            "Kartu Peserta Ujian",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pilih periode ujian, lalu unduh kartu atau halaman QR sesuai kebutuhan.",
            style: TextStyle(color: Colors.white.withAlpha(220), height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePalette.divider),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryMetric(
              value: examData.length.toString(),
              label: "periode tersedia",
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryMetric(
              value: _totalSubjects().toString(),
              label: "mata kuliah",
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePalette.soft(0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(dynamic item) {
    final detailCount = _detailCount(item);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePalette.divider),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safeText(item['exam_name']),
                        style: TextStyle(
                          color: AppThemePalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _safeText(item['SemesterName']),
                        style: TextStyle(
                          color: AppThemePalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: _cardMeta(
                    label: "Jadwal",
                    value: "$detailCount mata kuliah",
                    icon: Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _cardMeta(
                    label: "Mulai",
                    value: _firstExamDate(item),
                    icon: Icons.event_outlined,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppThemePalette.divider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: "Kartu PDF",
                    onTap: () => _generatePdf(item),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    icon: Icons.qr_code_2_outlined,
                    label: "QR Ujian",
                    isSecondary: true,
                    onTap: () => _generateQrPdf(item),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppThemePalette.negativeSoft(0.86),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "Siap",
        style: TextStyle(
          color: AppThemePalette.negative(),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _cardMeta({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppThemePalette.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppThemePalette.textTertiary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppThemePalette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final foreground = isSecondary ? primaryBlue : AppThemePalette.onPrimary();
    final background = isSecondary ? AppThemePalette.soft(0.88) : primaryBlue;

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppThemePalette.textTertiary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemePalette.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: widget.skipInitialFetch ? null : fetchExamSlips,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Muat Ulang"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _totalSubjects() {
    return examData.fold<int>(0, (total, item) => total + _detailCount(item));
  }

  int _detailCount(dynamic item) {
    final detail = item['detail'];
    return detail is List ? detail.length : 0;
  }

  String _firstExamDate(dynamic item) {
    final detail = item['detail'];
    if (detail is! List || detail.isEmpty) return "-";
    return _safeText(detail.first['date']);
  }

  String _periodLabel(Map<String, dynamic> data) {
    final examName = _safeText(data['exam_name']);
    final semester = _safeText(data['SemesterName']);
    if (examName == "-" && semester == "-") return "-";
    if (examName == "-") return semester;
    if (semester == "-") return examName;
    return "$examName $semester";
  }

  String _safeText(dynamic value, {String fallback = "-"}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  Uint8List? _decodeBase64Image(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    try {
      return base64Decode(source.split(',').last);
    } catch (_) {
      return null;
    }
  }
}
