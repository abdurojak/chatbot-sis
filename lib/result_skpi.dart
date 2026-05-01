import 'dart:typed_data';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/skpi_models.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:chatbot/services/skpi_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class HasilSkpiPage extends StatefulWidget {
  const HasilSkpiPage({super.key});

  @override
  State<HasilSkpiPage> createState() => _HasilSkpiPageState();
}

class _HasilSkpiPageState extends State<HasilSkpiPage> {
  Color get primaryBlue => AppThemePalette.primary;

  bool _isLoading = true;
  String? _error;
  String? _loadingEvidenceId;
  List<SkpiOrganization> _organizations = const [];
  List<SkpiLanguage> _languages = const [];
  List<SkpiSoftskill> _softskills = const [];
  List<SkpiHonor> _honors = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final pageData = await SkpiService.fetchPageData(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _organizations = pageData.organizations;
        _languages = pageData.languages;
        _softskills = pageData.softskills;
        _honors = pageData.honors;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data SKPI. Silakan coba lagi.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openEvidence({
    required String idFile,
    required String title,
  }) async {
    if (idFile.isEmpty || _loadingEvidenceId == idFile) {
      return;
    }

    setState(() {
      _loadingEvidenceId = idFile;
    });

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final evidence = await SkpiService.getEvidence(
        idLogin: idLogin,
        token: token,
        idFile: idFile,
      );

      if (!mounted) return;

      final page = evidence.isPdf
          ? _SkpiPdfPreviewPage(title: title, bytes: evidence.bytes)
          : _SkpiImagePreviewPage(title: title, bytes: evidence.bytes);

      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka evidence: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingEvidenceId = null;
        });
      }
    }
  }

  Future<void> _openAddHonorForm() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AddHonorPage()),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = AppThemePalette.onPrimary(primaryBlue);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('SKPI'),
        backgroundColor: primaryBlue,
        foregroundColor: onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryBlue,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeroCard(onPrimary),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorCard()
            else ...[
              _buildSectionCard<SkpiOrganization>(
                title: 'Organisasi',
                subtitle:
                    '${_organizations.length} pengalaman organisasi dan kepanitiaan',
                icon: Icons.groups_rounded,
                accentColor: const Color(0xFFFF7A59),
                items: _organizations,
                itemBuilder: _buildOrganizationItem,
              ),
              const SizedBox(height: 14),
              _buildSectionCard<SkpiLanguage>(
                title: 'Bahasa Asing',
                subtitle: _languages.isEmpty
                    ? 'Belum ada data bahasa asing'
                    : 'Skor terbaik ${_languages.first.standardName} ${_languages.first.score}',
                icon: Icons.translate_rounded,
                accentColor: const Color(0xFF2F80ED),
                items: _languages,
                itemBuilder: _buildLanguageItem,
              ),
              const SizedBox(height: 14),
              _buildSectionCard<SkpiSoftskill>(
                title: 'Softskill',
                subtitle: _softskills.isEmpty
                    ? 'Belum ada data softskill'
                    : '${_softskills.length} pelatihan, seminar, dan workshop pendukung',
                icon: Icons.workspace_premium_rounded,
                accentColor: const Color(0xFF34A853),
                items: _softskills,
                itemBuilder: _buildSoftskillItem,
              ),
              const SizedBox(height: 14),
              _buildSectionCard<SkpiHonor>(
                title: 'Penghargaan',
                subtitle: _honors.isEmpty
                    ? 'Belum ada data penghargaan'
                    : '${_honors.length} penghargaan dan pencapaian akademik',
                icon: Icons.emoji_events_rounded,
                accentColor: const Color(0xFFF4B400),
                items: _honors,
                itemBuilder: _buildHonorItem,
                action: FilledButton.icon(
                  onPressed: _openAddHonorForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(Color onPrimary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, AppThemePalette.dark(0.14)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withAlpha(55),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Student Achievement Profile',
              style: TextStyle(
                color: onPrimary.withAlpha(230),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'SKPI',
            style: TextStyle(
              color: onPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ringkasan capaian mahasiswa dalam Surat Keterangan Pendamping Ijazah ditampilkan dalam format yang lebih rapi, ringkas, dan mudah ditelusuri.',
            style: TextStyle(
              color: onPrimary.withAlpha(230),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SkpiSummaryBadges(
            organizationCount: _organizations.length,
            languageCount: _languages.length,
            softskillCount: _softskills.length,
            honorCount: _honors.length,
            textColor: onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withAlpha(35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 34),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildSectionCard<T>({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                if (action != null) ...[const SizedBox(height: 12), action],
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          children: items.isEmpty
              ? [_buildEmptyState(title)]
              : List.generate(
                  items.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 14,
                    ),
                    child: itemBuilder(items[index], index),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Belum ada data untuk bagian $title.',
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildOrganizationItem(SkpiOrganization item, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE1D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A59),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.occupation,
                      style: const TextStyle(
                        color: Color(0xFFFF7A59),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(item.level),
              _buildMetaChip(item.category),
              _buildMetaChip(item.periodLabel),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvidenceButton(
            idFile: item.evidenceFileId,
            title: item.displayTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(SkpiLanguage item, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.languageName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.standardName,
                      style: const TextStyle(
                        color: Color(0xFF2F80ED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Score',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(item.languageCode),
              _buildMetaChip(item.takenDateLabel),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvidenceButton(
            idFile: item.evidenceFileId,
            title: item.languageName,
          ),
        ],
      ),
    );
  }

  Widget _buildSoftskillItem(SkpiSoftskill item, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FFF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7F0DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.givenBy,
                      style: const TextStyle(
                        color: Color(0xFF34A853),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Durasi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.hoursLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(item.periodLabel),
              _buildMetaChip('Kegiatan pendukung'),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvidenceButton(
            idFile: item.evidenceFileId,
            title: item.displayTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildHonorItem(SkpiHonor item, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFBE3A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.givenBy,
                      style: const TextStyle(
                        color: Color(0xFFC58B00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B400),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(item.level),
              _buildMetaChip(item.field),
              _buildMetaChip(item.honorDateLabel),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvidenceButton(
            idFile: item.evidenceFileId,
            title: item.displayTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceButton({required String idFile, required String title}) {
    if (idFile.isEmpty) {
      return const SizedBox.shrink();
    }

    final isLoading = _loadingEvidenceId == idFile;

    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => _openEvidence(idFile: idFile, title: title),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.visibility_rounded, size: 18),
        label: Text(isLoading ? 'Membuka...' : 'Lihat Evidence'),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: primaryBlue.withAlpha(90)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
        ),
      ),
    );
  }
}

class _AddHonorPage extends StatefulWidget {
  const _AddHonorPage();

  @override
  State<_AddHonorPage> createState() => _AddHonorPageState();
}

class _AddHonorPageState extends State<_AddHonorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleBahasaController = TextEditingController();
  final _dateController = TextEditingController();
  final _givenByController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _selectedLevel;
  String? _selectedField;
  List<SkpiReferenceOption> _levels = const [];
  List<SkpiReferenceOption> _fields = const [];

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleBahasaController.dispose();
    _dateController.dispose();
    _givenByController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;
      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final data = await SkpiService.getHonorReferences(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;
      setState(() {
        _levels = data.levels;
        _fields = data.fields;
        _selectedLevel = data.levels.isNotEmpty ? data.levels.first.key : null;
        _selectedField = data.fields.isNotEmpty ? data.fields.first.key : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat referensi penghargaan.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null || !mounted) return;
    _dateController.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = await SessionService.loadSession();
    final token = session?.token;
    final idLogin = session?.idLogin;
    if (token == null || idLogin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan')),
      );
      return;
    }

    if (_selectedLevel == null || _selectedField == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referensi penghargaan belum lengkap')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await SkpiService.addHonor(
        idLogin: idLogin,
        token: token,
        title: _titleController.text.trim(),
        titleBahasa: _titleBahasaController.text.trim(),
        dateOfHonor: _dateController.text.trim(),
        givenBy: _givenByController.text.trim(),
        level: _selectedLevel!,
        field: _selectedField!,
      );

      if (!mounted) return;
      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan penghargaan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Tambah Penghargaan'),
        backgroundColor: primaryBlue,
        foregroundColor: AppThemePalette.onPrimary(primaryBlue),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReferences,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Penghargaan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _titleController,
                            label: 'Judul',
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _titleBahasaController,
                            label: 'Judul Bahasa Indonesia',
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _givenByController,
                            label: 'Diberikan Oleh',
                          ),
                          const SizedBox(height: 14),
                          _buildDateField(),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Level',
                            value: _selectedLevel,
                            items: _levels,
                            onChanged: (value) {
                              setState(() => _selectedLevel = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Bidang',
                            value: _selectedField,
                            items: _fields,
                            onChanged: (value) {
                              setState(() => _selectedField = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSubmitting ? 'Menyimpan...' : 'Simpan Penghargaan',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: label.contains('Judul') ? 2 : 1,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Tanggal Penghargaan',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(Icons.calendar_today_rounded),
      ),
      onTap: _pickDate,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tanggal penghargaan wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<SkpiReferenceOption> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.key,
              child: Text(item.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selected) {
        if (selected == null || selected.isEmpty) {
          return '$label wajib dipilih';
        }
        return null;
      },
    );
  }
}

class _SkpiPdfPreviewPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const _SkpiPdfPreviewPage({required this.title, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}

class _SkpiImagePreviewPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const _SkpiImagePreviewPage({required this.title, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.memory(bytes),
        ),
      ),
    );
  }
}

class SkpiSummaryBadges extends StatelessWidget {
  final int organizationCount;
  final int languageCount;
  final int softskillCount;
  final int honorCount;
  final Color textColor;

  const SkpiSummaryBadges({
    super.key,
    required this.organizationCount,
    required this.languageCount,
    required this.softskillCount,
    required this.honorCount,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryBadge(
          icon: Icons.groups_rounded,
          value: '$organizationCount',
          textColor: textColor,
        ),
        _SummaryBadge(
          icon: Icons.translate_rounded,
          value: '$languageCount',
          textColor: textColor,
        ),
        _SummaryBadge(
          icon: Icons.workspace_premium_rounded,
          value: '$softskillCount',
          textColor: textColor,
        ),
        _SummaryBadge(
          icon: Icons.emoji_events_rounded,
          value: '$honorCount',
          textColor: textColor,
        ),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color textColor;

  const _SummaryBadge({
    required this.icon,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
