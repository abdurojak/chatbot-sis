import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/skpi_models.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:chatbot/services/skpi_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _uploadingEvidenceKey;
  List<SkpiOrganization> _organizations = const [];
  List<SkpiLanguage> _languages = const [];
  List<SkpiSoftskill> _softskills = const [];
  List<SkpiInternship> _internships = const [];
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
        _internships = pageData.internships;
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

  Future<void> _uploadEvidence({
    required String itemId,
    required String documentName,
    required String title,
  }) async {
    if (itemId.isEmpty) {
      return;
    }

    final selectedFile = await _pickEvidenceFile();
    if (selectedFile == null || !mounted) {
      return;
    }

    final uploadKey = '$documentName:$itemId';
    setState(() {
      _uploadingEvidenceKey = uploadKey;
    });

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await SkpiService.uploadEvidence(
        idLogin: idLogin,
        token: token,
        itemsId: itemId,
        documentName: documentName,
        mime: selectedFile.mime,
        base64Data: base64Encode(selectedFile.bytes),
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${result.message} untuk $title')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal upload evidence: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingEvidenceKey = null;
        });
      }
    }
  }

  Future<_SelectedSkpiEvidence?> _pickEvidenceFile() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded),
                title: const Text('Pilih File PDF'),
                onTap: () => Navigator.pop(sheetContext, 'pdf'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return null;
    }

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) {
        return null;
      }

      final bytes = await image.readAsBytes();
      return _SelectedSkpiEvidence(
        bytes: bytes,
        mime: _inferImageMime(image.path),
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.first;

    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      throw Exception('File PDF tidak dapat dibaca');
    }

    return _SelectedSkpiEvidence(bytes: bytes, mime: 'application/pdf');
  }

  String _inferImageMime(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
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

  Future<void> _openAddOrganizationForm() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AddOrganizationPage()),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openAddLanguageForm() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AddLanguagePage()),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openAddSoftskillForm() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AddSoftskillPage()),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openAddInternshipForm() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AddInternshipPage()),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openEditOrganizationForm(SkpiOrganization organization) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddOrganizationPage(organization: organization),
      ),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openEditLanguageForm(SkpiLanguage language) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _AddLanguagePage(language: language)),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openEditSoftskillForm(SkpiSoftskill softskill) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddSoftskillPage(softskill: softskill),
      ),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openEditInternshipForm(SkpiInternship internship) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddInternshipPage(internship: internship),
      ),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openEditHonorForm(SkpiHonor honor) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _AddHonorPage(honor: honor)),
    );

    if (message != null && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteHonor(SkpiHonor honor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Penghargaan'),
          content: Text(
            'Penghargaan "${honor.displayTitle}" akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await SkpiService.deleteHonor(
        idLogin: idLogin,
        token: token,
        idHonor: honor.id,
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus penghargaan: $e')),
      );
    }
  }

  Future<void> _deleteOrganization(SkpiOrganization organization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Organisasi'),
          content: Text(
            'Data organisasi "${organization.displayTitle}" akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await SkpiService.deleteOrganization(
        idLogin: idLogin,
        token: token,
        idOrganization: organization.id,
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus organisasi: $e')));
    }
  }

  Future<void> _deleteLanguage(SkpiLanguage language) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Bahasa'),
          content: Text(
            'Data bahasa "${language.languageName}" akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await SkpiService.deleteLanguage(
        idLogin: idLogin,
        token: token,
        idLanguage: language.id,
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus bahasa: $e')));
    }
  }

  Future<void> _deleteSoftskill(SkpiSoftskill softskill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Softskill'),
          content: Text(
            'Data softskill "${softskill.displayTitle}" akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await SkpiService.deleteSoftskill(
        idLogin: idLogin,
        token: token,
        idSoftskill: softskill.id,
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus softskill: $e')));
    }
  }

  Future<void> _deleteInternship(SkpiInternship internship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Magang'),
          content: Text(
            'Data magang "${internship.displayTitle}" akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;

      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await SkpiService.deleteInternship(
        idLogin: idLogin,
        token: token,
        idInternship: internship.id,
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus magang: $e')));
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
                action: FilledButton.icon(
                  onPressed: _openAddOrganizationForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
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
                action: FilledButton.icon(
                  onPressed: _openAddLanguageForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
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
                action: FilledButton.icon(
                  onPressed: _openAddSoftskillForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard<SkpiInternship>(
                title: 'Magang',
                subtitle: _internships.isEmpty
                    ? 'Belum ada data magang'
                    : '${_internships.length} pengalaman magang dan praktik kerja',
                icon: Icons.business_center_rounded,
                accentColor: const Color(0xFF7C4DFF),
                items: _internships,
                itemBuilder: _buildInternshipItem,
                action: FilledButton.icon(
                  onPressed: _openAddInternshipForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
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
            internshipCount: _internships.length,
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
          _buildEvidenceActions(
            idFile: item.evidenceFileId,
            itemId: item.id,
            title: item.displayTitle,
            documentName: 'Organisasi',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEditOrganizationButton(item),
              _buildDeleteOrganizationButton(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditOrganizationButton(SkpiOrganization item) {
    return TextButton.icon(
      onPressed: () => _openEditOrganizationForm(item),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit Organisasi'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFE66548),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDeleteOrganizationButton(SkpiOrganization item) {
    return TextButton.icon(
      onPressed: () => _deleteOrganization(item),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Hapus'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD14343),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          _buildEvidenceActions(
            idFile: item.evidenceFileId,
            itemId: item.id,
            title: item.languageName,
            documentName: 'Language',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEditLanguageButton(item),
              _buildDeleteLanguageButton(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditLanguageButton(SkpiLanguage item) {
    return TextButton.icon(
      onPressed: () => _openEditLanguageForm(item),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit Bahasa'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2F80ED),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDeleteLanguageButton(SkpiLanguage item) {
    return TextButton.icon(
      onPressed: () => _deleteLanguage(item),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Hapus'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD14343),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          _buildEvidenceActions(
            idFile: item.evidenceFileId,
            itemId: item.id,
            title: item.displayTitle,
            documentName: 'Softskill',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEditSoftskillButton(item),
              _buildDeleteSoftskillButton(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditSoftskillButton(SkpiSoftskill item) {
    return TextButton.icon(
      onPressed: () => _openEditSoftskillForm(item),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit Softskill'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF34A853),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDeleteSoftskillButton(SkpiSoftskill item) {
    return TextButton.icon(
      onPressed: () => _deleteSoftskill(item),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Hapus'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD14343),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildInternshipItem(SkpiInternship item, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3DAFF)),
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
                      item.displayPosition,
                      style: const TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(14),
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
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(item.periodLabel),
              if (item.positionEnglish != '-' &&
                  item.positionEnglish != item.position)
                _buildMetaChip(item.positionEnglish),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvidenceActions(
            idFile: item.evidenceFileId,
            itemId: item.id,
            title: item.displayTitle,
            documentName: 'Internship',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEditInternshipButton(item),
              _buildDeleteInternshipButton(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditInternshipButton(SkpiInternship item) {
    return TextButton.icon(
      onPressed: () => _openEditInternshipForm(item),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit Magang'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF7C4DFF),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDeleteInternshipButton(SkpiInternship item) {
    return TextButton.icon(
      onPressed: () => _deleteInternship(item),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Hapus'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD14343),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          _buildEvidenceActions(
            idFile: item.evidenceFileId,
            itemId: item.id,
            title: item.displayTitle,
            documentName: 'Honors',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEditHonorButton(item),
              _buildDeleteHonorButton(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditHonorButton(SkpiHonor item) {
    return TextButton.icon(
      onPressed: () => _openEditHonorForm(item),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit Penghargaan'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFC58B00),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDeleteHonorButton(SkpiHonor item) {
    return TextButton.icon(
      onPressed: () => _deleteHonor(item),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Hapus'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD14343),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEvidenceActions({
    required String idFile,
    required String itemId,
    required String title,
    required String documentName,
  }) {
    final isLoading = _loadingEvidenceId == idFile;
    final isUploading = _uploadingEvidenceKey == '$documentName:$itemId';

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (idFile.isNotEmpty)
            OutlinedButton.icon(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: isUploading
                ? null
                : () => _uploadEvidence(
                    itemId: itemId,
                    documentName: documentName,
                    title: title,
                  ),
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(isUploading ? 'Mengunggah...' : 'Upload Evidence'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F7AE0),
              side: const BorderSide(color: Color(0xFFBFD7FA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
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
  final SkpiHonor? honor;

  const _AddHonorPage({this.honor});

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

  bool get _isEditMode => widget.honor != null;

  @override
  void initState() {
    super.initState();
    _prefillHonor();
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

  void _prefillHonor() {
    final honor = widget.honor;
    if (honor == null) {
      return;
    }

    _titleController.text = honor.title;
    _titleBahasaController.text = honor.titleEnglish;
    _dateController.text = honor.honorDate == '-' ? '' : honor.honorDate;
    _givenByController.text = honor.givenBy == '-' ? '' : honor.givenBy;
  }

  String? _findReferenceKeyByValue(
    List<SkpiReferenceOption> items,
    String value,
  ) {
    final normalized = value.trim().toLowerCase();
    for (final item in items) {
      if (item.value.trim().toLowerCase() == normalized) {
        return item.key;
      }
    }
    return null;
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
      final honor = widget.honor;
      setState(() {
        _levels = data.levels;
        _fields = data.fields;
        _selectedLevel = honor == null
            ? (data.levels.isNotEmpty ? data.levels.first.key : null)
            : _findReferenceKeyByValue(data.levels, honor.level) ??
                  (data.levels.isNotEmpty ? data.levels.first.key : null);
        _selectedField = honor == null
            ? (data.fields.isNotEmpty ? data.fields.first.key : null)
            : _findReferenceKeyByValue(data.fields, honor.field) ??
                  (data.fields.isNotEmpty ? data.fields.first.key : null);
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referensi penghargaan belum lengkap')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = _isEditMode
          ? await SkpiService.updateHonor(
              idLogin: idLogin,
              token: token,
              idHonor: widget.honor!.id,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              dateOfHonor: _dateController.text.trim(),
              givenBy: _givenByController.text.trim(),
              level: _selectedLevel!,
              field: _selectedField!,
            )
          : await SkpiService.addHonor(
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
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Gagal memperbarui penghargaan: $e'
                : 'Gagal menambahkan penghargaan: $e',
          ),
        ),
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
        title: Text(_isEditMode ? 'Edit Penghargaan' : 'Tambah Penghargaan'),
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
                        _isSubmitting
                            ? 'Menyimpan...'
                            : _isEditMode
                            ? 'Update Penghargaan'
                            : 'Simpan Penghargaan',
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

class _AddOrganizationPage extends StatefulWidget {
  final SkpiOrganization? organization;

  const _AddOrganizationPage({this.organization});

  @override
  State<_AddOrganizationPage> createState() => _AddOrganizationPageState();
}

class _AddOrganizationPageState extends State<_AddOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleBahasaController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _selectedLevel;
  String? _selectedCategory;
  String? _selectedOccupacy;
  String? _selectedYearStart;
  String? _selectedYearStop;
  List<SkpiReferenceOption> _levels = const [];
  List<SkpiReferenceOption> _categories = const [];
  List<SkpiReferenceOption> _occupacies = const [];
  List<String> _years = const [];

  bool get _isEditMode => widget.organization != null;

  @override
  void initState() {
    super.initState();
    _prefillOrganization();
    _loadReferences();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleBahasaController.dispose();
    super.dispose();
  }

  void _prefillOrganization() {
    final organization = widget.organization;
    if (organization == null) return;
    _titleController.text = organization.title;
    _titleBahasaController.text = organization.titleEnglish;
  }

  String? _findReferenceKeyByValue(
    List<SkpiReferenceOption> items,
    String value,
  ) {
    final normalized = value.trim().toLowerCase();
    for (final item in items) {
      if (item.value.trim().toLowerCase() == normalized) {
        return item.key;
      }
    }
    return null;
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

      final data = await SkpiService.getOrganizationReferences(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;
      final organization = widget.organization;
      setState(() {
        _levels = data.levels;
        _categories = data.categories;
        _occupacies = data.occupacies;
        _years = data.years;
        _selectedLevel = organization == null
            ? (data.levels.isNotEmpty ? data.levels.first.key : null)
            : _findReferenceKeyByValue(data.levels, organization.level) ??
                  (data.levels.isNotEmpty ? data.levels.first.key : null);
        _selectedCategory = organization == null
            ? (data.categories.isNotEmpty ? data.categories.first.key : null)
            : _findReferenceKeyByValue(
                    data.categories,
                    organization.category,
                  ) ??
                  (data.categories.isNotEmpty
                      ? data.categories.first.key
                      : null);
        _selectedOccupacy = organization == null
            ? (data.occupacies.isNotEmpty ? data.occupacies.first.key : null)
            : _findReferenceKeyByValue(
                    data.occupacies,
                    organization.occupation,
                  ) ??
                  (data.occupacies.isNotEmpty
                      ? data.occupacies.first.key
                      : null);
        _selectedYearStart = organization == null
            ? (data.years.isNotEmpty ? data.years.last : null)
            : (data.years.contains(organization.yearStart)
                  ? organization.yearStart
                  : (data.years.isNotEmpty ? data.years.last : null));
        _selectedYearStop = organization == null
            ? (data.years.isNotEmpty ? data.years.last : null)
            : (data.years.contains(organization.yearStop)
                  ? organization.yearStop
                  : (data.years.isNotEmpty ? data.years.last : null));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat referensi organisasi.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    if (_selectedLevel == null ||
        _selectedCategory == null ||
        _selectedOccupacy == null ||
        _selectedYearStart == null ||
        _selectedYearStop == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referensi organisasi belum lengkap')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = _isEditMode
          ? await SkpiService.updateOrganization(
              idLogin: idLogin,
              token: token,
              idOrganization: widget.organization!.id,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              yearStart: _selectedYearStart!,
              yearStop: _selectedYearStop!,
              level: _selectedLevel!,
              category: _selectedCategory!,
              occupacy: _selectedOccupacy!,
            )
          : await SkpiService.addOrganization(
              idLogin: idLogin,
              token: token,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              yearStart: _selectedYearStart!,
              yearStop: _selectedYearStop!,
              level: _selectedLevel!,
              category: _selectedCategory!,
              occupacy: _selectedOccupacy!,
            );

      if (!mounted) return;
      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Gagal memperbarui organisasi: $e'
                : 'Gagal menambahkan organisasi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Organisasi' : 'Tambah Organisasi'),
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
                            'Data Organisasi',
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
                          _buildDropdown(
                            label: 'Tahun Mulai',
                            value: _selectedYearStart,
                            items: _years
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedYearStart = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Tahun Selesai',
                            value: _selectedYearStop,
                            items: _years
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedYearStop = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Level',
                            value: _selectedLevel,
                            items: _levels
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.key,
                                    child: Text(item.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedLevel = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Kategori',
                            value: _selectedCategory,
                            items: _categories
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.key,
                                    child: Text(item.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Jabatan',
                            value: _selectedOccupacy,
                            items: _occupacies
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.key,
                                    child: Text(item.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedOccupacy = value);
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
                        _isSubmitting
                            ? 'Menyimpan...'
                            : _isEditMode
                            ? 'Update Organisasi'
                            : 'Simpan Organisasi',
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
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
      items: items,
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

class _AddLanguagePage extends StatefulWidget {
  final SkpiLanguage? language;

  const _AddLanguagePage({this.language});

  @override
  State<_AddLanguagePage> createState() => _AddLanguagePageState();
}

class _AddLanguagePageState extends State<_AddLanguagePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _scoreController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _selectedLanguage;
  String? _selectedStandard;
  List<SkpiReferenceOption> _languages = const [];
  List<SkpiReferenceOption> _standards = const [];

  bool get _isEditMode => widget.language != null;

  @override
  void initState() {
    super.initState();
    _prefillLanguage();
    _loadReferences();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _prefillLanguage() {
    final language = widget.language;
    if (language == null) return;
    _dateController.text = language.takenDate == '-' ? '' : language.takenDate;
    _scoreController.text = language.score == '-' ? '' : language.score;
  }

  String? _findReferenceKeyByValue(
    List<SkpiReferenceOption> items,
    String value,
  ) {
    final normalized = value.trim().toLowerCase();
    for (final item in items) {
      if (item.value.trim().toLowerCase() == normalized) {
        return item.key;
      }
    }
    return null;
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

      final data = await SkpiService.getLanguageReferences(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;
      final language = widget.language;
      setState(() {
        _languages = data.languages;
        _standards = data.standards;
        _selectedLanguage = language == null
            ? (data.languages.isNotEmpty ? data.languages.first.key : null)
            : _findReferenceKeyByValue(data.languages, language.languageName) ??
                  (data.languages.isNotEmpty ? data.languages.first.key : null);
        _selectedStandard = language == null
            ? (data.standards.isNotEmpty ? data.standards.first.key : null)
            : _findReferenceKeyByValue(data.standards, language.standardName) ??
                  (data.standards.isNotEmpty ? data.standards.first.key : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat referensi bahasa.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

    if (_selectedLanguage == null || _selectedStandard == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referensi bahasa belum lengkap')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = _isEditMode
          ? await SkpiService.updateLanguage(
              idLogin: idLogin,
              token: token,
              idLanguage: widget.language!.id,
              languageId: _selectedLanguage!,
              languageStandard: _selectedStandard!,
              dateOfTaken: _dateController.text.trim(),
              score: _scoreController.text.trim(),
            )
          : await SkpiService.addLanguage(
              idLogin: idLogin,
              token: token,
              languageId: _selectedLanguage!,
              languageStandard: _selectedStandard!,
              dateOfTaken: _dateController.text.trim(),
              score: _scoreController.text.trim(),
            );

      if (!mounted) return;
      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Gagal memperbarui bahasa: $e'
                : 'Gagal menambahkan bahasa: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Bahasa' : 'Tambah Bahasa'),
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
                            'Data Bahasa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            label: 'Bahasa',
                            value: _selectedLanguage,
                            items: _languages
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.key,
                                    child: Text(item.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedLanguage = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Standar',
                            value: _selectedStandard,
                            items: _standards
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.key,
                                    child: Text(item.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedStandard = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildDateField(),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _scoreController,
                            label: 'Skor',
                            keyboardType: TextInputType.number,
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
                        _isSubmitting
                            ? 'Menyimpan...'
                            : _isEditMode
                            ? 'Update Bahasa'
                            : 'Simpan Bahasa',
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
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
        labelText: 'Tanggal Tes',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(Icons.calendar_today_rounded),
      ),
      onTap: _pickDate,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tanggal tes wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
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
      items: items,
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

class _AddSoftskillPage extends StatefulWidget {
  final SkpiSoftskill? softskill;

  const _AddSoftskillPage({this.softskill});

  @override
  State<_AddSoftskillPage> createState() => _AddSoftskillPageState();
}

class _AddSoftskillPageState extends State<_AddSoftskillPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleBahasaController = TextEditingController();
  final _dateStartController = TextEditingController();
  final _dateStopController = TextEditingController();
  final _hoursController = TextEditingController();
  final _givenByController = TextEditingController();

  bool _isSubmitting = false;

  bool get _isEditMode => widget.softskill != null;

  @override
  void initState() {
    super.initState();
    _prefillSoftskill();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleBahasaController.dispose();
    _dateStartController.dispose();
    _dateStopController.dispose();
    _hoursController.dispose();
    _givenByController.dispose();
    super.dispose();
  }

  void _prefillSoftskill() {
    final softskill = widget.softskill;
    if (softskill == null) return;
    _titleController.text = softskill.title;
    _titleBahasaController.text = softskill.titleEnglish;
    _dateStartController.text = softskill.dateStart == '-'
        ? ''
        : softskill.dateStart;
    _dateStopController.text = softskill.dateStop == '-'
        ? ''
        : softskill.dateStop;
    _hoursController.text = softskill.hours == '0' ? '' : softskill.hours;
    _givenByController.text = softskill.givenBy == '-' ? '' : softskill.givenBy;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null || !mounted) return;
    controller.text =
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

    setState(() => _isSubmitting = true);

    try {
      final result = _isEditMode
          ? await SkpiService.updateSoftskill(
              idLogin: idLogin,
              token: token,
              idSoftskill: widget.softskill!.id,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              dateStart: _dateStartController.text.trim(),
              dateStop: _dateStopController.text.trim(),
              hours: _hoursController.text.trim(),
              givenBy: _givenByController.text.trim(),
            )
          : await SkpiService.addSoftskill(
              idLogin: idLogin,
              token: token,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              dateStart: _dateStartController.text.trim(),
              dateStop: _dateStopController.text.trim(),
              hours: _hoursController.text.trim(),
              givenBy: _givenByController.text.trim(),
            );

      if (!mounted) return;
      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Gagal memperbarui softskill: $e'
                : 'Gagal menambahkan softskill: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Softskill' : 'Tambah Softskill'),
        backgroundColor: primaryBlue,
        foregroundColor: AppThemePalette.onPrimary(primaryBlue),
      ),
      body: SafeArea(
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
                      'Data Softskill',
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
                    _buildDateField(
                      controller: _dateStartController,
                      label: 'Tanggal Mulai',
                    ),
                    const SizedBox(height: 14),
                    _buildDateField(
                      controller: _dateStopController,
                      label: 'Tanggal Selesai',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _hoursController,
                      label: 'Jam',
                      keyboardType: TextInputType.number,
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
                  _isSubmitting
                      ? 'Menyimpan...'
                      : _isEditMode
                      ? 'Update Softskill'
                      : 'Simpan Softskill',
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.calendar_today_rounded),
      ),
      onTap: () => _pickDate(controller),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }
}

class _AddInternshipPage extends StatefulWidget {
  final SkpiInternship? internship;

  const _AddInternshipPage({this.internship});

  @override
  State<_AddInternshipPage> createState() => _AddInternshipPageState();
}

class _AddInternshipPageState extends State<_AddInternshipPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleBahasaController = TextEditingController();
  final _dateStartController = TextEditingController();
  final _dateStopController = TextEditingController();
  final _positionController = TextEditingController();
  final _positionEnglishController = TextEditingController();

  bool _isSubmitting = false;

  bool get _isEditMode => widget.internship != null;

  @override
  void initState() {
    super.initState();
    _prefillInternship();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleBahasaController.dispose();
    _dateStartController.dispose();
    _dateStopController.dispose();
    _positionController.dispose();
    _positionEnglishController.dispose();
    super.dispose();
  }

  void _prefillInternship() {
    final internship = widget.internship;
    if (internship == null) return;
    _titleController.text = internship.title;
    _titleBahasaController.text = internship.titleEnglish;
    _dateStartController.text = internship.dateStart == '-'
        ? ''
        : internship.dateStart;
    _dateStopController.text = internship.dateStop == '-'
        ? ''
        : internship.dateStop;
    _positionController.text = internship.position == '-'
        ? ''
        : internship.position;
    _positionEnglishController.text = internship.positionEnglish == '-'
        ? ''
        : internship.positionEnglish;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null || !mounted) return;
    controller.text =
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

    setState(() => _isSubmitting = true);

    try {
      final result = _isEditMode
          ? await SkpiService.updateInternship(
              idLogin: idLogin,
              token: token,
              idInternship: widget.internship!.id,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              dateStart: _dateStartController.text.trim(),
              dateStop: _dateStopController.text.trim(),
              position: _positionController.text.trim(),
              positionEnglish: _positionEnglishController.text.trim(),
            )
          : await SkpiService.addInternship(
              idLogin: idLogin,
              token: token,
              title: _titleController.text.trim(),
              titleBahasa: _titleBahasaController.text.trim(),
              dateStart: _dateStartController.text.trim(),
              dateStop: _dateStopController.text.trim(),
              position: _positionController.text.trim(),
              positionEnglish: _positionEnglishController.text.trim(),
            );

      if (!mounted) return;
      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Gagal memperbarui magang: $e'
                : 'Gagal menambahkan magang: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Magang' : 'Tambah Magang'),
        backgroundColor: primaryBlue,
        foregroundColor: AppThemePalette.onPrimary(primaryBlue),
      ),
      body: SafeArea(
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
                      'Data Magang',
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
                      controller: _positionController,
                      label: 'Posisi',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _positionEnglishController,
                      label: 'Posisi Bahasa Inggris',
                    ),
                    const SizedBox(height: 14),
                    _buildDateField(
                      controller: _dateStartController,
                      label: 'Tanggal Mulai',
                    ),
                    const SizedBox(height: 14),
                    _buildDateField(
                      controller: _dateStopController,
                      label: 'Tanggal Selesai',
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
                  _isSubmitting
                      ? 'Menyimpan...'
                      : _isEditMode
                      ? 'Update Magang'
                      : 'Simpan Magang',
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

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.calendar_today_rounded),
      ),
      onTap: () => _pickDate(controller),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }
}

class _SelectedSkpiEvidence {
  final Uint8List bytes;
  final String mime;

  const _SelectedSkpiEvidence({required this.bytes, required this.mime});
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
  final int internshipCount;
  final int honorCount;
  final Color textColor;

  const SkpiSummaryBadges({
    super.key,
    required this.organizationCount,
    required this.languageCount,
    required this.softskillCount,
    required this.internshipCount,
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
          icon: Icons.business_center_rounded,
          value: '$internshipCount',
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
