import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/component/app_loading_button.dart';
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
  bool _isDropping = false;
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
    if (_isDropping) {
      return;
    }

    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    setState(() => _isDropping = true);

    try {
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
    } finally {
      if (mounted) {
        setState(() => _isDropping = false);
      }
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

    final selectedItems = _krsList
        .where((item) => _selectedCourses.contains(item.idRegister))
        .toList();

    await showDropKrsOtpSheet(
      context: context,
      selectedItems: selectedItems,
      onSubmit: (otp) => _cancelCourse(otp, idOtp),
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

Future<void> showDropKrsOtpSheet({
  required BuildContext context,
  required List<KrsEnrollment> selectedItems,
  required Future<void> Function(String otp) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppThemePalette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return _DropKrsOtpSheet(
        selectedItems: selectedItems,
        onSubmit: onSubmit,
      );
    },
  );
}

class _DropKrsOtpSheet extends StatefulWidget {
  final List<KrsEnrollment> selectedItems;
  final Future<void> Function(String otp) onSubmit;

  const _DropKrsOtpSheet({
    required this.selectedItems,
    required this.onSubmit,
  });

  @override
  State<_DropKrsOtpSheet> createState() => _DropKrsOtpSheetState();
}

class _DropKrsOtpSheetState extends State<_DropKrsOtpSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_otpController.text.trim());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppThemePalette.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppThemePalette.negative().withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppThemePalette.negative(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Drop MK',
                          style: TextStyle(
                            color: AppThemePalette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Masukkan kode OTP untuk melanjutkan.',
                          style: TextStyle(
                            color: AppThemePalette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...widget.selectedItems.map(_DropCourseCard.new),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  color: AppThemePalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  labelText: 'Kode OTP',
                  hintText: 'Masukkan OTP',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  labelStyle: TextStyle(color: AppThemePalette.textSecondary),
                  filled: true,
                  fillColor: AppThemePalette.fieldFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppThemePalette.divider),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppThemePalette.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppThemePalette.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppThemePalette.textPrimary,
                        side: BorderSide(color: AppThemePalette.divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppLoadingButton(
                      label: 'Drop MK',
                      loadingLabel: 'Memproses...',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                      icon: Icons.delete_outline_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropCourseCard extends StatelessWidget {
  final KrsEnrollment course;

  const _DropCourseCard(this.course);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePalette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePalette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.courseName,
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${course.code} - Kelas ${course.className} - ${course.credits} SKS',
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
