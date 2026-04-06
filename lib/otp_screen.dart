import 'dart:convert';
import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpVerificationScreen extends StatefulWidget {
  final String idOtp;

  const OtpVerificationScreen({super.key, required this.idOtp});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int otpLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length != otpLength) {
      _showMessage('Kode OTP belum lengkap');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/otp-verification'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_otp": widget.idOtp, "kode_otp": _otpCode}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatDetailPage()),
        );
      } else {
        _showMessage(data['message'] ?? 'OTP tidak valid');
      }
    } catch (e) {
      _showMessage('Terjadi error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppThemePalette.screenGradient()),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // LOGO
              Image.asset(
                'assets/images/logo_trisakti.png',
                width: 120,
                color: Colors.white,
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppThemePalette.soft(0.35),
                        AppThemePalette.soft(0.78),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "OTP Verification",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThemePalette.dark(0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Masukkan kode OTP yang dikirim ke email kamu",
                        style: TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 24),

                      // OTP INPUT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(otpLength, (i) => _otpBox(i)),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemePalette.dark(0.35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyOtp,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Confirm",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: (val) {
          if (val.isNotEmpty && index < otpLength - 1) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          if (val.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
