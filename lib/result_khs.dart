import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/khs_models.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:chatbot/services/khs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

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
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSemesterPicker(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildKinerjaGrid(),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Detail Mata Kuliah',
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
        initialValue: _selectedSemesterId,
        decoration: InputDecoration(
          labelText: 'Semester',
          border: const OutlineInputBorder(),
          fillColor: AppThemePalette.fieldFill,
          filled: true,
        ),
        items: _semesters
            .map(
              (semester) => DropdownMenuItem<String>(
                value: semester.idSemesterMaster,
                child: Text(semester.semesterMainName),
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
          _cardKinerja('IPS', kinerja.ips, Colors.orange),
          _cardKinerja('IPK', kinerja.ipk, Colors.green),
          _cardKinerja('SKS Semester', kinerja.sksSemester, Colors.blue),
          _cardKinerja('SKS Lulus', kinerja.sksLulus, Colors.purple),
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
            item.courseName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text('${item.courseCode} • ${item.credits} SKS'),
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  void _showDetailModal(KhsCourseDetail item) {
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
                item.courseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.courseCode, style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
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
                color: value == 'Pass' ? Colors.green : Colors.red,
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
