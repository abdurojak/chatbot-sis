import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/mbkm_apply_screen.dart';
import 'package:chatbot/mbkm_log_screen.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/mbkm_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MbkmPage extends StatefulWidget {
  const MbkmPage({super.key});

  @override
  State<MbkmPage> createState() => _MbkmPageState();
}

class _MbkmPageState extends State<MbkmPage> {
  bool _isLoading = true;
  String? _error;
  MbkmResponseData? _data;

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadMbkm();
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
      backgroundColor: Colors.white,
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
                            color: Colors.grey.shade300,
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
                        style: const TextStyle(color: Colors.grey),
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
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final applications = _data?.applications ?? const <MbkmApplication>[];
    final biodata = _data?.biodata;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi MBKM'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadMbkm,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (biodata != null) _buildBiodataCard(biodata),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final submitted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MbkmApplyPage(),
                          ),
                        );

                        if (submitted == true) {
                          await _loadMbkm();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajukan MBKM'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Daftar Pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (applications.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Belum ada data MBKM'),
                      ),
                    )
                  else
                    ...applications.map(_buildApplicationCard),
                ],
              ),
            ),
    );
  }

  Widget _buildBiodataCard(MbkmBiodata biodata) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(70)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biodata Mahasiswa',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 12),
          _infoRow('Nama', biodata.name),
          _infoRow('NIM', biodata.nim),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(MbkmApplication item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryBlue.withAlpha(38)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryBlue.withAlpha(235), AppThemePalette.dark(0.1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(item.activityType, filled: true),
                    _chip(item.scaleName, filled: true),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.companyName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: AppThemePalette.soft(0.95),
              border: Border(
                bottom: BorderSide(color: primaryBlue.withAlpha(25)),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard('Semester', item.semesterName),
                _statCard('Periode', '${item.startDate} - ${item.endDate}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Mentor Internal', item.internalMentorName),
                      _infoRow('Seleksi', item.selectionDate),
                      _infoRow('Hasil Seleksi', item.resultDate),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                if (item.competencies.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
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
                  const SizedBox(height: 10),
                  ...item.competencies.map(_buildCompetencyCard),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MbkmLogPage(
                              idMa: item.idApplication,
                              title: item.title,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('Lihat Log'),
                    ),
                    if (item.hasMoreInfo)
                      TextButton.icon(
                        onPressed: () => _openLink(item.moreInfoUrl),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Buka Info'),
                      ),
                  ],
                ),
              ],
            ),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _chip(String text, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.white.withAlpha(28) : primaryBlue.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled ? Colors.white24 : primaryBlue.withAlpha(38),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
}
