import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HasilKrsPage extends StatefulWidget {
  const HasilKrsPage({super.key});

  @override
  State<HasilKrsPage> createState() => _HasilKrsPageState();
}

class _HasilKrsPageState extends State<HasilKrsPage> {
  Color get primaryBlue => AppThemePalette.primary;

  bool isLoading = true;
  List kelasList = [];
  List<Map<String, dynamic>> _semesters = [];

  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchDefaultSemester();
    await _fetchSemesters();
    await fetchKrs();
  }

  /// =========================
  /// 1️⃣ GET DEFAULT SEMESTER
  /// =========================
  Future<void> _fetchDefaultSemester() async {
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/krs-requirement');

    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"IdLogin": idLogin, "token": token}),
    );

    final json = jsonDecode(res.body);

    final String semester = json['body']?['IdSemesterMain'] ?? '';

    _selectedSemesterId = semester;
  }

  /// =========================
  /// 2️⃣ GET SEMESTER LIST
  /// =========================
  Future<void> _fetchSemesters() async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    final res = await http.post(
      Uri.parse('https://sismob.trisakti.ac.id/api/get-semester'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token, "IdLogin": idLogin}),
    );

    final json = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final List list = json['body']?['semester'] ?? [];

      setState(() {
        _semesters = List<Map<String, dynamic>>.from(list);

        final matched = _semesters.firstWhere(
          (e) => e['IdSemesterMaster']?.toString() == _selectedSemesterId,
          orElse: () => _semesters.isNotEmpty ? _semesters.first : {},
        );

        _selectedSemesterId = matched['IdSemesterMaster']?.toString();
      });
    }
  }

  /// =========================
  /// 3️⃣ FETCH KRS
  /// =========================
  Future<void> fetchKrs() async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    if (_selectedSemesterId == null) return;

    setState(() => isLoading = true);

    final url = Uri.parse('https://sismob.trisakti.ac.id/api/get-krs');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "IdLogin": idLogin,
        "token": token,
        "IdSemester": _selectedSemesterId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        kelasList = data["body"]?["kelas"] ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        kelasList = [];
        isLoading = false;
      });
    }
  }

  void _onSemesterChanged(String? value) {
    setState(() {
      _selectedSemesterId = value;
    });

    fetchKrs();
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil KRS'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          /// 🔽 DROPDOWN SEMESTER
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedSemesterId,
              decoration: const InputDecoration(
                labelText: "Pilih Semester",
                border: OutlineInputBorder(),
              ),
              items: _semesters.map((sem) {
                return DropdownMenuItem<String>(
                  value: sem['IdSemesterMaster']?.toString(),
                  child: Text(sem['SemesterMainName'] ?? ''),
                );
              }).toList(),
              onChanged: _onSemesterChanged,
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : kelasList.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada data KRS",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : _buildKrsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKrsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: kelasList.length,
      itemBuilder: (context, index) {
        final kelas = kelasList[index];

        final isApproved = kelas['persetujuan'] == "1";

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${kelas['kodemk']} - ${kelas['namamk']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),

                Text("SKS: ${kelas['sks']}"),
                Text("Kelas: ${kelas['namakelas']}"),

                const SizedBox(height: 10),
                const Text(
                  "Jadwal:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                ...kelas['jadwal'].map<Widget>((jadwal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "${jadwal['hari']} | "
                      "${jadwal['mulai']} - ${jadwal['selesai']} | "
                      "Ruang: ${jadwal['ruang']}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),

                /// ✅ STATUS PERSETUJUAN
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isApproved ? "Disetujui" : "Menunggu Persetujuan",
                      style: TextStyle(
                        color: isApproved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
