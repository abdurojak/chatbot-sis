import 'package:flutter/material.dart';
import 'package:chatbot/component/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _dateController = TextEditingController();
  bool _obscurePassword = true;

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
                const SizedBox(height: 40),

                // Logo
                Image.asset(
                  'assets/images/logo_trisakti.png',
                  width: 150,
                  color: Colors.white,
                ),

                const SizedBox(height: 50),

                _inputField(hint: 'Email'),

                const SizedBox(height: 16),

                _dateField(),

                const SizedBox(height: 16),

                _inputField(hint: 'Nama Ibu Kandung'),

                const SizedBox(height: 16),

                _passwordField(),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemePalette.dark(0.35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {},
                        child: const Text('Kirim'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Batalkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========= Widgets =========

  Widget _inputField({required String hint}) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppThemePalette.textTertiary),
        filled: true,
        fillColor: AppThemePalette.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Tanggal Lahir',
        hintStyle: TextStyle(color: AppThemePalette.textTertiary),
        suffixIcon: Icon(
          Icons.calendar_month,
          color: AppThemePalette.textSecondary,
        ),
        filled: true,
        fillColor: AppThemePalette.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
        }
      },
    );
  }

  Widget _passwordField() {
    return TextField(
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Konfirmasi Password Baru',
        hintStyle: TextStyle(color: AppThemePalette.textTertiary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppThemePalette.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: AppThemePalette.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
