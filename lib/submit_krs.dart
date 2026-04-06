import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SubmitKrsScreen extends StatefulWidget {
  final String idSemester;

  const SubmitKrsScreen({super.key, required this.idSemester});

  @override
  State<SubmitKrsScreen> createState() => _SubmitKrsScreenState();
}

class _SubmitKrsScreenState extends State<SubmitKrsScreen> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _krsList = [];
  List<String> _selectedCourses = [];

  List<Map<String, dynamic>> _semesters = [];

  int semesterLevel = 0;
  int totalSks = 0;
  int maxSks = 24;

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchSemesters();
    await _fetchKrs();
  }

  /// ================= FETCH SEMESTER =================

  Future<void> _fetchSemesters() async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    final res = await http.post(
      Uri.parse('https://sismob.trisakti.ac.id/api/get-semester'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"IdLogin": idLogin, "token": token}),
    );

    final json = jsonDecode(res.body);

    final List list = json['body']?['semester'] ?? [];

    setState(() {
      _semesters = List<Map<String, dynamic>>.from(list);
      semesterLevel = _semesters.length;
    });
  }

  /// ================= FETCH KRS =================

  Future<void> _fetchKrs() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthStorage.getToken();
      final idLogin = await AuthStorage.getIdLogin();

      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/get-krs'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "IdLogin": idLogin,
          "token": token,
          "IdSemester": widget.idSemester,
        }),
      );

      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final List list = json['body']?['kelas'] ?? [];

        int sks = 0;

        for (var item in list) {
          sks += int.tryParse(item['sks'].toString()) ?? 0;
        }

        if (!mounted) return;

        setState(() {
          _krsList = List<Map<String, dynamic>>.from(list);
          _selectedCourses.clear();
          totalSks = sks;
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ================= SEND OTP =================

  Future<String?> _sendOtp() async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    final res = await http.post(
      Uri.parse('https://sismob.trisakti.ac.id/api/send-otp'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"IdLogin": idLogin, "token": token}),
    );

    final json = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return json['body']?['id_otp']?.toString();
    }

    return null;
  }

  /// ================= CANCEL COURSE =================

  Future<void> _cancelCourse(String otp, String idOtp) async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    final res = await http.post(
      Uri.parse('https://sismob.trisakti.ac.id/api/cancel-course'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "IdLogin": idLogin,
        "token": token,
        "otp": otp,
        "id_otp": idOtp,
        "courses": _selectedCourses,
      }),
    );

    final json = jsonDecode(res.body);

    if (res.statusCode == 200) {
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Berhasil Drop MK")));

      _fetchKrs();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(json['message'] ?? "Gagal Drop")));
    }
  }

  /// ================= OTP DIALOG =================

  Future<void> _showOtpDialog() async {
    if (_selectedCourses.isEmpty) return;

    final idOtp = await _sendOtp();

    if (idOtp == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal kirim OTP")));
      return;
    }

    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final selectedItems = _krsList
            .where((e) => _selectedCourses.contains(e['IdRegister'].toString()))
            .toList();

        return AlertDialog(
          title: const Text("Konfirmasi Drop MK"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...selectedItems.map(
                (e) => ListTile(
                  title: Text("${e['kodemk']} - ${e['namamk']}"),
                  subtitle: Text("Kelas: ${e['namakelas']}"),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: "Masukkan OTP",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Drop"),
              onPressed: () {
                _cancelCourse(otpController.text, idOtp);
              },
            ),
          ],
        );
      },
    );
  }

  /// ================= INFO ROW =================

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
  // Widget _infoRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4),
  //     child: Row(
  //       children: [
  //         Expanded(flex: 2, child: Text(label)),
  //         const Text(": "),
  //         Expanded(
  //           flex: 3,
  //           child: Text(
  //             value,
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KRS Saya"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: _selectedCourses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showOtpDialog,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: const Text("Drop MK"),
              icon: const Icon(Icons.delete),
            )
          : null,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // /// ===== INFO BOX =====
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: Column(
                //     children: [
                //       _infoRow(
                //         "Semester to Register",
                //         _semesters.isNotEmpty
                //             ? _semesters.first["SemesterMainName"]
                //             : "-",
                //       ),
                //       _infoRow("Semester Level", semesterLevel.toString()),
                //       _infoRow("Total Credit", "$totalSks/$maxSks"),
                //     ],
                //   ),
                // ),

                /// ======= INFO CARD =======
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        "Semester to Register",
                        _semesters.isNotEmpty
                            ? _semesters.first["SemesterMainName"]
                            : "-",
                      ),
                      _infoRow("Semester Level", semesterLevel.toString()),
                      _infoRow("Total Credit", "$totalSks/$maxSks"),
                    ],
                  ),
                ),

                /// ===== LIST KRS =====
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _krsList.length,
                    itemBuilder: (context, index) {
                      final item = _krsList[index];

                      final bool isApproved =
                          item['persetujuan'].toString() == "1";

                      final bool canCancel = !isApproved;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selectedCourses.contains(
                            item['IdRegister'].toString(),
                          ),
                          onChanged: canCancel
                              ? (val) {
                                  setState(() {
                                    final id = item['IdRegister'].toString();

                                    if (val == true) {
                                      _selectedCourses.add(id);
                                    } else {
                                      _selectedCourses.remove(id);
                                    }
                                  });
                                }
                              : null,

                          title: Text(
                            "${item['kodemk']} - ${item['namamk']}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),

                              Text(
                                "Kelas: ${item['namakelas']} | SKS: ${item['sks']}",
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isApproved
                                      ? "Disetujui"
                                      : "Menunggu Persetujuan",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isApproved
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
