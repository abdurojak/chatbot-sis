import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class SubmitKrsScreen extends StatefulWidget {
  final String idSemester;

  const SubmitKrsScreen({super.key, required this.idSemester});

  @override
  State<SubmitKrsScreen> createState() => _SubmitKrsScreenState();
}

class _SubmitKrsScreenState extends State<SubmitKrsScreen> {
  bool _isLoading = true;
  String? _error;

  List<KrsEnrollment> _krsList = const [];
  final List<String> _selectedCourses = [];
  List<SemesterInfo> _semesters = const [];

  int semesterLevel = 0;
  int totalSks = 0;
  int maxSks = 24;

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<(String?, String?)> _getAuth() async {
    final session = await SessionService.loadSession();
    return (session?.token, session?.idLogin);
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _fetchSemesters();
      await _fetchKrs();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSemesters() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final semesters = await KrsService.getSemesters(
      idLogin: idLogin,
      token: token,
    );

    if (!mounted) return;
    setState(() {
      _semesters = semesters;
      semesterLevel = semesters.length;
    });
  }

  Future<void> _fetchKrs() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final krs = await KrsService.getKrs(
      idLogin: idLogin,
      token: token,
      idSemester: widget.idSemester,
    );

    if (!mounted) return;
    setState(() {
      _krsList = krs;
      _selectedCourses.clear();
      totalSks = krs.fold<int>(0, (sum, item) => sum + item.creditsValue);
    });
  }

  Future<String?> _sendOtp() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return null;
    }

    final result = await KrsService.sendOtp(idLogin: idLogin, token: token);

    return result?.idOtp;
  }

  Future<void> _cancelCourse(String otp, String idOtp) async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final result = await KrsService.cancelCourses(
      idLogin: idLogin,
      token: token,
      otp: otp,
      idOtp: idOtp,
      courses: _selectedCourses,
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Berhasil drop mata kuliah'
              : result.message.isNotEmpty
              ? result.message
              : 'Gagal drop mata kuliah',
        ),
      ),
    );

    if (result.isSuccess) {
      await _fetchKrs();
    }
  }

  Future<void> _showOtpDialog() async {
    if (_selectedCourses.isEmpty) {
      return;
    }

    final idOtp = await _sendOtp();
    if (!mounted) return;

    if (idOtp == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal kirim OTP')));
      return;
    }

    final otpController = TextEditingController();
    final selectedItems = _krsList
        .where((item) => _selectedCourses.contains(item.idRegister))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppThemePalette.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text('Konfirmasi Drop MK'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...selectedItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item.code} - ${item.courseName}'),
                  subtitle: Text('Kelas: ${item.className}'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                style: TextStyle(color: AppThemePalette.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Masukkan OTP',
                  labelStyle: TextStyle(color: AppThemePalette.textSecondary),
                  filled: true,
                  fillColor: AppThemePalette.fieldFill,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemePalette.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryBlue, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _cancelCourse(otpController.text, idOtp);
              },
              child: const Text('Drop'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppThemePalette.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemePalette.accentAvatar,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSemester = _semesters.where(
      (semester) => semester.idSemesterMaster == widget.idSemester,
    );

    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('KRS Saya'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _selectedCourses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showOtpDialog,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: const Text('Drop MK'),
              icon: const Icon(Icons.delete),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: TextStyle(color: AppThemePalette.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppThemePalette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemePalette.divider),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePalette.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        'Semester to Register',
                        selectedSemester.isNotEmpty
                            ? selectedSemester.first.semesterMainName
                            : _semesters.isNotEmpty
                            ? _semesters.first.semesterMainName
                            : '-',
                      ),
                      _infoRow('Semester Level', semesterLevel.toString()),
                      _infoRow('Total Credit', '$totalSks/$maxSks'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _krsList.length,
                    itemBuilder: (context, index) {
                      final item = _krsList[index];
                      final isApproved = item.isApproved;
                      final canCancel = !isApproved;
                      final statusBackground = isApproved
                          ? AppThemePalette.isDark
                                ? Colors.green.withAlpha(38)
                                : Colors.green.shade100
                          : AppThemePalette.isDark
                          ? Colors.orange.withAlpha(38)
                          : Colors.orange.shade100;
                      final statusTextColor = isApproved
                          ? AppThemePalette.isDark
                                ? Colors.greenAccent.shade400
                                : Colors.green.shade700
                          : AppThemePalette.isDark
                          ? Colors.orangeAccent.shade200
                          : Colors.orange.shade800;

                      return Card(
                        color: AppThemePalette.surface,
                        margin: const EdgeInsets.only(bottom: 12),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppThemePalette.divider),
                        ),
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: primaryBlue,
                          checkColor: AppThemePalette.onPrimary(primaryBlue),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          value: _selectedCourses.contains(item.idRegister),
                          onChanged: canCancel
                              ? (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedCourses.add(item.idRegister);
                                    } else {
                                      _selectedCourses.remove(item.idRegister);
                                    }
                                  });
                                }
                              : null,
                          title: Text(
                            '${item.code} - ${item.courseName}',
                            style: TextStyle(
                              color: AppThemePalette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Kelas: ${item.className} | SKS: ${item.credits}',
                                style: TextStyle(
                                  color: AppThemePalette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isApproved
                                      ? 'Disetujui'
                                      : 'Menunggu Persetujuan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusTextColor,
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
