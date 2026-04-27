import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/mbkm_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class MbkmExchangePage extends StatefulWidget {
  const MbkmExchangePage({super.key});

  @override
  State<MbkmExchangePage> createState() => _MbkmExchangePageState();
}

class _MbkmExchangePageState extends State<MbkmExchangePage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String? _idSemesterMain;
  MbkmExchangeCourseData? _data;
  bool _showApplied = false;
  bool _showInternal = false;
  bool _showExternal = false;

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final results = await Future.wait([
        MbkmService.getExchangeCourses(
          idLogin: session.idLogin,
          token: session.token,
        ),
        MbkmService.getActiveSemesterId(
          idLogin: session.idLogin,
          token: session.token,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _data = results[0] as MbkmExchangeCourseData;
        _idSemesterMain = results[1] as String;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyCourse(MbkmExchangeCourse course) async {
    if (_idSemesterMain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semester aktif belum ditemukan')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ajukan Mata Kuliah'),
          content: Text(
            'Ajukan ${course.subjectCode} - ${course.subjectName} ke MBKM Pertukaran Mahasiswa?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ajukan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final message = await MbkmService.saveExchangeCourse(
        idLogin: session.idLogin,
        token: session.token,
        outbound: '0',
        idSemesterMain: _idSemesterMain!,
        kelas: [course.idCourseTaggingGroup, course.lecturerId],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan mata kuliah: $e')),
      );
    }
  }

  Future<void> _deleteAppliedCourse(MbkmExchangeAppliedCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Mata Kuliah'),
          content: Text(
            'Hapus pengajuan untuk ${course.subjectCode} - ${course.subjectName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final message = await MbkmService.deleteExchangeCourse(
        idLogin: session.idLogin,
        token: session.token,
        outbound: '0',
        idSemesterMain: course.semesterId,
        kelas: [course.idCourseTaggingGroup, course.lecturerId],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus mata kuliah: $e')),
      );
    }
  }

  bool _matchesSearch(MbkmExchangeCourse course, String query) {
    if (query.isEmpty) return true;

    final normalized = query.toLowerCase();
    final bag = [
      course.subjectCode,
      course.subjectName,
      course.programName,
      course.groupCode,
      course.lecturer,
      course.day,
    ].join(' ').toLowerCase();

    return bag.contains(normalized);
  }

  bool _isCourseApplied(MbkmExchangeCourse course) {
    final appliedCourses =
        _data?.appliedCourses ?? const <MbkmExchangeAppliedCourse>[];
    return appliedCourses.any(
      (item) =>
          item.idCourseTaggingGroup == course.idCourseTaggingGroup &&
          item.lecturerId == course.lecturerId,
    );
  }

  void _toggleSection(_MbkmExchangeSection section) {
    setState(() {
      final shouldExpand = switch (section) {
        _MbkmExchangeSection.applied => !_showApplied,
        _MbkmExchangeSection.internal => !_showInternal,
        _MbkmExchangeSection.external => !_showExternal,
      };

      _showApplied = false;
      _showInternal = false;
      _showExternal = false;

      if (!shouldExpand) {
        return;
      }

      switch (section) {
        case _MbkmExchangeSection.applied:
          _showApplied = true;
        case _MbkmExchangeSection.internal:
          _showInternal = true;
        case _MbkmExchangeSection.external:
          _showExternal = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final query = _searchController.text.trim();
    final filteredApplied = data == null
        ? const <MbkmExchangeAppliedCourse>[]
        : data.appliedCourses
              .where((course) => _matchesSearch(course, query))
              .toList();
    final filteredInternal = data == null
        ? const <MbkmExchangeCourse>[]
        : data.internalCourses
              .where((course) => _matchesSearch(course, query))
              .toList();
    final filteredExternal = data == null
        ? const <MbkmExchangeCourse>[]
        : data.externalCourses
              .where((course) => _matchesSearch(course, query))
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MBKM Pertukaran Mahasiswa'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MbkmExchangeSchedulePage(
                      courses: data.appliedCourses.isNotEmpty
                          ? data.appliedCourses
                          : data.internalCourses,
                    ),
                  ),
                );
              },
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Jadwal'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : data == null
          ? const Center(
              child: Text('Data pertukaran mahasiswa tidak tersedia'),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildHeroCard(data)),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySectionHeaderDelegate(
                      minExtentValue: 82,
                      maxExtentValue: 82,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: _buildPinnedSearchBar(),
                      ),
                    ),
                  ),
                  ..._buildSectionSlivers(
                    title: 'Mata Kuliah Sudah Diajukan',
                    isExpanded: _showApplied,
                    onToggle: () =>
                        _toggleSection(_MbkmExchangeSection.applied),
                    child: filteredApplied.isEmpty
                        ? _buildEmptyState(
                            query.isEmpty
                                ? 'Belum ada mata kuliah yang diajukan'
                                : 'Tidak ada hasil yang cocok di mata kuliah diajukan',
                          )
                        : Column(
                            children: filteredApplied
                                .map(
                                  (course) => _buildAppliedCourseCard(course),
                                )
                                .toList(),
                          ),
                  ),
                  ..._buildSectionSlivers(
                    title: 'Mata Kuliah Internal',
                    isExpanded: _showInternal,
                    onToggle: () =>
                        _toggleSection(_MbkmExchangeSection.internal),
                    child: filteredInternal.isEmpty
                        ? _buildEmptyState(
                            query.isEmpty
                                ? 'Belum ada mata kuliah internal'
                                : 'Tidak ada hasil yang cocok di mata kuliah internal',
                          )
                        : Column(
                            children: filteredInternal
                                .map((course) => _buildCourseCard(course))
                                .toList(),
                          ),
                  ),
                  ..._buildSectionSlivers(
                    title: 'Mata Kuliah External',
                    isExpanded: _showExternal,
                    onToggle: () =>
                        _toggleSection(_MbkmExchangeSection.external),
                    child: filteredExternal.isEmpty
                        ? _buildEmptyState(
                            query.isEmpty
                                ? 'Belum ada mata kuliah external'
                                : 'Tidak ada hasil yang cocok di mata kuliah external',
                          )
                        : Column(
                            children: filteredExternal
                                .map((course) => _buildCourseCard(course))
                                .toList(),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSectionSlivers({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return [
      if (isExpanded)
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySectionHeaderDelegate(
            minExtentValue: 80,
            maxExtentValue: 80,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildSectionHeader(
                title: title,
                isExpanded: isExpanded,
                onToggle: onToggle,
                isPinned: true,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: title,
              isExpanded: isExpanded,
              onToggle: onToggle,
            ),
          ),
        ),
      if (isExpanded)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: child),
        ),
    ];
  }

  Widget _buildHeroCard(MbkmExchangeCourseData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue.withAlpha(235), AppThemePalette.dark(0.12)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withAlpha(28),
          //     borderRadius: BorderRadius.circular(999),
          //     border: Border.all(color: Colors.white24),
          //   ),
          //   child: const Text(
          //     'Exchange Course Hub',
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 11,
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 12),
          const Text(
            'MBKM Pertukaran Mahasiswa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola pilihan mata kuliah pertukaran mahasiswa.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari mata kuliah, dosen, program, atau kode',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryBlue.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryBlue.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryBlue, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildPinnedSearchBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemePalette.soft(0.985),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildSearchField(),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    bool isPinned = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isPinned ? 246 : 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withAlpha(isPinned ? 26 : 18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isPinned ? 17 : 18,
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryBlue,
                        size: 28,
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

  Widget _buildCourseCard(MbkmExchangeCourse course) {
    final isApplied = _isCourseApplied(course);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withAlpha(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(course.subjectCode),
              _chip(course.groupCode),
              _chip('${course.creditHours} SKS'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.subjectName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.programName,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppThemePalette.soft(0.96),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _plainDetail(course.scheduleLabel),
                Divider(height: 18, color: primaryBlue.withAlpha(18)),
                const SizedBox(height: 2),
                const SizedBox(height: 8),
                _plainDetail(course.lecturer),
                Divider(height: 18, color: primaryBlue.withAlpha(18)),
                const SizedBox(height: 2),
                const SizedBox(height: 8),
                _plainDetail('${course.appliedCount} peminat'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: isApplied
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.withAlpha(38)),
                    ),
                    child: const Text(
                      'Sudah Diajukan',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => _applyCourse(course),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Ajukan'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedCourseCard(MbkmExchangeAppliedCourse course) {
    final canDelete = course.canDelete;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppThemePalette.soft(0.94)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryBlue.withAlpha(26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(course.subjectCode),
                    _chip(course.groupCode),
                    _statusChip(course.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.subjectName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.programName,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _plainDetail(course.scheduleLabel),
                Divider(height: 18, color: primaryBlue.withAlpha(18)),
                const SizedBox(height: 2),
                const SizedBox(height: 8),
                _plainDetail(course.lecturer),
                Divider(height: 18, color: primaryBlue.withAlpha(18)),
                const SizedBox(height: 2),
                const SizedBox(height: 8),
                _plainDetail('Approval: ${course.approvalStatus}'),
                Divider(height: 18, color: primaryBlue.withAlpha(18)),
                const SizedBox(height: 2),
                const SizedBox(height: 8),
                _plainDetail('Remark: ${course.remark}'),
              ],
            ),
          ),
          if (canDelete) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _deleteAppliedCourse(course),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withAlpha(18)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryBlue.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryBlue.withAlpha(24)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _plainDetail(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
    );
  }

  Widget _statusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.amber.shade900,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MbkmExchangeSchedulePage extends StatelessWidget {
  final List<MbkmExchangeCourse> courses;

  const MbkmExchangeSchedulePage({super.key, required this.courses});

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> _timeSlots = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
  ];

  Color get primaryBlue => AppThemePalette.primary;

  @override
  Widget build(BuildContext context) {
    final totalCredits = courses.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.creditHours) ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pertukaran Mahasiswa'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
                _scheduleInfoRow(
                  'Jumlah Mata Kuliah',
                  courses.length.toString(),
                ),
                _scheduleInfoRow('Total SKS', totalCredits.toStringAsFixed(2)),
                _scheduleInfoRow('Sumber Jadwal', 'Data MBKM Exchange'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Schedule',
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
                    Row(
                      children: [
                        _headerCell('Time'),
                        ..._days.map((day) => _headerCell(day.substring(0, 3))),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final time = _timeSlots[index];
                          return Row(
                            children: [
                              _timeCell(time),
                              ..._days.map((day) {
                                final course = _getCourseForSlot(day, time);
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

  MbkmExchangeCourse? _getCourseForSlot(String day, String time) {
    for (final course in courses) {
      if (course.day != day) {
        continue;
      }

      final slotHour = int.tryParse(time.substring(0, 2));
      final startHour = int.tryParse(course.startTime.substring(0, 2));
      final endHour = int.tryParse(course.endTime.substring(0, 2));

      if (slotHour == null || startHour == null || endHour == null) {
        continue;
      }

      if (slotHour >= startHour && slotHour < endHour) {
        return course;
      }
    }

    return null;
  }

  Widget _scheduleInfoRow(String title, String value) {
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

  Widget _courseCell(MbkmExchangeCourse? course) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          course.subjectCode,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  const _StickySectionHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: overlapsContent
            ? AppThemePalette.soft(0.98)
            : Colors.transparent,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySectionHeaderDelegate oldDelegate) {
    return minExtentValue != oldDelegate.minExtentValue ||
        maxExtentValue != oldDelegate.maxExtentValue ||
        child != oldDelegate.child;
  }
}

enum _MbkmExchangeSection { applied, internal, external }
