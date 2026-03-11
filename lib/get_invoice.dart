import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
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
  static const Color primaryBlue = Color(0xFF1E73BE);
  bool isLoading = true;
  List invoiceList = [];
  // --- TAMBAHKAN INI ---
  bool canGenerateInvoice = false;
  Map<String, dynamic>? openInvoiceData;
  // --------------------

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    setState(() => isLoading = true); // Pastikan loading aktif di awal

    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    try {
      // 1. Ambil Daftar Invoice (seperti biasa)
      final resInvoice = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/get-invoice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      // 2. Cek apakah ada tagihan yang bisa dibuat (is-any-open-invoice)
      final resOpen = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/is-any-open-invoice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      if (mounted) {
        setState(() {
          // Handle data daftar invoice
          if (resInvoice.statusCode == 200) {
            final data = json.decode(resInvoice.body);
            invoiceList = data["body"]?["data"] ?? [];
          }

          // Handle pengecekan tombol aktif
          if (resOpen.statusCode == 200) {
            final openData = json.decode(resOpen.body);
            final body = openData['body'];

            if (body['idactivity'] != null && body['idactivity'] is Map) {
              canGenerateInvoice = true;
              openInvoiceData =
                  body['idactivity']; // Simpan untuk dipakai nanti
            } else {
              canGenerateInvoice = false;
            }
          }

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error Fetch: $e");
    }
  }

  // Future<void> _checkOpenInvoice() async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => const Center(child: CircularProgressIndicator()),
  //   );

  //   final token = await AuthStorage.getToken();
  //   final idLogin = await AuthStorage.getIdLogin();
  //   final url = Uri.parse(
  //     'https://sismob.trisakti.ac.id/api/is-any-open-invoice',
  //   );

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode({"IdLogin": idLogin, "token": token}),
  //     );

  //     if (mounted) Navigator.pop(context); // Tutup loading

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final body = data['body'];

  //       // Jika idactivity adalah Map, artinya ada tagihan yang bisa dibuat
  //       if (body['idactivity'] != null && body['idactivity'] is Map) {
  //         String idSem = body['idactivity']['IdSemester'].toString();
  //         String idAct = body['idactivity']['id_activity'].toString();

  //         // LANGKAH 2: Otomatis lanjut ke Generate Invoice untuk dapat rincian
  //         _generateInvoice(idSem, idAct);
  //       } else {
  //         // Jika tidak ada tagihan terbuka
  //         _showResultModal(false, body['message'] ?? "Tidak ada tagihan", null);
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) Navigator.pop(context);
  //     _showResultModal(false, "Koneksi gagal: $e", null);
  //   }
  // }

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
                          style: const TextStyle(
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
                        side: const BorderSide(color: primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
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
    // Memisahkan data berdasarkan status_paid
    final activeInvoices = invoiceList
        .where((i) => i['status_paid'] != "P")
        .toList();
    final paidInvoices = invoiceList
        .where((i) => i['status_paid'] == "P")
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tagihan & VA'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (activeInvoices.isNotEmpty) ...[
                        _buildSectionHeader(
                          "Tagihan Tersedia",
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        ...activeInvoices.map(
                          (i) => _buildInvoiceCard(i, false),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (paidInvoices.isNotEmpty) ...[
                        _buildSectionHeader(
                          "Riwayat Pembayaran",
                          Icons.check_circle,
                          Colors.green,
                        ),
                        ...paidInvoices.map((i) => _buildInvoiceCard(i, true)),
                      ],
                    ],
                  ),
                ),

                // TOMBOL DI BAGIAN BAWAH
                if (canGenerateInvoice)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed:
                          _handleCreateInvoice, // Gunakan fungsi sederhana tadi
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_card,
                      ), // Icon diganti agar lebih sesuai "Buat Tagihan"
                      label: const Text(
                        "Buat Tagihan Baru", // Label disesuaikan
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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

            // if (item['va'] != null && item['va'].toString().isNotEmpty) ...[
            //   const SizedBox(height: 12),
            //   Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       color: primaryBlue.withOpacity(0.05),
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Row(
            //       children: [
            //         const Icon(
            //           Icons.account_balance_wallet,
            //           size: 18,
            //           color: primaryBlue,
            //         ),
            //         const SizedBox(width: 8),
            //         Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             const Text(
            //               "Virtual Account",
            //               style: TextStyle(fontSize: 10, color: Colors.grey),
            //             ),
            //             Text(
            //               item['va'],
            //               style: const TextStyle(
            //                 fontWeight: FontWeight.bold,
            //                 fontSize: 15,
            //                 color: primaryBlue,
            //               ),
            //             ),
            //           ],
            //         ),
            //         const Spacer(),
            //         IconButton(
            //           icon: const Icon(
            //             Icons.copy,
            //             size: 18,
            //             color: primaryBlue,
            //           ),
            //           onPressed: () {
            //             Clipboard.setData(ClipboardData(text: item['va']));
            //             ScaffoldMessenger.of(context).showSnackBar(
            //               const SnackBar(
            //                 content: Text("Nomor VA disalin ke clipboard"),
            //                 duration: Duration(seconds: 1),
            //               ),
            //             );
            //           },
            //         ),
            //       ],
            //     ),
            //   ),
            // ] else if (!isPaid) ...[
            //   const SizedBox(height: 8),
            //   const Text(
            //     "* VA Belum tersedia untuk tagihan ini",
            //     style: TextStyle(
            //       fontSize: 11,
            //       color: Colors.red,
            //       fontStyle: FontStyle.italic,
            //     ),
            //   ),
            // ],
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
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
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
}
