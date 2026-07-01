import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/mbkm_exchange_screen.dart';
import 'package:chatbot/mbkm_outbound_screen.dart';
import 'package:flutter/material.dart';

class MbkmMenuPage extends StatelessWidget {
  const MbkmMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MBKM'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlue.withAlpha(235),
                  AppThemePalette.dark(0.12),
                ],
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Menu MBKM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Merdeka Belajar-Kampus Merdeka.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MenuCard(
            title: 'MBKM Outbound',
            subtitle:
                'Melihat transaksi, log, kompetensi, dan pengajuan MBKM outbound non PT.',
            icon: Icons.language_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MbkmOutboundPage()),
              );
            },
          ),
          const SizedBox(height: 14),
          _MenuCard(
            title: 'MBKM Pertukaran Mahasiswa',
            subtitle:
                'Halaman placeholder untuk alur pertukaran mahasiswa. Nanti bisa kita lengkapi bertahap.',
            icon: Icons.swap_horiz_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MbkmExchangePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppThemePalette.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primaryBlue.withAlpha(32)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
