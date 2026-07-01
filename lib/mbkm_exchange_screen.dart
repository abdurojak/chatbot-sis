import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/mbkm_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class MbkmExchangePage extends StatefulWidget {
  const MbkmExchangePage({
    super.key,
    this.initialData,
    this.initialSemesterId,
    this.skipInitialLoad = false,
  });

  final MbkmExchangeCourseData? initialData;
  final String? initialSemesterId;
  final bool skipInitialLoad;

  @override
  State<MbkmExchangePage> createState() => _MbkmExchangePageState();
}

class _MbkmExchangePageState extends State<MbkmExchangePage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String? _idSemesterMain;
  MbkmExchangeCourseData? _data;
  _MbkmExchangeSection _selectedSection = _MbkmExchangeSection.applied;

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _idSemesterMain = widget.initialSemesterId;
    if (widget.skipInitialLoad) {
      _isLoading = false;
      return;
    }
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

  void _selectSection(_MbkmExchangeSection section) {
    setState(() => _selectedSection = section);
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
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('MBKM Pertukaran Mahasiswa'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : data == null
          ? const Center(
              child: Text('Data pertukaran mahasiswa tidak tersedia'),
            )
          : data.isUnavailable
          ? RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 80),
                  _buildUnavailableState(data.message),
                ],
              ),
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
                      minExtentValue: 148,
                      maxExtentValue: 148,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: _buildPinnedControls(
                          appliedCount: filteredApplied.length,
                          internalCount: filteredInternal.length,
                          externalCount: filteredExternal.length,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildSelectedSection(
                        data: data,
                        query: query,
                        filteredApplied: filteredApplied,
                        filteredInternal: filteredInternal,
                        filteredExternal: filteredExternal,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectedSection({
    required MbkmExchangeCourseData data,
    required String query,
    required List<MbkmExchangeAppliedCourse> filteredApplied,
    required List<MbkmExchangeCourse> filteredInternal,
    required List<MbkmExchangeCourse> filteredExternal,
  }) {
    final title = switch (_selectedSection) {
      _MbkmExchangeSection.applied => 'Mata Kuliah Diajukan',
      _MbkmExchangeSection.internal => 'Mata Kuliah Internal',
      _MbkmExchangeSection.external => 'Mata Kuliah External',
    };
    final emptyText = switch (_selectedSection) {
      _MbkmExchangeSection.applied =>
        query.isEmpty
            ? 'Belum ada mata kuliah yang diajukan'
            : 'Tidak ada hasil yang cocok di mata kuliah diajukan',
      _MbkmExchangeSection.internal =>
        query.isEmpty
            ? 'Belum ada mata kuliah internal'
            : 'Tidak ada hasil yang cocok di mata kuliah internal',
      _MbkmExchangeSection.external =>
        query.isEmpty
            ? 'Belum ada mata kuliah external'
            : 'Tidak ada hasil yang cocok di mata kuliah external',
    };
    final courses = switch (_selectedSection) {
      _MbkmExchangeSection.applied => filteredApplied,
      _MbkmExchangeSection.internal => filteredInternal,
      _MbkmExchangeSection.external => filteredExternal,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentToolbar(title, data),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          _buildEmptyState(emptyText)
        else
          ...courses.map((course) {
            if (course is MbkmExchangeAppliedCourse) {
              return _buildAppliedCourseCard(course);
            }
            return _buildCourseCard(course);
          }),
      ],
    );
  }

  Widget _buildContentToolbar(String title, MbkmExchangeCourseData data) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton.icon(
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
          style: FilledButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: const Text('Jadwal'),
        ),
      ],
    );
  }

  Widget _buildHeroCard(MbkmExchangeCourseData data) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const Text(
            'Pertukaran Mahasiswa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  value: data.appliedCourses.length.toString(),
                  label: 'Diajukan',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroStat(
                  value: data.internalCourses.length.toString(),
                  label: 'Internal',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroStat(
                  value: data.externalCourses.length.toString(),
                  label: 'External',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableState(String message) {
    final displayMessage = message.isEmpty
        ? 'Pendaftaran pertukaran mahasiswa belum dibuka'
        : message;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePalette.divider),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, color: primaryBlue, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan cek kembali halaman ini secara berkala.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppThemePalette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadData,
            style: FilledButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Muat Ulang'),
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
        fillColor: AppThemePalette.fieldFill,
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

  Widget _buildPinnedControls({
    required int appliedCount,
    required int internalCount,
    required int externalCount,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemePalette.background.withAlpha(248),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 10),
            _buildSegmentedTabs(
              appliedCount: appliedCount,
              internalCount: internalCount,
              externalCount: externalCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs({
    required int appliedCount,
    required int internalCount,
    required int externalCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppThemePalette.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePalette.divider),
      ),
      child: Row(
        children: [
          _segmentButton(
            section: _MbkmExchangeSection.applied,
            label: 'Diajukan',
            count: appliedCount,
          ),
          _segmentButton(
            section: _MbkmExchangeSection.internal,
            label: 'Internal',
            count: internalCount,
          ),
          _segmentButton(
            section: _MbkmExchangeSection.external,
            label: 'External',
            count: externalCount,
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required _MbkmExchangeSection section,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedSection == section;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectSection(section),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppThemePalette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppThemePalette.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$label $count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? primaryBlue : AppThemePalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(MbkmExchangeCourse course) {
    final isApplied = _isCourseApplied(course);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(24)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
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
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.programName,
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildCourseDetailGrid([
            _CourseDetail(label: 'Jadwal', value: course.scheduleLabel),
            _CourseDetail(label: 'Dosen', value: course.lecturer),
            _CourseDetail(
              label: 'Peminat',
              value: '${course.appliedCount} mahasiswa',
            ),
          ]),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
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
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.programName,
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildCourseDetailGrid([
            _CourseDetail(label: 'Jadwal', value: course.scheduleLabel),
            _CourseDetail(label: 'Dosen', value: course.lecturer),
            _CourseDetail(label: 'Approval', value: course.approvalStatus),
            _CourseDetail(label: 'Remark', value: course.remark),
          ]),
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
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withAlpha(18)),
      ),
      child: Text(text, style: TextStyle(color: AppThemePalette.textTertiary)),
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

  Widget _buildCourseDetailGrid(List<_CourseDetail> details) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: details
              .map(
                (detail) => SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppThemePalette.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppThemePalette.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppThemePalette.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppThemePalette.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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

class _CourseDetail {
  final String label;
  final String value;

  const _CourseDetail({required this.label, required this.value});
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
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Jadwal Pertukaran Mahasiswa'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppThemePalette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemePalette.divider),
              boxShadow: [
                BoxShadow(color: AppThemePalette.shadow, blurRadius: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Schedule',
                style: TextStyle(
                  color: AppThemePalette.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppThemePalette.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemePalette.fieldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
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
        border: Border.all(color: AppThemePalette.background),
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
        color: AppThemePalette.fieldFill,
        border: Border.all(color: AppThemePalette.background),
      ),
      child: Text(text, style: TextStyle(color: AppThemePalette.textPrimary)),
    );
  }

  Widget _courseCell(MbkmExchangeCourse? course) {
    if (course == null) {
      return Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: AppThemePalette.surface,
          border: Border.all(color: AppThemePalette.background),
        ),
      );
    }

    return Container(
      width: 100,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemePalette.background),
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
