import 'dart:convert';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Email & password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://sismob.trisakti.ac.id/api/login'), // GANTI URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String token = data['token'];
        final String idOtp = data['id_otp'];
        final String userId = data['userid'];

        // 👇 SIMPAN KE AUTH STORAGE
        await AuthStorage.saveAuth(
          token: data['token'],
          idLogin: data['IdLogin'], // ini penting buat KRS requirement
          userId: data['userid'],
          nim: data['nim'],
          color: data['color'],
          photoBase64: data['photo'], // ⚠️ base64 besar, lihat catatan di bawah
          active: data['Active'], // pakai userid sebagai IdLogin sesuai API KRS
        );

        debugPrint('TOKEN: $token');
        debugPrint('USERID: $userId');
        debugPrint('idOtp: $idOtp');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(idOtp: idOtp),
          ),
        );
      } else {
        _showMessage(data['status'] ?? 'Login gagal');
      }
    } catch (e) {
      _showMessage('Terjadi error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A66C2), Colors.white],
          ),
        ),
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
                      backgroundColor: const Color(0xFF2F477A),
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

// class OtpVerificationScreen extends StatelessWidget {
//   final String idOtp;

//   const OtpVerificationScreen({super.key, required this.idOtp});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Verifikasi OTP")),
//       body: Center(child: Text("ID OTP: $idOtp")),
//     );
//   }
// }
