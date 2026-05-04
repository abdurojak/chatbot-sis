import 'package:chatbot/component/krs_requirement_buble.dart';
import 'package:chatbot/convocation_screen.dart';
import 'package:chatbot/fill_krs.dart';
import 'package:chatbot/get_invoice.dart';
import 'package:chatbot/kpu_screen.dart';
import 'package:chatbot/login_screen.dart';
import 'package:chatbot/mbkm_exchange_screen.dart';
import 'package:chatbot/mbkm_outbound_screen.dart';
import 'package:chatbot/result_khs.dart';
import 'package:chatbot/result_krs.dart';
import 'package:chatbot/result_skpi.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class BotActionHandle {
  static Future<bool> handle(
    BuildContext context, {
    required String payload,
    required Function(String) sendMessage,
    required Function(List<Widget>) addBotWidgets,
  }) async {
    final session = await SessionService.loadSession();
    final token = session?.token;
    final idLogin = session?.idLogin;

    Future<bool> requireLogin() async {
      if (token != null && idLogin != null) {
        return true;
      }

      if (!context.mounted) {
        return false;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return false;
    }

    switch (payload) {
      case 'Transaksi KRS':
        if (!await requireLogin()) {
          return true;
        }

        final currentToken = token!;
        final currentIdLogin = idLogin!;

        try {
          final response = await KrsService.getRequirements(
            idLogin: currentIdLogin,
            token: currentToken,
          );

          if (!context.mounted) return true;

          addBotWidgets([
            _botBubble('Berikut status persyaratan KRS kamu:'),
            const SizedBox(height: 12),
            KrsRequirementBubble(items: response.requirements),
          ]);

          final allPassed = response.requirements.every(
            (item) => item.status == 1,
          );

          if (allPassed) {
            addBotWidgets([
              _botBubble('Semua persyaratan terpenuhi.'),
              const SizedBox(height: 12),
              _botBubble('Mengalihkan ke halaman pengisian KRS...'),
            ]);

            await Future.delayed(const Duration(seconds: 1));

            if (!context.mounted) return true;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PengisianKrsPage(idSemester: response.idSemester),
              ),
            );
          } else {
            addBotWidgets([
              _botBubble('Masih ada persyaratan yang belum terpenuhi.'),
              const SizedBox(height: 12),
              _botBubble('Silakan lengkapi dulu sebelum isi KRS.'),
            ]);
          }
        } catch (_) {
          addBotWidgets([_botBubble('Gagal mengambil data persyaratan KRS.')]);
        }

        return true;

      case 'Hasil KRS':
        if (!await requireLogin()) {
          return true;
        }
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilKrsPage()),
        );
        return true;

      case 'Hasil KHS':
        if (!await requireLogin()) {
          return true;
        }
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilKhsPage()),
        );
        return true;

      case 'Hasil SKPI':
        if (!await requireLogin()) {
          return true;
        }

        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilSkpiPage()),
        );
        return true;

      case 'Hasil Kartu Peserta Ujian':
        if (!await requireLogin()) {
          return true;
        }
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamSlipPage()),
        );
        return true;

      case 'Transaksi MB Outbound Non PT':
      case 'Hasil MB Outbound Non PT':
        if (!await requireLogin()) {
          return true;
        }
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MbkmOutboundPage()),
        );
        return true;

      case 'Hasil Pertukaran Mahasiswa':
        if (!await requireLogin()) {
          return true;
        }
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MbkmExchangePage()),
        );
        return true;

      case 'Transaksi Pembayaran':
        if (!await requireLogin()) {
          return true;
        }
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvoicePage()),
        );
        return true;

      case 'Transaksi Wisuda':
        if (!await requireLogin()) {
          return true;
        }

        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConvocationPage()),
        );
        return true;

      default:
        return false;
    }
  }

  static Widget _botBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text),
      ),
    );
  }
}
