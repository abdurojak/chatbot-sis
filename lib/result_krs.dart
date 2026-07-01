import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class HasilKrsPage extends StatefulWidget {
  const HasilKrsPage({super.key});

  @override
  State<HasilKrsPage> createState() => _HasilKrsPageState();
}

class _HasilKrsPageState extends State<HasilKrsPage> {
  Color get primaryBlue => AppThemePalette.primary;

  bool isLoading = true;
  String? _error;
  List<KrsEnrollment> kelasList = const [];
  List<SemesterInfo> _semesters = const [];

  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<(String?, String?)> _getAuth() async {
    final session = await SessionService.loadSession();
    return (session?.token, session?.idLogin);
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      await _fetchDefaultSemester();
      await _fetchSemesters();
      await fetchKrs();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchDefaultSemester() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    final requirement = await KrsService.getRequirements(
      idLogin: idLogin,
      token: token,
    );

    _selectedSemesterId = requirement.idSemester;
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

      final matched = semesters.where(
        (semester) => semester.idSemesterMaster == _selectedSemesterId,
      );

      _selectedSemesterId = matched.isNotEmpty
          ? matched.first.idSemesterMaster
          : semesters.isNotEmpty
          ? semesters.first.idSemesterMaster
          : null;
    });
  }

  Future<void> fetchKrs() async {
    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null || _selectedSemesterId == null) {
      return;
    }

    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final items = await KrsService.getKrs(
        idLogin: idLogin,
        token: token,
        idSemester: _selectedSemesterId!,
      );

      if (!mounted) return;
      setState(() => kelasList = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onSemesterChanged(String? value) {
    setState(() => _selectedSemesterId = value);
    fetchKrs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Hasil KRS'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSemesterId,
              dropdownColor: AppThemePalette.surface,
              style: TextStyle(color: AppThemePalette.textPrimary),
              decoration: InputDecoration(
                labelText: 'Pilih Semester',
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
              items: _semesters.map((semester) {
                return DropdownMenuItem<String>(
                  value: semester.idSemesterMaster,
                  child: Text(
                    semester.semesterMainName,
                    style: TextStyle(color: AppThemePalette.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: _onSemesterChanged,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppThemePalette.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                : kelasList.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data KRS',
                      style: TextStyle(
                        color: AppThemePalette.textSecondary,
                        fontSize: 16,
                      ),
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
        final isApproved = kelas.isApproved;
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
          margin: const EdgeInsets.only(bottom: 16),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppThemePalette.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${kelas.code} - ${kelas.courseName}',
                  style: TextStyle(
                    color: AppThemePalette.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SKS: ${kelas.credits}',
                  style: TextStyle(color: AppThemePalette.textSecondary),
                ),
                Text(
                  'Kelas: ${kelas.className}',
                  style: TextStyle(color: AppThemePalette.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Jadwal:',
                  style: TextStyle(
                    color: AppThemePalette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...kelas.schedules.map(
                  (jadwal) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${jadwal.day} | ${jadwal.startTime} - ${jadwal.endTime} | Ruang: ${jadwal.room}',
                      style: TextStyle(
                        color: AppThemePalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isApproved ? 'Disetujui' : 'Menunggu Persetujuan',
                      style: TextStyle(
                        color: statusTextColor,
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
