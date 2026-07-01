import 'dart:typed_data';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:chatbot/services/transcript_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class TranscriptPage extends StatefulWidget {
  const TranscriptPage({super.key});

  @override
  State<TranscriptPage> createState() => _TranscriptPageState();
}

class _TranscriptPageState extends State<TranscriptPage> {
  bool _isLoading = true;
  String? _error;
  String? _filePath;
  Future<Uint8List>? _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    _loadTranscript();
  }

  Future<void> _loadTranscript() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _filePath = null;
      _pdfBytesFuture = null;
    });

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;
      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final transcript = await TranscriptService.getTranscript(
        idLogin: idLogin,
        token: token,
      );
      if (transcript.filePath.isEmpty) {
        throw Exception('File transkrip belum tersedia.');
      }

      if (!mounted) return;
      setState(() {
        _filePath = transcript.filePath;
        _pdfBytesFuture = TranscriptService.downloadTranscriptBytes(
          transcript.filePath,
        );
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

  Future<void> _openPdf() async {
    final filePath = _filePath;
    if (filePath == null || filePath.isEmpty) return;

    final uri = Uri.parse(filePath);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka PDF transkrip.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Transkrip Nilai'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : _loadTranscript,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _filePath == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: _openPdf,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Unduh PDF'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _messageState(
        icon: Icons.error_outline_rounded,
        title: 'Gagal memuat transkrip',
        message: _error!,
      );
    }

    final pdfBytesFuture = _pdfBytesFuture;
    if (pdfBytesFuture == null) {
      return _messageState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Transkrip belum tersedia',
        message: 'File transkrip tidak ditemukan.',
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppThemePalette.surface,
          child: Text(
            'Transaksi Transkrip / Hasil Transkrip',
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: PdfPreview(
            build: (_) => pdfBytesFuture,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            pdfFileName: 'transkrip_nilai.pdf',
            loadingWidget: const Center(child: CircularProgressIndicator()),
            onError: (context, error) => _messageState(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Preview PDF tidak tersedia',
              message: 'Gunakan tombol Unduh PDF untuk membuka file transkrip.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppThemePalette.textTertiary, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppThemePalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
