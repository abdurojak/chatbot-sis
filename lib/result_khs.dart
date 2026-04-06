import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HasilKhsPage extends StatefulWidget {
  const HasilKhsPage({super.key});

  @override
  State<HasilKhsPage> createState() => _HasilKhsPageState();
}

class _HasilKhsPageState extends State<HasilKhsPage> {
  Color get primaryBlue => AppThemePalette.primary;

  bool isLoading = true;
  List khsDetailList = [];
  Map<String, dynamic> kinerja = {};
  List<Map<String, dynamic>> _semesters = [];
  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // ... (Fungsi _initializeData, _fetchDefaultSemester, dan _fetchSemesters tetap sama seperti sebelumnya) ...
  Future<void> _initializeData() async {
    await _fetchDefaultSemester();
    await _fetchSemesters();
    await fetchKhs();
  }

  Future<void> _fetchDefaultSemester() async {
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/krs-requirement');
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );
      final json = jsonDecode(res.body);
      _selectedSemesterId = json['body']?['IdSemesterMain']?.toString();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchSemesters() async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    try {
      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/get-semester'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token, "IdLogin": idLogin}),
      );
      final json = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _semesters = List<Map<String, dynamic>>.from(
            json['body']?['semester'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchKhs() async {
    if (_selectedSemesterId == null) return;
    setState(() => isLoading = true);
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/get-khs');

    try {
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
          kinerja = data["body"]?["kinerja"] ?? {};
          khsDetailList = data["body"]?["detail"] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hasil KHS'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSemesterPicker(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildKinerjaGrid(),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Detail Mata Kuliah",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        _buildKhsList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: primaryBlue.withAlpha(13),
      child: DropdownButtonFormField<String>(
        value: _selectedSemesterId,
        decoration: const InputDecoration(
          labelText: "Semester",
          border: OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
        ),
        items: _semesters
            .map(
              (sem) => DropdownMenuItem(
                value: sem['IdSemesterMaster'].toString(),
                child: Text(sem['SemesterMainName']),
              ),
            )
            .toList(),
        onChanged: (v) {
          setState(() => _selectedSemesterId = v);
          fetchKhs();
        },
      ),
    );
  }

  Widget _buildKinerjaGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _cardKinerja("IPS", kinerja['ips'] ?? "0.00", Colors.orange),
          _cardKinerja("IPK", kinerja['ipk'] ?? "0.00", Colors.green),
          _cardKinerja("SKS Semester", kinerja['sks_sem'] ?? "0", Colors.blue),
          _cardKinerja("SKS Lulus", kinerja['sks_lulus'] ?? "0", Colors.purple),
        ],
      ),
    );
  }

  Widget _cardKinerja(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: khsDetailList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = khsDetailList[index];
        return ListTile(
          onTap: () => _showDetailModal(item),
          title: Text(
            item['namamk'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text("${item['kodemk']} • ${item['sks']} SKS"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['nilai'] ?? "-",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  void _showDetailModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['namamk'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(item['kodemk'], style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              _rowModal("Kelas", item['namakelas']),
              _rowModal("SKS", item['sks'].toString()),
              _rowModal("Nilai Angka", item['nilai_angka'] ?? "-"),
              _rowModal("Nilai Huruf", item['nilai'] ?? "-"),
              _rowModal("Status", item['pass'] ?? "N/A", isStatus: true),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _rowModal(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: value == "Pass" ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
