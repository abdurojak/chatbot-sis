import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/mbkm_apply_screen.dart';
import 'package:chatbot/mbkm_log_screen.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/mbkm_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MbkmOutboundPage extends StatefulWidget {
  const MbkmOutboundPage({
    super.key,
    this.initialData,
    this.skipInitialLoad = false,
  });

  final MbkmResponseData? initialData;
  final bool skipInitialLoad;

  @override
  State<MbkmOutboundPage> createState() => _MbkmOutboundPageState();
}

class _MbkmOutboundPageState extends State<MbkmOutboundPage> {
  bool _isLoading = true;
  String? _error;
  MbkmResponseData? _data;
  final Set<String> _expandedApplicationIds = <String>{};

  Color get primaryBlue => AppThemePalette.primary;
  Color get subtleText => AppThemePalette.textSecondary;
  Color get mutedText => AppThemePalette.textPrimary;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    if (widget.skipInitialLoad) {
      _isLoading = false;
    } else {
      _loadMbkm();
    }
  }

  Future<void> _loadMbkm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final data = await MbkmService.getMbkm(
        idLogin: session.idLogin,
        token: session.token,
      );

      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openLink(String url) async {
    final normalizedUrl =
        url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link tidak valid')));
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (opened || !mounted) {
        return;
      }

      final fallbackOpened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (fallbackOpened || !mounted) {
        return;
      }
    } catch (_) {
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal membuka link: $normalizedUrl')),
    );
  }

  Future<void> _showAddCompetencyModal(MbkmApplication item) async {
    final competencyController = TextEditingController();
    final learningSourceController = TextEditingController();
    final assessmentModelController = TextEditingController();
    final learningExperienceController = TextEditingController();
    final durationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemePalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final session = await SessionService.loadSession();
              if (session == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Sesi login tidak ditemukan')),
                );
                return;
              }

              setModalState(() => isSubmitting = true);

              try {
                final message = await MbkmService.addCompetency(
                  idLogin: session.idLogin,
                  token: session.token,
                  competency: competencyController.text.trim(),
                  learningSource: learningSourceController.text.trim(),
                  assessmentModel: assessmentModelController.text.trim(),
                  learningExperience: learningExperienceController.text.trim(),
                  durationInHour: durationController.text.trim(),
                  idMaCompetency: item.idApplication,
                );

                if (!mounted || !sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(message)));
                await _loadMbkm();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Gagal menambah kompetensi: $e')),
                );
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => isSubmitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppThemePalette.divider,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tambah Kompetensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(color: AppThemePalette.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: competencyController,
                        label: 'Kompetensi',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: learningSourceController,
                        label: 'Sumber Belajar',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: assessmentModelController,
                        label: 'Model Asesmen',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: learningExperienceController,
                        label: 'Pengalaman Belajar',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: durationController,
                        label: 'Durasi dalam Jam',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: AppThemePalette.onPrimary(),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppThemePalette.onPrimary(),
                                  ),
                                )
                              : const Text('Simpan Kompetensi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleApplication(String id) {
    setState(() {
      if (_expandedApplicationIds.contains(id)) {
        _expandedApplicationIds.remove(id);
      } else {
        _expandedApplicationIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final applications = _data?.applications ?? const <MbkmApplication>[];
    final biodata = _data?.biodata;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MBKM Outbound'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppThemePalette.background,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState(_error!)
          : RefreshIndicator(
              onRefresh: _loadMbkm,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // _buildCompactHeader(),
                  if (biodata != null) ...[
                    const SizedBox(height: 10),
                    _buildStudentSummary(biodata, applications),
                  ],
                  const SizedBox(height: 12),
                  _buildApplyButton(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daftar Pengajuan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppThemePalette.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Tarik untuk muat ulang',
                        style: TextStyle(
                          color: AppThemePalette.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (applications.isEmpty)
                    _buildEmptyState()
                  else
                    ...applications.map(_buildApplicationCard),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 14),
          Text(
            'Memuat data MBKM...',
            style: TextStyle(color: AppThemePalette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 50,
              color: AppThemePalette.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat MBKM',
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppThemePalette.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMbkm,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue.withAlpha(235), AppThemePalette.dark(0.12)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.language_rounded, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Outbound MBKM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSummary(
    MbkmBiodata biodata,
    List<MbkmApplication> applications,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePalette.divider),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppThemePalette.soft(0.86),
                child: Text(
                  _initials(biodata.name),
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biodata.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppThemePalette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      biodata.nim,
                      style: TextStyle(
                        color: AppThemePalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  value: applications.length.toString(),
                  label: 'pengajuan',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryMetric(
                  value: _competencyCount(applications).toString(),
                  label: 'kompetensi',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryMetric(value: '-', label: 'log'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemePalette.soft(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final submitted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const MbkmApplyPage()),
          );

          if (submitted == true) {
            await _loadMbkm();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: AppThemePalette.onPrimary(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Ajukan MBKM',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePalette.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            color: AppThemePalette.textTertiary,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada pengajuan MBKM',
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai pengajuan baru saat kamu sudah memiliki program outbound.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(MbkmApplication item) {
    final isExpanded = _expandedApplicationIds.contains(item.idApplication);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePalette.divider),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 74,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip(item.activityType),
                          _chip(item.scaleName),
                          _statusChip(item),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppThemePalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppThemePalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _compactInfo(
                              label: 'Periode',
                              value: _periodText(item),
                              icon: Icons.event_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _compactInfo(
                              label: 'Mentor',
                              value: item.internalMentorName,
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppThemePalette.divider),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openLog(item),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Lihat Log'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: BorderSide(color: primaryBlue.withAlpha(70)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleApplication(item.idApplication),
                    icon: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    label: const Text('Detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: AppThemePalette.onPrimary(),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: AppThemePalette.soft(0.95),
                    border: Border(
                      bottom: BorderSide(color: primaryBlue.withAlpha(25)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _compactStatCard(
                              'Semester',
                              item.semesterName,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _compactStatCard(
                              'Periode',
                              '${item.startDate} - ${item.endDate}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _compactStatCard(
                              'Seleksi',
                              item.selectionDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _compactStatCard('Hasil', item.resultDate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deskripsi Program',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: mutedText,
                        ),
                      ),
                      if (item.competencies.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildCompetencySection(item.competencies),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showAddCompetencyModal(item),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah Kompetensi'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openLog(item),
                            icon: const Icon(Icons.history, size: 16),
                            label: const Text('Lihat Log'),
                          ),
                          if (item.hasMoreInfo)
                            TextButton.icon(
                              onPressed: () => _openLink(item.moreInfoUrl),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Buka Link'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildCompetencyCard(MbkmCompetency item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePalette.soft(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.competency,
            style: TextStyle(fontWeight: FontWeight.w700, color: mutedText),
          ),
          const SizedBox(height: 8),
          _infoRow('Sumber Belajar', item.learningSource),
          _infoRow('Model Asesmen', item.assessmentModel),
          _infoRow('Pengalaman Belajar', item.learningExperience),
          _infoRow('Durasi', '${item.durationInHour} jam'),
        ],
      ),
    );
  }

  Widget _buildCompetencySection(List<MbkmCompetency> competencies) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePalette.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          iconColor: primaryBlue,
          collapsedIconColor: primaryBlue,
          title: Row(
            children: [
              Icon(Icons.school, size: 18, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Kompetensi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${competencies.length} kompetensi tersedia',
            style: TextStyle(color: subtleText),
          ),
          children: competencies.map(_buildCompetencyCard).toList(),
        ),
      ),
    );
  }

  Widget _compactInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppThemePalette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePalette.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppThemePalette.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppThemePalette.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppThemePalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(MbkmApplication item) {
    final hasMentor =
        item.internalMentorName.trim().isNotEmpty &&
        item.internalMentorName.trim() != '-';
    final color = hasMentor ? const Color(0xFF1F8A63) : const Color(0xFFAA6A08);
    final background = Color.lerp(color, AppThemePalette.surface, 0.86)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasMentor ? 'Aktif' : 'Menunggu',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _chip(String text, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? Colors.white.withAlpha(28) : AppThemePalette.soft(0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? Colors.white24 : primaryBlue.withAlpha(38),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: filled ? Colors.white : primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _compactStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemePalette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtleText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.25,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label, style: TextStyle(color: subtleText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: mutedText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openLog(MbkmApplication item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MbkmLogPage(idMa: item.idApplication, title: item.title),
      ),
    );
  }

  int _competencyCount(List<MbkmApplication> applications) {
    return applications.fold<int>(
      0,
      (total, item) => total + item.competencies.length,
    );
  }

  String _periodText(MbkmApplication item) {
    return '${item.startDate} - ${item.endDate}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MB';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
