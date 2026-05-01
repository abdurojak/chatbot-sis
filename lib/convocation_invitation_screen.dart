import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/convocation_models.dart';
import 'package:chatbot/services/convocation_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConvocationInvitationPage extends StatefulWidget {
  const ConvocationInvitationPage({super.key});

  @override
  State<ConvocationInvitationPage> createState() =>
      _ConvocationInvitationPageState();
}

class _ConvocationInvitationPageState extends State<ConvocationInvitationPage> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  String _idLogin = '';
  List<ConvocationInvitationCard> _cards = const [];

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _generateInvitation() async {
    if (_idLogin.isEmpty || _isGenerating) return;

    setState(() => _isGenerating = true);
    try {
      await ConvocationService.generateInvitationCard(idLogin: _idLogin);
      await _loadCards();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undangan berhasil digenerate')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal generate undangan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final cards = await ConvocationService.getInvitationCards(
        idLogin: session.idLogin,
        token: session.token,
      );

      if (!mounted) return;
      setState(() {
        _idLogin = session.idLogin;
        _cards = cards;
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !mounted) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (opened || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka tautan')));
  }

  String _toPublicSisUrl(String rawPath) {
    final path = rawPath.trim();
    if (path.isEmpty) return '';

    const sisHost = 'https://sis.trisakti.ac.id';
    const sisStoragePrefix = '/var/www/html/sis';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith(sisStoragePrefix)) {
      return '$sisHost${path.replaceFirst(sisStoragePrefix, '')}';
    }
    if (path.startsWith('/')) {
      return '$sisHost$path';
    }
    return '$sisHost/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Undangan Wisuda'),
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
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadCards,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCards,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  ..._cards.map(_buildCard),
                  if (_cards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryBlue.withAlpha(40)),
                      ),
                      child: const Text('Belum ada data undangan.'),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Undangan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gunakan tombol di bawah untuk generate/cetak undangan PDF dari server.',
            style: TextStyle(height: 1.4, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _idLogin.isEmpty || _isGenerating
                  ? null
                  : _generateInvitation,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _isGenerating
                    ? 'Generating Undangan...'
                    : 'Generate / Refresh Undangan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ConvocationInvitationCard card) {
    final pdfUrl = _toPublicSisUrl(card.invitationCardPath);
    final photoUrl = _toPublicSisUrl(card.photoPath);
    final qrUrl = _toPublicSisUrl(card.qrPath);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Undangan #${card.invitationId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: card.isAttended
                      ? Colors.green.withAlpha(24)
                      : Colors.orange.withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  card.attendanceLabel,
                  style: TextStyle(
                    color: card.isAttended
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Dibuat: ${card.createdAt.isEmpty ? '-' : card.createdAt}'),
          Text('Hadir: ${card.attendanceAt.isEmpty ? '-' : card.attendanceAt}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: pdfUrl.isEmpty ? null : () => _openUrl(pdfUrl),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Lihat PDF'),
              ),
              OutlinedButton.icon(
                onPressed: photoUrl.isEmpty ? null : () => _openUrl(photoUrl),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Lihat Foto'),
              ),
              OutlinedButton.icon(
                onPressed: qrUrl.isEmpty ? null : () => _openUrl(qrUrl),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Lihat QR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
