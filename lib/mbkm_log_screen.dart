import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/mbkm_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

class MbkmLogPage extends StatefulWidget {
  final String idMa;
  final String title;

  const MbkmLogPage({super.key, required this.idMa, required this.title});

  @override
  State<MbkmLogPage> createState() => _MbkmLogPageState();
}

class _MbkmLogPageState extends State<MbkmLogPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final Set<String> _expandedLogIds = <String>{};

  bool _isLoading = true;
  String? _error;
  List<MbkmLogEntry> _logs = const [];

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final result = await MbkmService.getMbkmLog(
        idLogin: session.idLogin,
        token: session.token,
        idMa: widget.idMa,
      );

      if (!mounted) return;
      setState(() => _logs = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null || !mounted) {
      return;
    }

    controller.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showLogForm({MbkmLogEntry? entry}) async {
    final formKey = GlobalKey<FormState>();
    final startController = TextEditingController(text: entry?.startDate ?? '');
    final endController = TextEditingController(text: entry?.endDate ?? '');
    final activityController = TextEditingController(
      text: entry?.activity ?? '',
    );
    final evaluationController = TextEditingController(
      text: entry?.evaluation ?? '',
    );
    final actionController = TextEditingController(text: entry?.action ?? '');
    final mentorController = TextEditingController(
      text: entry?.mentorRemark == '-' ? '' : entry?.mentorRemark ?? '',
    );
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
                final message = await MbkmService.saveMbkmLog(
                  idLogin: session.idLogin,
                  token: session.token,
                  startDate: startController.text.trim(),
                  endDate: endController.text.trim(),
                  activity: activityController.text.trim(),
                  evaluation: evaluationController.text.trim(),
                  action: actionController.text.trim(),
                  mentorRemark: mentorController.text.trim(),
                  idMa: widget.idMa,
                  idLog: entry?.idLog.isNotEmpty == true ? entry!.idLog : null,
                );

                if (!mounted || !sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(message)));
                await _loadLog();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan log: $e')),
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
                        entry == null ? 'Tambah Log MBKM' : 'Ubah Log MBKM',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        context: sheetContext,
                        controller: startController,
                        label: 'Tanggal Mulai',
                      ),
                      const SizedBox(height: 12),
                      _buildDateField(
                        context: sheetContext,
                        controller: endController,
                        label: 'Tanggal Selesai',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: activityController,
                        label: 'Aktivitas',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: evaluationController,
                        label: 'Evaluasi',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: actionController,
                        label: 'Tindakan',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: mentorController,
                        label: 'Remark Mentor',
                        maxLines: 2,
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
                              : const Text('Simpan Log'),
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

  void _toggleLog(String idLog) {
    setState(() {
      if (_expandedLogIds.contains(idLog)) {
        _expandedLogIds.remove(idLog);
      } else {
        _expandedLogIds.add(idLog);
      }
    });
  }

  Future<void> _showEvidenceList(MbkmLogEntry entry) async {
    if (entry.evidences.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada bukti untuk log ini')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                  'Preview Bukti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.startDate} - ${entry.endDate}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entry.evidences.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final evidence = entry.evidences[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppThemePalette.soft(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryBlue.withAlpha(24)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.attach_file_rounded,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evidence.fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    evidence.remark,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID File: ${evidence.idFile}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _previewEvidence(evidence);
                              },
                              child: const Text('Buka'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _previewEvidence(MbkmLogEvidence evidence) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final fetched = await MbkmService.getFileEvidence(
        idLogin: session.idLogin,
        token: session.token,
        idFile: evidence.idFile,
      );

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (fetched.isPdf) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _MbkmPdfPreviewPage(
              title: fetched.fileName,
              bytes: fetched.bytes,
            ),
          ),
        );
        return;
      }

      if (fetched.isImage) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _MbkmImagePreviewPage(
              title: fetched.fileName,
              bytes: fetched.bytes,
            ),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'File bukti berhasil diambil, tetapi preview hanya mendukung PDF atau gambar',
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuka bukti: $e')),
      );
    }
  }

  Future<void> _showUploadEvidenceModal(MbkmLogEntry entry) async {
    final remarkController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    _EvidenceUploadSelection? selectedFile;
    bool isSubmitting = false;

    Future<void> pickCamera(StateSetter setModalState) async {
      final result = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (result == null) return;
      final bytes = await result.readAsBytes();
      setModalState(() {
        selectedFile = _EvidenceUploadSelection(
          fileName: result.name,
          mime: _inferImageMime(result.name),
          base64Data: base64Encode(bytes),
          bytes: bytes,
          sourceLabel: 'Kamera',
        );
      });
    }

    Future<void> pickGallery(StateSetter setModalState) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      final picked = result?.files.single;
      if (picked == null) return;
      final bytes =
          picked.bytes ??
          (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) return;

      setModalState(() {
        selectedFile = _EvidenceUploadSelection(
          fileName: picked.name,
          mime: _inferImageMime(picked.name),
          base64Data: base64Encode(bytes),
          bytes: bytes,
          sourceLabel: 'Galeri',
        );
      });
    }

    Future<void> pickPdf(StateSetter setModalState) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );

      final picked = result?.files.single;
      if (picked == null) return;
      final bytes =
          picked.bytes ??
          (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) return;

      setModalState(() {
        selectedFile = _EvidenceUploadSelection(
          fileName: picked.name,
          mime: 'application/pdf',
          base64Data: base64Encode(bytes),
          bytes: bytes,
          sourceLabel: 'PDF',
        );
      });
    }

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
              if (selectedFile == null) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Pilih file bukti terlebih dahulu'),
                  ),
                );
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
                final message = await MbkmService.uploadLogEvidence(
                  idLogin: session.idLogin,
                  token: session.token,
                  idLog: entry.idLog,
                  remark: remarkController.text.trim(),
                  mime: selectedFile!.mime,
                  base64Data: selectedFile!.base64Data,
                );

                if (!mounted || !sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(message)));
                await _loadLog();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Gagal mengunggah bukti: $e')),
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
                        'Upload Bukti',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${entry.startDate} - ${entry.endDate}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => pickCamera(setModalState),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kamera'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => pickGallery(setModalState),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Galeri'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => pickPdf(setModalState),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppThemePalette.soft(0.96),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryBlue.withAlpha(20)),
                        ),
                        child: selectedFile == null
                            ? const Text(
                                'Pilih bukti berupa gambar atau PDF. Untuk gambar, Anda juga bisa langsung memakai kamera.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFile!.fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedFile!.sourceLabel} • ${selectedFile!.mime}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  if (selectedFile!.isImage) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        selectedFile!.bytes,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: remarkController,
                        label: 'Remark Bukti',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),
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
                              : const Text('Upload Bukti'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log MBKM'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogForm(),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadLog,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 18),
                  if (_logs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Belum ada log MBKM'),
                      ),
                    )
                  else
                    ..._logs.map(_buildLogCard),
                ],
              ),
            ),
    );
  }

  Widget _buildLogCard(MbkmLogEntry item) {
    final isExpanded = _expandedLogIds.contains(item.idLog);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryBlue.withAlpha(34)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _toggleLog(item.idLog),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue.withAlpha(235),
                      AppThemePalette.dark(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(22),
                    bottom: Radius.circular(isExpanded ? 0 : 22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode Log',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: Colors.white.withAlpha(205),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.startDate} - ${item.endDate}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.activity,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withAlpha(235),
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        OutlinedButton(
                          onPressed: () => _showLogForm(entry: item),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            backgroundColor: Colors.white.withAlpha(18),
                            minimumSize: const Size(42, 38),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.edit, size: 18),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                      children: [
                        _infoRow('Evaluasi', item.evaluation),
                        _infoRow('Tindakan', item.action),
                        _infoRow('Remark Mentor', item.mentorRemark),
                        _infoRow('Tanggal Input', item.entryDate),
                        _infoRow('Approval', item.approvalStatus),
                        _infoRow('Bukti', '${item.evidenceCount} file'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: item.evidences.isEmpty
                            ? null
                            : () => _showEvidenceList(item),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Preview Bukti'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showUploadEvidenceModal(item),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Upload Bukti'),
                      ),
                    ],
                  ),
                ],
              ),
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

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryBlue.withAlpha(42)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryBlue.withAlpha(28)),
            ),
            child: Text(
              'Log Aktivitas MBKM',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppThemePalette.dark(0.18),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _logs.isEmpty
                ? 'Belum ada log yang tercatat untuk program ini.'
                : '${_logs.length} log tercatat untuk program ini.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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

  Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () => _pickDate(context, controller),
    );
  }

  String _inferImageMime(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class _EvidenceUploadSelection {
  final String fileName;
  final String mime;
  final String base64Data;
  final Uint8List bytes;
  final String sourceLabel;

  const _EvidenceUploadSelection({
    required this.fileName,
    required this.mime,
    required this.base64Data,
    required this.bytes,
    required this.sourceLabel,
  });

  bool get isImage => mime.startsWith('image/');
}

class _MbkmPdfPreviewPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const _MbkmPdfPreviewPage({required this.title, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(build: (_) async => bytes),
    );
  }
}

class _MbkmImagePreviewPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const _MbkmImagePreviewPage({required this.title, required this.bytes});

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
