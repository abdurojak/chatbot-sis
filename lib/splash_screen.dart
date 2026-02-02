import 'dart:async';
import 'package:chatbot/home_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Delay 5 detik lalu pindah ke Login
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background lengkung biru
          ClipPath(
            clipper: CurveClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0A66C2), // BIRU TUA TRISAKTI
            ),
          ),

          // Logo & Text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_trisakti.png',
                  width: 150,
                  color: Colors.white, // pastikan putih
                ),
                const SizedBox(height: 12),
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
