import 'dart:async';
import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/home_screen.dart';
import 'package:chatbot/login_screen.dart';
import 'package:chatbot/services/startup_security_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.autoNavigate = true,
    this.startupSecurityService,
  });

  final bool autoNavigate;
  final StartupSecurityService? startupSecurityService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingSecurity = false;
  String? _securityMessage;

  @override
  void initState() {
    super.initState();

    if (!widget.autoNavigate) {
      return;
    }

    Timer(const Duration(seconds: 5), _resolveStartup);
  }

  Future<void> _resolveStartup() async {
    if (!mounted || _isCheckingSecurity) return;

    setState(() {
      _isCheckingSecurity = true;
      _securityMessage = null;
    });

    final result =
        await (widget.startupSecurityService ?? StartupSecurityService())
            .resolveStartup();
    if (!mounted) return;

    switch (result) {
      case StartupSecurityResult.openHome:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      case StartupSecurityResult.requireLogin:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      case StartupSecurityResult.locked:
        setState(() {
          _isCheckingSecurity = false;
          _securityMessage = 'Autentikasi sidik jari diperlukan.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoAsset = AppThemePalette.isDark
        ? 'assets/images/logo_trisakti_black.png'
        : 'assets/images/logo_trisakti.png';
    final logoColor = AppThemePalette.isDark ? null : Colors.white;

    return Scaffold(
      backgroundColor: AppThemePalette.background,
      body: Stack(
        children: [
          // Background lengkung biru
          ClipPath(
            clipper: CurveClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppThemePalette.primary,
            ),
          ),

          // Logo & Text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(logoAsset, width: 150, color: logoColor),
                const SizedBox(height: 12),
                if (_isCheckingSecurity)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_securityMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _securityMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _resolveStartup,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Mulai dari kanan atas
    path.moveTo(size.width, 0);

    // Garis ke kiri
    path.lineTo(size.width * 0.35, 0);

    // Lengkungan atas ke bawah
    path.quadraticBezierTo(0, size.height * 0.25, 0, size.height * 0.5);

    path.quadraticBezierTo(
      0,
      size.height * 0.75,
      size.width * 0.35,
      size.height,
    );

    // Tutup ke kanan bawah
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
