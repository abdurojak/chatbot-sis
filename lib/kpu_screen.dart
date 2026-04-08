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
  const ExamSlipPage({super.key});

  @override
  State<ExamSlipPage> createState() => _ExamSlipPageState();
}

class _ExamSlipPageState extends State<ExamSlipPage> {
  List<dynamic> examData = [];
  bool isLoading = true;
  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    fetchExamSlips();
  }

  Future<void> fetchExamSlips() async {
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
        setState(() {
          examData = (data['body']['data'] as List)
              .where((element) => element['detail'] != null)
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exam slips: $e");
      setState(() => isLoading = false);
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

    Uint8List? photoBytes;
    if (headerInfo.$1 != null) {
      photoBytes = base64Decode(headerInfo.$1!.split(',').last);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Synchronous header component
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logoImage, width: 55, height: 55),
                pw.SizedBox(width: 15),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "FAKULTAS TEKNOLOGI INDUSTRI",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      "UNIVERSITAS TRISAKTI",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
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
            ),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Kartu Peserta Ujian",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            pw.SizedBox(height: 15),
            _buildPdfStudentBox(data, photoBytes),
            pw.SizedBox(height: 20),
            _buildPdfTable(data),
            pw.SizedBox(height: 30),
            pw.Text(
              "Jakarta, 16 March 2026",
              style: const pw.TextStyle(fontSize: 9),
            ),
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

    Uint8List? photoBytes;
    if (headerInfo.$1 != null) {
      photoBytes = base64Decode(headerInfo.$1!.split(',').last);
    }

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
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Halaman QR Code Ujian",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            pw.SizedBox(height: 15),
            _buildPdfStudentBox(data, photoBytes),
            pw.SizedBox(height: 20),

            // Grid QR Code sesuai gambar referensi Anda
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: details.map((e) {
                // final qrBytes = base64Decode(e['qr'].split(',').last);
                return pw.Container(
                  width: 110,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(
                    children: [
                      // pw.Image(pw.MemoryImage(qrBytes), width: 70, height: 70),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        e['kodemk'] ?? "",
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        e['namamk'] ?? "",
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                      pw.Text(
                        "${e['date']} ${e['start']}",
                        style: const pw.TextStyle(fontSize: 5),
                      ),
                      pw.Text(
                        e['room'] ?? "",
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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
                : pw.Center(child: pw.Text("FOTO")),
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
                  _pdfDataRow(
                    "Periode",
                    "${data['exam_name']} ${data['SemesterName']}",
                  ),
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
      data: List.generate((data['detail'] as List).length, (index) {
        final item = data['detail'][index];
        return [
          "${index + 1}.",
          item['kodemk'],
          item['namamk'],
          "3.00",
          item['date'],
          item['start'],
          item['room'],
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

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(child: _buildExamTable()),
                      _buildDownloadButton(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        "Semester",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        "Exam Type",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        "Kartu Peserta Ujian",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: examData.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = examData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['SemesterName'] ?? "-",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['exam_name'] ?? "-",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _actionButton(
                              "PDF",
                              const Color(0xFFF27878),
                              () => _generatePdf(item),
                            ),
                            const SizedBox(width: 6),
                            _actionButton(
                              "QR Code",
                              const Color(0xFFF27878),
                              () => _generateQrPdf(item),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 10),
      child: ElevatedButton(
        onPressed: examData.isEmpty ? null : () => _generatePdf(examData[0]),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: const Text("Download", style: TextStyle(fontSize: 14)),
      ),
    );
  }
}
