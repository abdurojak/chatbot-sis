import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur salin VA
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Untuk format rupiah

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  Color get primaryBlue => AppThemePalette.primary;
  bool isLoading = true;
  List invoiceList = [];
  // --- TAMBAHKAN INI ---
  bool canGenerateInvoice = false;
  Map<String, dynamic>? openInvoiceData;
  Map<String, dynamic>? singleInvoice;
  List detailInvoices = [];
  List camabaInvoices = [];
  List paymentHistory = []; // Untuk menyimpan data dari api/get-payment-history
  List<int> selectedDetailIndexes =
      []; // Menyimpan index dari detailInvoices yang dicentang
  // --------------------

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    setState(() => isLoading = true);
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    try {
      final responseInvoice = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/get-invoice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      final responseHistory = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/get-payment'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      if (responseInvoice.statusCode == 200 &&
          responseHistory.statusCode == 200) {
        final dataInv = json.decode(responseInvoice.body);
        final dataHist = json.decode(responseHistory.body);

        setState(() {
          singleInvoice = dataInv['body']?['data']?['single_invoice'];
          detailInvoices = dataInv['body']?['data']?['detail'] ?? [];
          camabaInvoices = dataInv['body']?['data']?['invoice_camaba'] ?? [];
          paymentHistory = dataHist['body']?['data'] ?? [];

          // --- LOGIKA BARU DI SINI ---
          // Reset dulu agar tidak duplikat saat refresh
          selectedDetailIndexes.clear();

          for (int i = 0; i < detailInvoices.length; i++) {
            // Jika status_calculate adalah "1", masukkan ke daftar terpilih
            if (detailInvoices[i]['status_calculate'] == "1") {
              selectedDetailIndexes.add(i);
            }
          }
        });
      }
      await _checkIsAnyOpenInvoice(token, idLogin);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Menghitung total Debit dari item yang dicentang
  double get totalSelectedDebit {
    double total = 0;
    for (int index in selectedDetailIndexes) {
      total +=
          double.tryParse(detailInvoices[index]['bill_amount'].toString()) ?? 0;
    }
    return total;
  }

  // Menghitung total Balance dari item yang dicentang
  double get totalSelectedBalance {
    double total = 0;
    for (int index in selectedDetailIndexes) {
      total +=
          double.tryParse(detailInvoices[index]['bill_balance'].toString()) ??
          0;
    }
    return total;
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // User tidak bisa menutup modal dengan klik di luar
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
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

    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    // 1. UBAH DI SINI: Ambil 'id_invoice' sebagai pengganti 'bill_number'
    List<String> selectedInvoiceIds = selectedDetailIndexes.map((index) {
      // Pastikan key-nya adalah 'id_invoice' sesuai dengan struktur data API Anda
      return detailInvoices[index]['id_invoice'].toString();
    }).toList();

    // 2. Gabungkan menjadi string yang dipisahkan koma (e.g., "123,124")
    String idSetString = selectedInvoiceIds.join(',');

    try {
      final response = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/recalculate-invoice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "IdLogin": idLogin,
          "token": token,
          "idset": idSetString, // Sekarang idset berisi kumpulan id_invoice
        }),
      );

      debugPrint("Kirimannya: $idSetString");

      Navigator.pop(context); // Tutup loading spinner

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['body'] != null) {
          // Jika berhasil, panggil fetchInvoices lagi untuk memperbarui UI
          await fetchInvoices();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("VA Berhasil Diperbarui"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data?['data']), backgroundColor: Colors.red),
          );
        }
      } else {
        _showErrorSnackBar("Gagal memperbarui VA");
      }
    } catch (e) {
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

  Future<void> _checkIsAnyOpenInvoice(String? token, String? idLogin) async {
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/cek-open-invoice');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Jika statusnya 200 dan body tidak null, berarti ada tagihan yang bisa dibuat
        if (data['status'] == 200 && data['body'] != null) {
          setState(() {
            canGenerateInvoice = true;
            openInvoiceData = data['body'];
          });
        } else {
          setState(() {
            canGenerateInvoice = false;
            openInvoiceData = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Cek Open Invoice: $e");
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
        color: Colors.white,
        border: Border.all(color: primaryBlue.withAlpha(128)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  singleInvoice!['Description'] ?? "-",
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowInfo("Invoice", singleInvoice!['bill_number']),
                    // Tampilan yang otomatis update
                    _rowInfo("Debit Amount", displayDebit),
                    _rowInfo("Balance", displayBalance),
                    // TOMBOL HITUNG SINGLE VA
                    ElevatedButton(
                      onPressed: () {
                        // Membuat Map dummy untuk modal agar strukturnya sama dengan invoice asli
                        Map<String, dynamic> accumulationData = {
                          'Description': 'Accumulated Single VA',
                          'bill_number': singleInvoice!['bill_number'],
                          'va': singleInvoice!['va'],
                          'bill_amount': totalSelectedDebit,
                        };

                        _showDetailModal(
                          hasSelection ? accumulationData : singleInvoice!,
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
      String idSem = openInvoiceData!['IdSemester'].toString();
      String idAct = openInvoiceData!['id_activity'].toString();
      _generateInvoice(idSem, idAct);
    }
  }

  Future<void> _generateInvoice(String idSemester, String idActivity) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/generate-invoice');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "IdLogin": idLogin,
          "token": token,
          "IdSemester": idSemester,
          "idactivity": idActivity,
          "cuti": "",
        }),
      );

      if (mounted) Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Tampilkan Modal dengan data rincian biaya yang didapat
        _showResultModal(true, "Rincian biaya berhasil ditarik", data['body']);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error Generate: $e");
    }
  }

  /// Fungsi untuk menyetujui tagihan (Hit API approve-invoice)
  Future<void> _approveInvoice(Map<String, dynamic> invoiceData) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/approve-invoice');

    // 1. Mapping Item (Tetap sama, mengubah Map bundledetail ke List)
    List<Map<String, dynamic>> itemsList = [];
    final bundleDetail = invoiceData['bundledetail'] as Map<String, dynamic>;
    bundleDetail.forEach((key, value) {
      itemsList.add({
        "fi_id": value['fi_id'].toString(),
        "fi_name": value['fi_name'],
        "fi_name_short": value['fi_name_short'],
        "amount": value['amount'],
      });
    });

    // 2. Persiapkan Body Request Terbaru
    final Map<String, dynamic> requestBody = {
      "token": token,
      "IdLogin": idLogin,
      "IdSemester": invoiceData['IdSemesterMaster'].toString(),
      "description":
          invoiceData['descriptiom'], // Typo dari API generate: 'descriptiom'
      "close": "c",
      "idactivity": invoiceData['idActivity'].toString(),
      "payment": "1",
      "idinvoice": "",
      "fs_id": invoiceData['fs_id'].toString(),
      "id_calendar":
          invoiceData['id_calendar']?.toString() ?? "9527", // Field Baru
      "item": itemsList,
      "discount": [
        // Sekarang berbentuk List, bukan Map
        {
          "id_discount": "1",
          "item": [
            {"fi_id": "2", "amount": "2000"},
            {"fi_id": "11", "amount": "4000"},
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resData['body']?['message'] ?? "Tagihan Berhasil Dibuat!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        fetchInvoices();
      } else {
        throw "Gagal (Status: ${response.statusCode})";
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error Approve: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailModal(
    Map<String, dynamic> data, {
    String title = "Rincian Tagihan",
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
            const Divider(),
            _rowModal("Deskripsi", data['Description']),
            _rowModal("No. Invoice", data['bill_number']),

            const SizedBox(height: 10),
            // --- BAGIAN VA YANG DI HIGHLIGHT ---
            const Text(
              "Virtual Account",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            _buildCopyableVA(data['va']),

            const SizedBox(height: 10),
            _rowModal("Total", formatRupiah(data['bill_amount'])),
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
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showResultModal(bool isSuccess, String message, dynamic data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Agar modal bisa menyesuaikan tinggi isi rincian
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Jika sukses, kita ambil data bundle pertama dari list 'data'
        final invoiceData = (isSuccess && data['data'] != null)
            ? data['data'][0]
            : null;
        final bundleDetail = invoiceData != null
            ? invoiceData['bundledetail'] as Map<String, dynamic>
            : {};

        // Hitung Total Otomatis
        double totalAmount = 0;
        bundleDetail.forEach((key, value) {
          totalAmount += double.tryParse(value['amount'].toString()) ?? 0;
        });

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    isSuccess == true
                        ? invoiceData['SemesterMainName'] ?? "-"
                        : "-",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 32),

                  if (isSuccess) ...[
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: bundleDetail.length,
                        itemBuilder: (context, index) {
                          // Mengambil key Map (0, 1, 2, dst)
                          String key = bundleDetail.keys.elementAt(index);
                          var item = bundleDetail[key];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['fi_name'],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  formatRupiah(item['amount']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Estimasi",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("Account Statement"),
          backgroundColor: primaryBlue,
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
      return const Center(child: Text("Belum ada riwayat pembayaran"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final item = paymentHistory[index];
        List cnList = item['cn'] ?? []; // Mengambil list potongan

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBlue.withAlpha(128)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
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
                      item['Description'] ?? "-",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _rowHistoryDetail("No. Tagihan", item['bill_number']),
              _rowHistoryDetail(
                "Total Tagihan",
                formatRupiah(item['bill_amount']),
              ),

              // TAMPILKAN CN (POTONGAN) JIKA ADA
              if (cnList.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  "Potongan / Beasiswa:",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                // Looping semua isi CN
                ...cnList.map(
                  (cn) => _rowHistoryDetail(
                    cn['cn_desc'] ?? "Potongan",
                    "- ${formatRupiah(cn['amount'])}",
                    color: Colors.red,
                  ),
                ),
              ],

              const Divider(height: 24),
              _rowHistoryDetail(
                "Total Dibayar",
                formatRupiah(item['bill_paid']),
                isBold: true,
                color: Colors.green,
              ),

              if (item['payment'] != null && item['payment'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Metode: ${item['payment'][0]['payment_mode']} • ${item['payment'][0]['payment_date'].toString().split(' ')[0]}",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
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
    Color color = Colors.black87,
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> item, bool isPaid) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['Description'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _statusChip(isPaid),
              ],
            ),
            const Divider(height: 24),
            // _rowDetail("Nomor Tagihan", item['bill_number']),
            if (item['va'] != null && item['va'].toString().isNotEmpty)
              _rowDetail(
                "Nomor Virtual Account",
                item['va'] ?? "Belum tersedia",
              ),
            _rowDetail("Total Tagihan", formatRupiah(item['bill_amount'])),
            if (!isPaid)
              _rowDetail(
                "Sisa Tagihan",
                formatRupiah(item['bill_balance']),
                isBold: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _rowDetail(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withAlpha(26)
            : Colors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? "Lunas" : "Belum Bayar",
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget untuk baris informasi (Tanggal, Invoice, dll)
  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: primaryBlue),
          children: [
            TextSpan(
              text: "$label : ",
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk item rincian dengan checkbox (BPP Pokok, SKS, dll)
  Widget _buildSubItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_box_outline_blank, color: primaryBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item['Description'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Text(
            "Total Tagihan : ${formatRupiah(item['bill_amount'])}",
            style: TextStyle(fontSize: 11, color: primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInvoiceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (singleInvoice != null) _buildMainInvoiceCard(),
        if (camabaInvoices.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...camabaInvoices.map((item) => _buildCamabaCard(item)),
        ],
        if (singleInvoice == null && camabaInvoices.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("Tidak ada tagihan aktif"),
            ),
          ),
      ],
    );
  }

  Widget _buildCopyableVA(String? va) {
    final String vaText = (va == null || va.isEmpty) ? "-" : va;
    bool isAvailable = vaText != "-";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable ? primaryBlue.withAlpha(26) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAvailable ? primaryBlue.withAlpha(77) : Colors.grey.shade300,
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
              color: isAvailable ? primaryBlue : Colors.grey,
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Account Statement",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemCard(Map<String, dynamic> item, int index) {
    bool isSelected = selectedDetailIndexes.contains(index);

    return GestureDetector(
      onTap: () => _showDetailModal(item), // Klik teks/kartu buka modal
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: primaryBlue.withAlpha(77)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5),
          ],
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
                item['Description'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),
            Text(
              formatRupiah(item['bill_amount']),
              style: TextStyle(
                fontSize: 10,
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamabaCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item['Description'] ?? "Paket Camaba",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowInfo("Invoice", item['bill_number']),
                _rowInfo("Balance", formatRupiah(item['bill_balance'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
