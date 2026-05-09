import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/services/auth_service.dart';
import 'package:flutter/material.dart';

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
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode =>
      _controllers.map((controller) => controller.text.trim()).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length != otpLength) {
      _showMessage('Kode OTP belum lengkap');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.verifyOtp(
        idOtp: widget.idOtp,
        otpCode: _otpCode,
      );

      if (result.isSuccess) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatDetailPage()),
        );
      } else {
        _showMessage(result.message);
      }
    } catch (e) {
      _showMessage('Terjadi error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                        'OTP Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThemePalette.dark(0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan kode OTP yang dikirim ke email kamu',
                        style: TextStyle(color: AppThemePalette.textPrimary),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          otpLength,
                          (index) => _otpBox(index),
                        ),
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
                                  'Confirm',
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
        onChanged: (value) {
          if (value.isNotEmpty && index < otpLength - 1) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppThemePalette.fieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
