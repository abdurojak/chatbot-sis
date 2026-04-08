import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/otp_screen.dart';
import 'package:chatbot/services/auth_service.dart';
import 'package:flutter/material.dart';

import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Email & password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        user: _emailController.text,
        password: _passwordController.text,
      );

      if (result.isSuccess && result.session != null && result.idOtp != null) {
        await AuthStorage.saveSession(result.session!);
        AppThemeController.instance.updatePrimaryColor(result.session!.color);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(idOtp: result.idOtp!),
          ),
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
        decoration: BoxDecoration(gradient: AppThemePalette.screenGradient()),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Image.asset(
                  'assets/images/logo_trisakti.png',
                  width: 150,
                  color: Colors.white,
                ),
                const SizedBox(height: 60),
                _inputField(
                  controller: _emailController,
                  icon: Icons.person,
                  hint: 'Email / NIM',
                ),
                const SizedBox(height: 16),
                _inputField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  hint: 'Password',
                  isPassword: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 16),
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
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}
