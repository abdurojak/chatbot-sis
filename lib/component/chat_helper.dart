import 'dart:convert';

import 'package:chatbot/component/krs_requirement_buble.dart';
import 'package:chatbot/fill_krs.dart';
import 'package:chatbot/get_invoice.dart';
import 'package:chatbot/kpu_screen.dart';
import 'package:chatbot/login_screen.dart';
import 'package:chatbot/result_khs.dart';
import 'package:chatbot/result_krs.dart';
import 'package:chatbot/services/krs_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

    switch (payload) {
      case 'Transaksi KRS':
        if (token == null || idLogin == null) {
          if (!context.mounted) return true;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return true;
        }

        try {
          final response = await KrsService.getRequirements(
            idLogin: idLogin,
            token: token,
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
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilKrsPage()),
        );
        return true;

      case 'Hasil KHS':
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilKhsPage()),
        );
        return true;

      case 'Hasil Kartu Peserta Ujian':
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamSlipPage()),
        );
        return true;

      case 'Transaksi Pembayaran':
        if (!context.mounted) return true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvoicePage()),
        );
        return true;

      case 'Hasil Nilai':
        if (token == null || idLogin == null) {
          if (!context.mounted) return true;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return true;
        }

        try {
          final res = await http.post(
            Uri.parse('https://sismob.trisakti.ac.id/api/get-transkrip'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'IdLogin': idLogin, 'token': token}),
          );

          final json = jsonDecode(res.body);
          final fileUrl = json['body']?['data']?['file_path']?.toString() ?? '';

          if (fileUrl.isEmpty) {
            addBotWidgets([_botBubble('File transkrip tidak ditemukan.')]);
            return true;
          }

          addBotWidgets([_botBubble('Membuka hasil nilai kamu...')]);

          final uri = Uri.parse(fileUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            addBotWidgets([_botBubble('Gagal membuka file PDF.')]);
          }
        } catch (_) {
          addBotWidgets([_botBubble('Gagal mengambil data transkrip.')]);
        }

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
