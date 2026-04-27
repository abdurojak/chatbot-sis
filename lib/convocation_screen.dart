import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/convocation_models.dart';
import 'package:chatbot/services/convocation_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class ConvocationPage extends StatefulWidget {
  const ConvocationPage({super.key});

  @override
  State<ConvocationPage> createState() => _ConvocationPageState();
}

class _ConvocationPageState extends State<ConvocationPage> {
  bool _isLoading = true;
  String? _error;
  ConvocationData? _data;

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadConvocation();
  }

  Future<void> _loadConvocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final data = await ConvocationService.getConvocation(
        idLogin: session.idLogin,
        token: session.token,
      );

      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final steps = data?.buildSteps() ?? const <ConvocationStep>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Wisuda'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadConvocation,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadConvocation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(data),
                  const SizedBox(height: 18),
                  Text(
                    'Alur Wisuda',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...steps.map(_buildStepCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(ConvocationData? data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue.withAlpha(240), AppThemePalette.dark(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proses Wisuda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data?.hasInfoWisuda == true
                ? data!.infoWisuda
                : 'Pantau tahapan wisuda Anda dari yudisium sampai undangan.',
            style: const TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(ConvocationStep step) {
    final accent = switch (step.state) {
      ConvocationStepState.done => Colors.green.shade600,
      ConvocationStepState.current => primaryBlue,
      ConvocationStepState.locked => const Color(0xFF6B7280),
    };

    final icon = switch (step.state) {
      ConvocationStepState.done => Icons.check_rounded,
      ConvocationStepState.current => Icons.play_arrow_rounded,
      ConvocationStepState.locked => Icons.lock_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(22),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withAlpha(80)),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                Container(
                  width: 2,
                  height: 86,
                  margin: const EdgeInsets.only(top: 8),
                  color: step.order == 5
                      ? Colors.transparent
                      : accent.withAlpha(55),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withAlpha(50)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Langkah ${step.order}',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.statusText,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
