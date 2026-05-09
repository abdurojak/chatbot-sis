import 'dart:convert';

import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/fill_krs.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PerwalianPage extends StatefulWidget {
  const PerwalianPage({super.key});

  @override
  State<PerwalianPage> createState() => _PerwalianPageState();
}

class _PerwalianPageState extends State<PerwalianPage> {
  final _formKey = GlobalKey<FormState>();

  final _summaryCtrl = TextEditingController(text: 'KRS');
  final _descCtrl = TextEditingController(text: 'Persetujuan pengisian KRS');

  DateTime? _selectedDateTime;
  String _semesterId = '773'; // default, boleh kamu ambil dari API semester
  final String _problemId = '1';

  bool _loading = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal & jam perwalian dulu')),
      );
      return;
    }

    final session = await SessionService.loadSession();
    if (session == null) return;

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/counseling'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "IdLogin": session.idLogin,
          "token": session.token,
          "summary": _summaryCtrl.text,
          "problem_description": _descCtrl.text,
          "IdSemester": _semesterId,
          "appointment_date": _formatDateTime(_selectedDateTime!),
          "problem_id": _problemId,
        }),
      );

      final json = jsonDecode(res.body);

      if (res.statusCode == 200 && json['body']?['status proses'] == "1") {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan perwalian berhasil dikirim ✅'),
          ),
        );

        Navigator.pop(context); // balik ke chat
      } else {
        throw json['body']?['messages'] ?? 'Gagal mengirim perwalian';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Perwalian Akademik'),
        backgroundColor: PengisianKrsPage.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _field(label: 'Ringkasan', controller: _summaryCtrl),
              const SizedBox(height: 16),

              _field(
                label: 'Deskripsi Masalah',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _semesterId,
                decoration: _inputDecoration('Semester'),
                items: const [
                  DropdownMenuItem(
                    value: '773',
                    child: Text('Genap 2025/2026'),
                  ),
                ],
                onChanged: (v) => setState(() => _semesterId = v!),
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: _inputDecoration('Tanggal & Jam Perwalian'),
                  child: Text(
                    _selectedDateTime == null
                        ? 'Pilih tanggal & jam'
                        : _formatDateTime(_selectedDateTime!),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PengisianKrsPage.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Ajukan Perwalian',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      decoration: _inputDecoration(label),
    );
  }
}
