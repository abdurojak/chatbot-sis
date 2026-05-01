import 'dart:convert';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/convocation_application_screen.dart';
import 'package:chatbot/convocation_invitation_screen.dart';
import 'package:chatbot/models/convocation_models.dart';
import 'package:chatbot/services/convocation_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ConvocationPage extends StatefulWidget {
  const ConvocationPage({super.key});

  @override
  State<ConvocationPage> createState() => _ConvocationPageState();
}

class _ConvocationPageState extends State<ConvocationPage> {
  bool _isLoading = true;
  String? _error;
  ConvocationData? _data;
  final ImagePicker _imagePicker = ImagePicker();

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadConvocation();
  }

  Future<void> _loadConvocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final data = await ConvocationService.getConvocation(
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

  Future<void> _showCompanionUploadSheet(ConvocationData data) async {
    final session = await SessionService.loadSession();
    if (session == null || !mounted) return;

    var convoid = data.companionConvoId;
    var invitationId = data.companionInvitationId;

    if (convoid.isEmpty || invitationId.isEmpty) {
      try {
        final cards = await ConvocationService.getInvitationCards(
          idLogin: session.idLogin,
          token: session.token,
        );
        if (cards.isNotEmpty) {
          convoid = cards.first.convoId;
          invitationId = cards.first.invitationApiId;
        }
      } catch (_) {
        // Ignore and let validation below show a clear message.
      }
    }

    if ((convoid.isEmpty || invitationId.isEmpty) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data undangan belum tersedia. Silakan buat/lihat undangan dulu.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        XFile? selectedFile;
        bool isUploading = false;
        String sourceLabel = '';

        Future<void> pickFile(
          ImageSource source,
          StateSetter setModalState,
        ) async {
          final picked = await _imagePicker.pickImage(
            source: source,
            imageQuality: 90,
          );
          if (picked == null || !sheetContext.mounted) return;
          setModalState(() {
            selectedFile = picked;
            sourceLabel = source == ImageSource.camera ? 'Kamera' : 'Galeri';
          });
        }

        Future<void> submit(StateSetter setModalState) async {
          if (selectedFile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pilih foto pendamping terlebih dahulu'),
              ),
            );
            return;
          }

          setModalState(() => isUploading = true);
          try {
            final bytes = await selectedFile!.readAsBytes();
            final mime = _inferImageMime(selectedFile!.name);
            final message = await ConvocationService.uploadCompanion(
              idLogin: session.idLogin,
              token: session.token,
              convoid: convoid,
              invitationId: invitationId,
              mime: mime,
              base64Data: base64Encode(bytes),
            );

            if (!mounted || !sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            await _loadConvocation();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal unggah pendamping: $e')),
            );
          } finally {
            if (sheetContext.mounted) {
              setModalState(() => isUploading = false);
            }
          }
        }

        return StatefulBuilder(
          builder: (_, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unggah Pendamping (Opsional)',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Langkah ini bisa dilewati. Jika ingin unggah, pilih foto dari kamera atau galeri.',
                      style: TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () => pickFile(
                                    ImageSource.camera,
                                    setModalState,
                                  ),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kamera'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () => pickFile(
                                    ImageSource.gallery,
                                    setModalState,
                                  ),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeri'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppThemePalette.soft(0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryBlue.withAlpha(35)),
                      ),
                      child: Text(
                        selectedFile == null
                            ? 'Belum ada file dipilih'
                            : '$sourceLabel • ${selectedFile!.name}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isUploading
                            ? null
                            : () => submit(setModalState),
                        icon: isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_rounded),
                        label: Text(
                          isUploading ? 'Mengunggah...' : 'Upload Pendamping',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _inferImageMime(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final steps = data?.buildSteps() ?? const <ConvocationStep>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Wisuda'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
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
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadConvocation,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadConvocation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(data),
                  const SizedBox(height: 18),
                  Text(
                    'Alur Wisuda',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...steps.map((step) => _buildStepCard(step, data)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(ConvocationData? data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue.withAlpha(240), AppThemePalette.dark(0.1)],
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
            'Proses Wisuda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pantau tahapan wisuda Anda dari yudisium sampai undangan.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(ConvocationStep step, ConvocationData? data) {
    final accent = switch (step.state) {
      ConvocationStepState.done => Colors.green.shade600,
      ConvocationStepState.current => primaryBlue,
      ConvocationStepState.locked => const Color(0xFF6B7280),
    };

    final icon = switch (step.state) {
      ConvocationStepState.done => Icons.check_rounded,
      ConvocationStepState.current => Icons.play_arrow_rounded,
      ConvocationStepState.locked => Icons.lock_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(22),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withAlpha(80)),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                Container(
                  width: 2,
                  height: 86,
                  margin: const EdgeInsets.only(top: 8),
                  color: step.order == 5
                      ? Colors.transparent
                      : accent.withAlpha(55),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withAlpha(50)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Langkah ${step.order}',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.statusText,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                  if (step.title == 'Aplikasi' && data?.canApply == true) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        final submitted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConvocationApplicationPage(
                              convocationData: data,
                            ),
                          ),
                        );

                        if (submitted == true) {
                          await _loadConvocation();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Isi Aplikasi'),
                    ),
                  ],
                  if (step.title == 'Unggah Pendamping' &&
                      data?.canCreateInvitation == true) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _showCompanionUploadSheet(data!),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload Pendamping'),
                    ),
                  ],
                  if (step.title == 'Buat Undangan' &&
                      data?.canCreateInvitation == true) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConvocationInvitationPage(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text('Lihat Undangan'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
