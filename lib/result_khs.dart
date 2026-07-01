import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/khs_models.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/services/khs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

@visibleForTesting
Widget buildKhsPerformanceCardForTest({
  required String title,
  required String value,
  required IconData icon,
}) {
  return _KhsPerformanceCard(title: title, value: value, icon: icon);
}

class HasilKhsPage extends StatefulWidget {
  const HasilKhsPage({super.key});

  @override
  State<HasilKhsPage> createState() => _HasilKhsPageState();
}

class _HasilKhsPageState extends State<HasilKhsPage> {
  Color get primaryBlue => AppThemePalette.primary;

  bool isLoading = true;
  String? _error;
  List<KhsCourseDetail> khsDetailList = const [];
  KhsPerformance kinerja = const KhsPerformance(
    ips: '0.00',
    ipk: '0.00',
    sksSemester: '0',
    sksLulus: '0',
  );
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
      final (token, idLogin) = await _getAuth();
      if (token == null || idLogin == null) {
        return;
      }

      final pageData = await KhsService.fetchPageData(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;
      setState(() {
        _selectedSemesterId = pageData.defaultSemesterId;
        _semesters = pageData.semesters;
        kinerja = pageData.khs.performance;
        khsDetailList = pageData.khs.details;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchKhs() async {
    if (_selectedSemesterId == null) {
      return;
    }

    final (token, idLogin) = await _getAuth();
    if (token == null || idLogin == null) {
      return;
    }

    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final result = await KhsService.getKhs(
        idLogin: idLogin,
        token: token,
        idSemester: _selectedSemesterId!,
      );

      if (!mounted) return;
      setState(() {
        kinerja = result.performance;
        khsDetailList = result.details;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Hasil KHS'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSemesterPicker(),
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
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildKinerjaGrid(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Detail Mata Kuliah',
                              style: TextStyle(
                                color: AppThemePalette.textPrimary,
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
      color: AppThemePalette.surface,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSemesterId,
        dropdownColor: AppThemePalette.surface,
        style: TextStyle(color: AppThemePalette.textPrimary),
        decoration: InputDecoration(
          labelText: 'Semester',
          labelStyle: TextStyle(color: AppThemePalette.textSecondary),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppThemePalette.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryBlue, width: 1.4),
          ),
          fillColor: AppThemePalette.fieldFill,
          filled: true,
        ),
        items: _semesters
            .map(
              (semester) => DropdownMenuItem<String>(
                value: semester.idSemesterMaster,
                child: Text(
                  semester.semesterMainName,
                  style: TextStyle(color: AppThemePalette.textPrimary),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _selectedSemesterId = value);
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
          _cardKinerja('IPS', kinerja.ips, Icons.show_chart),
          _cardKinerja('IPK', kinerja.ipk, Icons.trending_up),
          _cardKinerja('SKS Semester', kinerja.sksSemester, Icons.school),
          _cardKinerja('SKS Lulus', kinerja.sksLulus, Icons.verified),
        ],
      ),
    );
  }

  Widget _cardKinerja(String title, String value, IconData icon) {
    return _KhsPerformanceCard(title: title, value: value, icon: icon);
  }

  Widget _buildKhsList() {
    if (khsDetailList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Text(
          'Tidak ada data KHS',
          style: TextStyle(color: AppThemePalette.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: khsDetailList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = khsDetailList[index];
        return Material(
          color: AppThemePalette.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showDetailModal(item),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppThemePalette.divider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  item.courseName,
                  style: TextStyle(
                    color: AppThemePalette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${item.courseCode} - ${item.credits} SKS',
                  style: TextStyle(color: AppThemePalette.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.gradeLetter,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppThemePalette.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailModal(KhsCourseDetail item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemePalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.courseName,
                style: TextStyle(
                  color: AppThemePalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.courseCode,
                style: TextStyle(color: AppThemePalette.textSecondary),
              ),
              Divider(height: 32, color: AppThemePalette.divider),
              _rowModal('Kelas', item.className),
              _rowModal('SKS', item.credits),
              _rowModal('Nilai Angka', item.gradePoint),
              _rowModal('Nilai Huruf', item.gradeLetter),
              _rowModal('Status', item.passStatus, isStatus: true),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _rowModal(String label, String value, {bool isStatus = false}) {
    final isPass = value == 'Pass';
    final statusColor = isPass ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppThemePalette.textSecondary)),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppThemePalette.isDark
                    ? statusColor.withAlpha(45)
                    : statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: AppThemePalette.isDark ? statusColor : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _KhsPerformanceCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KhsPerformanceCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppThemePalette.negative();

    return Container(
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemePalette.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
