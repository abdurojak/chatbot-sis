import 'dart:convert';

import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/krs_requirement_buble.dart';
import 'package:chatbot/fill_krs.dart';
import 'package:chatbot/login_screen.dart';
import 'package:chatbot/result_khs.dart';
import 'package:chatbot/result_krs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BotActionHandle {
  static Future<bool> handle(
    BuildContext context, {
    required String payload,
    required Function(String) sendMessage,
    required Function(List<Widget>) addBotWidgets,
  }) async {
    final token = await AuthStorage.getToken();
    final idLogin = await AuthStorage.getIdLogin();
    switch (payload) {
      case 'Transaksi KRS':
        if (token == null || idLogin == null) {
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

          final data = response.requirements;
          final idSemester = response.idSemester;

          debugPrint("Requirement KRS : $data");
          debugPrint("ID Semester : $idSemester");

          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const PengisianKrsPage()),
          // );

          addBotWidgets([
            _botBubble("Berikut status persyaratan KRS kamu:"),
            const SizedBox(height: 12),
            KrsRequirementBubble(items: data),
          ]);

          final allPassed = data.every((e) => e.status == 1);

          if (allPassed) {
            addBotWidgets([
              _botBubble("Semua persyaratan terpenuhi ✅"),
              const SizedBox(height: 12),
              _botBubble("Mengalihkan ke halaman pengisian KRS... 🚀"),
            ]);

            await Future.delayed(const Duration(seconds: 1));

            if (!context.mounted) return true;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PengisianKrsPage(idSemester: idSemester),
              ),
            );
          } else {
            addBotWidgets([
              _botBubble("Masih ada persyaratan yang belum terpenuhi ❌"),
              const SizedBox(height: 12),
              _botBubble("Silakan lengkapi dulu ya sebelum isi KRS 🙏"),
            ]);
          }
        } catch (e) {
          addBotWidgets([
            _botBubble("Gagal mengambil data persyaratan KRS 😢"),
          ]);
        }

        return true;

      case 'Hasil KRS':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilKrsPage()),
        );
        return true;

      case 'Hasil KHS':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilKhsPage()),
        );
        return true;

      default:
        return false;

      // case 'Persyaratan KRS':
      //   if (token == null || idLogin == null) {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const LoginScreen()),
      //     );
      //     return true;
      //   }

      //   try {
      //     final data = await KrsService.getRequirements(
      //       idLogin: idLogin,
      //       token: token,
      //     );

      //     addBotWidgets([
      //       _botBubble("Berikut status persyaratan KRS kamu:"),
      //       KrsRequirementBubble(items: data),
      //     ]);
      //   } catch (e) {
      //     addBotWidgets([
      //       _botBubble("Gagal mengambil data persyaratan KRS 😢"),
      //     ]);
      //   }

      //   return true;

      // default:
      //   return false;
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

// KRS Requirement
class KrsRequirement {
  final String id;
  final String description;
  final int status;

  KrsRequirement({
    required this.id,
    required this.description,
    required this.status,
  });

  factory KrsRequirement.fromJson(Map<String, dynamic> json) {
    return KrsRequirement(
      id: json['req_id']?.toString() ?? '',
      description: json['description'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
    );
  }
}

class KrsRequirementResponse {
  final List<KrsRequirement> requirements;
  final String idSemester;

  KrsRequirementResponse({
    required this.requirements,
    required this.idSemester,
  });
}

class KrsService {
  static Future<KrsRequirementResponse> getRequirements({
    required String idLogin,
    required String token,
  }) async {
    final url = Uri.parse('https://sismob.trisakti.ac.id/api/krs-requirement');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"IdLogin": idLogin, "token": token}),
    );

    final json = jsonDecode(res.body);

    debugPrint('KRS Requirement RAW: $json');

    final List list = json['body']?['requirements'] ?? [];
    final String semester = json['body']?['IdSemesterMain'] ?? '';

    final requirements = list
        .map<KrsRequirement>((e) => KrsRequirement.fromJson(e))
        .toList();

    return KrsRequirementResponse(
      requirements: requirements,
      idSemester: semester,
    );
  }
}
