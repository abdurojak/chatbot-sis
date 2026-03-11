import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/subject_model.dart';
import 'package:chatbot/schedule_krs.dart';
import 'package:chatbot/submit_krs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PengisianKrsPage extends StatefulWidget {
  final String idSemester;

  const PengisianKrsPage({super.key, required this.idSemester});

  static const Color primaryBlue = Color(0xFF1E73BE);

  @override
  State<PengisianKrsPage> createState() => _PengisianKrsPageState();
}

class _PengisianKrsPageState extends State<PengisianKrsPage> {
  bool _isLoading = true;
  String? _error;

  List<Subject> _subjects = [];
  List<Map<String, dynamic>> _semesters = [];

  String? _selectedSemesterId;
  String? _expandedSubjectId;

  int maxSks = 0;
  int totalSks = 0;

  final Map<String, List<Map<String, dynamic>>> _subjectClassesCache = {};
  final Map<String, String> _selectedClassPerSubject = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchSemesters();
    if (_selectedSemesterId != null) {
      await _fetchSubjects();
    }
    await _fetchRequirement();
    await _fetchKrs();
  }

  // ================= FETCH SEMESTER =================

  Future<void> _fetchSemesters() async {
    try {
      final token = await AuthStorage.getToken();
      final idLogin = await AuthStorage.getIdLogin();

      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/get-semester'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token, "IdLogin": idLogin}),
      );

      final json = jsonDecode(res.body);

      debugPrint('Fetch semesters response: ${res.body}');

      if (res.statusCode == 200) {
        final List list = json['body']?['semester'] ?? [];

        if (!mounted) return;

        setState(() {
          _semesters = List<Map<String, dynamic>>.from(list);

          /// cari semester default dari parameter
          final matched = _semesters.firstWhere(
            (e) => e['IdSemesterMaster']?.toString() == widget.idSemester,
            orElse: () => _semesters.isNotEmpty ? _semesters.first : {},
          );

          _selectedSemesterId = matched['IdSemesterMaster']?.toString();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  /// ================= GET REQUIREMENT (TEMPORARY HARDCODED) =================

  Future<void> _fetchRequirement() async {
    // Karena API 404, kita gunakan data dummy sesuai spesifikasi Anda
    final Map<String, dynamic> mockResponse = {
      "status": "Successful",
      "header": {"Content-Type": "application/json"},
      "body": {
        "IdSemesterMain": "773",
        "maks_sks": "24",
        "requirements": [
          {
            "req_id": "req1",
            "description": "Status Mahasiswa Aktif.",
            "status": 1,
            "button": [],
          },
          {
            "req_id": "req2",
            "description": "Tidak ada kewajiban keuangan.",
            "status": 1,
            "button": [],
          },
          {
            "req_id": "req3",
            "description": "Belum Perwalian",
            "status": 0,
            "button": [],
          },
          {
            "req_id": "req4",
            "description": "Persetujuan Perwalian",
            "status": 0,
            "button": [],
          },
        ],
      },
    };

    // Simulasi delay jaringan agar CircularProgressIndicator tetap terlihat sebentar
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      maxSks = mockResponse["body"]["maks_sks"];
      // Anda bisa menyimpan data requirements ke variabel state lain jika ingin menampilkannya di UI
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
          totalSks = sks;
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= FETCH SUBJECT =================

  Future<void> _fetchSubjects() async {
    if (_selectedSemesterId == null) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthStorage.getToken();
      final idLogin = await AuthStorage.getIdLogin();

      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/subject'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "IdLogin": idLogin,
          "token": token,
          "IdSemester": _selectedSemesterId,
          "level": 0,
        }),
      );

      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final List list = json['body']['subjects'] ?? [];

        if (!mounted) return;

        setState(() {
          _subjects = list.map((e) => Subject.fromJson(e)).toList();
        });
      } else {
        _error = json['message'] ?? 'Gagal memuat mata kuliah';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= FETCH KELAS =================

  Future<void> _fetchSubjectClasses(String subjectId) async {
    if (_subjectClassesCache.containsKey(subjectId)) return;

    try {
      final token = await AuthStorage.getToken();
      final idLogin = await AuthStorage.getIdLogin();

      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/course-schedule'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "IdLogin": idLogin,
          "token": token,
          "IdSemester": _selectedSemesterId,
          "IdSubject": subjectId,
        }),
      );

      debugPrint('Fetch classes for subject $subjectId: ${res.body}');

      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final List bodyList = json['body'] ?? [];

        List<Map<String, dynamic>> flattened = [];

        if (bodyList.isNotEmpty && bodyList.first is Map) {
          final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
            bodyList.first,
          );

          dataMap.forEach((key, value) {
            if (value != null && value is Map) {
              flattened.add(Map<String, dynamic>.from(value));
            }
          });
        }

        if (!mounted) return;

        setState(() {
          _subjectClassesCache[subjectId] = flattened;
        });
      }
    } catch (e) {
      debugPrint('Error fetch classes: $e');
    }
  }

  Future<void> _onSemesterChanged(String? value) async {
    if (value == null) return;

    setState(() {
      _selectedSemesterId = value;
      _expandedSubjectId = null;
      _subjects = [];
      _subjectClassesCache.clear();
      _selectedClassPerSubject.clear();
    });

    await _fetchSubjects();
  }

  // ================= REGISTER =================

  Future<void> _registerKrs({required String idCourse}) async {
    try {
      final token = await AuthStorage.getToken();
      final idLogin = await AuthStorage.getIdLogin();

      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "IdLogin": idLogin,
          "IdCourse": idCourse,
          "sksmaks": "24",
        }),
      );

      final json = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 && json['body']?['status proses'] == "1") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mata kuliah berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchKrs(); // Refresh total SKS setelah berhasil register
        _fetchRequirement(); // Refresh requirement untuk update status jika ada
        _fetchSemesters(); // Refresh semester untuk update status jika ada
        _fetchSubjects(); // Refresh subjects untuk update status jika ada
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json['message'] ?? 'Gagal menyimpan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final semesterLevel = _semesters.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengisian KRS'),
        backgroundColor: PengisianKrsPage.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                /// ================= DROPDOWN SEMESTER =================
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: DropdownButtonFormField<String>(
                //     value: _selectedSemesterId,
                //     items: _semesters.map((sem) {
                //       return DropdownMenuItem<String>(
                //         value: sem['IdSemesterMaster']?.toString(),
                //         child: Text(sem['SemesterMainName'] ?? ''),
                //       );
                //     }).toList(),
                //     onChanged: _onSemesterChanged,
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

                /// ================= LIST SUBJECT =================
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _subjects.length,
                    itemBuilder: (context, i) {
                      final s = _subjects[i];
                      final subjectId = s.idSubject;
                      final isExpanded = _expandedSubjectId == subjectId;
                      final classes = _subjectClassesCache[subjectId];

                      final disabled = !s.isAvailable;
                      final statusMsg = s.statusMessage;

                      return Opacity(
                        opacity: disabled ? 0.5 : 1,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.namaMk,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    if (disabled && statusMsg != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusMsg == "Kelas Penuh"
                                              ? Colors.red
                                              : Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          statusMsg,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(s.kodeMk),
                                trailing: Text("${s.sks} SKS"),
                                onTap: disabled
                                    ? null
                                    : () async {
                                        if (isExpanded) {
                                          setState(
                                            () => _expandedSubjectId = null,
                                          );
                                        } else {
                                          setState(
                                            () =>
                                                _expandedSubjectId = subjectId,
                                          );
                                          await _fetchSubjectClasses(subjectId);
                                        }
                                      },
                              ),
                              if (!disabled && isExpanded) ...[
                                const Divider(),
                                if (classes == null)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        ...classes.map((cls) {
                                          final int terisi =
                                              int.tryParse(
                                                cls['terisi'].toString(),
                                              ) ??
                                              0;
                                          final int kapasitas =
                                              int.tryParse(
                                                cls['kapasitas'].toString(),
                                              ) ??
                                              0;

                                          final bool full = terisi >= kapasitas;

                                          final String classId = cls['IdCourse']
                                              .toString();

                                          return RadioListTile<String>(
                                            value: classId,
                                            groupValue:
                                                _selectedClassPerSubject[subjectId],
                                            onChanged: full
                                                ? null
                                                : (val) {
                                                    setState(() {
                                                      _selectedClassPerSubject[subjectId] =
                                                          val!;
                                                    });
                                                  },
                                            title: Text(
                                              "${cls['namakelas']} ($classId)",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ...List<Map<String, dynamic>>.from(
                                                  cls['jadwal'] ?? [],
                                                ).map(
                                                  (j) => Text(
                                                    "${j['hari']} • ${j['mulai'].substring(0, 5)} - ${j['selesai'].substring(0, 5)} | ${j['ruang']}",
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Kapasitas: $terisi/$kapasitas",
                                                  style: TextStyle(
                                                    color: full
                                                        ? Colors.red
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: OutlinedButton(
                                            onPressed:
                                                _selectedClassPerSubject[subjectId] ==
                                                    null
                                                ? null
                                                : () async {
                                                    await _registerKrs(
                                                      idCourse:
                                                          _selectedClassPerSubject[subjectId]!,
                                                    );
                                                  },
                                            child: const Text('Save'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      /// ================= BUTTON LIHAT KRS =================
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubmitKrsScreen(
                                        idSemester: _selectedSemesterId ?? '',
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PengisianKrsPage.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lihat KRS',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// ================= BUTTON LIHAT JADWAL =================
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JadwalKrsScreen(
                                        idSemester: _selectedSemesterId ?? '',
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PengisianKrsPage.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lihat Jadwal',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// ================= WIDGET =================

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
}
