import 'package:flutter/material.dart';

class PengisianKrsPage extends StatelessWidget {
  const PengisianKrsPage({super.key});

  static const Color primaryBlue = Color(0xFF1E73BE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengisian KRS'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICON WARNING
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 56,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 24),

            // TITLE
            const Text(
              '⚠️ Pengisian KRS belum bisa dilakukan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            // DESCRIPTION
            const Text(
              'Pengisian KRS belum tersedia karena pengajuan pengisian KRS '
              'belum diajukan atau masih menunggu persetujuan dari '
              'Dosen Pembimbing Akademik.\n\n'
              'Silakan ajukan pengisian KRS terlebih dahulu dan pastikan '
              'status approval sudah disetujui sebelum melanjutkan '
              'pengisian KRS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 32),

            // BUTTON KEMBALI
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
