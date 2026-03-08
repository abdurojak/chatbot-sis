import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/component/authentication.dart';

class JadwalKrsScreen extends StatefulWidget {
  final String idSemester;

  const JadwalKrsScreen({super.key, required this.idSemester});

  @override
  State<JadwalKrsScreen> createState() => _JadwalKrsScreenState();
}

class _JadwalKrsScreenState extends State<JadwalKrsScreen> {
  static const Color primaryBlue = Color(0xFF4A6FAE);

  bool _loading = true;

  List<Map<String, dynamic>> kelas = [];
  List semesters = [];

  int maxSks = 0;

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  final List<String> timeSlots = [
    "07:00",
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// ================= LOAD DATA =================

  Future<void> _loadData() async {
    try {
      final token = await AuthStorage.getToken();
      final idLogin = await AuthStorage.getIdLogin();

      /// GET KRS
      final krsRes = await http.post(
        Uri.parse("https://sismob.trisakti.ac.id/api/get-krs"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "IdLogin": idLogin,
          "token": token,
          "IdSemester": widget.idSemester,
        }),
      );

      final krsJson = jsonDecode(krsRes.body);

      kelas = List<Map<String, dynamic>>.from(krsJson["body"]["kelas"] ?? []);

      /// GET MAX SKS
      final reqRes = await http.post(
        Uri.parse("https://sismob.trisakti.ac.id/api/krs-requirement"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      final reqJson = jsonDecode(reqRes.body);

      maxSks = int.tryParse(reqJson["body"]["maks_sks"].toString()) ?? 0;
      // maxSks = 24; // Set default max SKS, since API might not provide it

      /// GET SEMESTER
      final semRes = await http.post(
        Uri.parse("https://sismob.trisakti.ac.id/api/get-semester"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"IdLogin": idLogin, "token": token}),
      );

      final semJson = jsonDecode(semRes.body);

      semesters = semJson["body"]["semester"] ?? [];
    } catch (e) {
      print(e);
    }

    setState(() {
      _loading = false;
    });
  }

  /// ================= TOTAL SKS =================

  int get totalSks {
    int total = 0;
    for (var k in kelas) {
      total += int.tryParse(k["sks"].toString()) ?? 0;
    }
    return total;
  }

  /// ================= CHECK SLOT =================

  Map<String, dynamic>? getCourseForSlot(String day, String time) {
    for (var mk in kelas) {
      for (var j in mk["jadwal"]) {
        if (j["hari"] == day) {
          final start = j["mulai"].substring(0, 2);
          final end = j["selesai"].substring(0, 2);

          final slot = time.substring(0, 2);

          int slotH = int.parse(slot);
          int startH = int.parse(start);
          int endH = int.parse(end);

          if (slotH >= startH && slotH < endH) {
            return mk;
          }
        }
      }
    }
    return null;
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final semesterLevel = semesters.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal KRS"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
                  semesters.isNotEmpty
                      ? semesters.first["SemesterMainName"]
                      : "-",
                ),
                _infoRow("Semester Level", semesterLevel.toString()),
                _infoRow("Total Credit", "$totalSks/$maxSks"),
              ],
            ),
          ),

          /// ======= SCHEDULE =======
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Schedule",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 700,
                child: Column(
                  children: [
                    /// HEADER
                    Row(
                      children: [
                        _headerCell("Time"),
                        ...days.map((d) => _headerCell(d.substring(0, 3))),
                      ],
                    ),

                    /// ROWS
                    Expanded(
                      child: ListView.builder(
                        itemCount: timeSlots.length,
                        itemBuilder: (context, i) {
                          final time = timeSlots[i];

                          return Row(
                            children: [
                              _timeCell(time),

                              ...days.map((day) {
                                final course = getCourseForSlot(day, time);

                                return _courseCell(course);
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _headerCell(String text) {
    return Container(
      width: 100,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryBlue,
        border: Border.all(color: Colors.white),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _timeCell(String text) {
    return Container(
      width: 80,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.white),
      ),
      child: Text(text),
    );
  }

  Widget _courseCell(Map<String, dynamic>? course) {
    if (course == null) {
      return Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      );
    }

    return Container(
      width: 100,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        course["kodemk"],
        style: const TextStyle(color: Colors.white, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
