import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/convocation_models.dart';
import 'package:chatbot/services/convocation_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class ConvocationApplicationPage extends StatefulWidget {
  final ConvocationData? convocationData;

  const ConvocationApplicationPage({super.key, this.convocationData});

  @override
  State<ConvocationApplicationPage> createState() =>
      _ConvocationApplicationPageState();
}

class _ConvocationApplicationPageState
    extends State<ConvocationApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _biayaController = TextEditingController();
  final _dateEndController = TextEditingController();
  final _receiverController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSavingPhotoOption = false;
  late List<ConvocationTogaSizeOption> _availableTogaSizes;
  late List<ConvocationPhotoPackageOption> _availablePhotoPackages;
  late List<ConvocationPhotoAdditionOption> _availablePhotoAdditions;
  late String _paymentDeadline;
  String _selectedTogaSize = '';
  String _selectedPhotoPackage = '';
  final Set<String> _selectedPhotoAdditions = <String>{};

  Color get primaryBlue => AppThemePalette.primary;

  ConvocationTogaSizeOption get _selectedTogaOption =>
      _availableTogaSizes.firstWhere(
        (item) => item.code == _selectedTogaSize,
        orElse: () => _availableTogaSizes.first,
      );

  ConvocationPhotoPackageOption get _selectedPhotoPackageOption =>
      _availablePhotoPackages.firstWhere(
        (item) => item.code == _selectedPhotoPackage,
        orElse: () => _availablePhotoPackages.first,
      );

  String get _selectedAdditionSummary {
    if (_selectedPhotoAdditions.isEmpty) {
      return 'Belum ada tambahan dipilih';
    }

    final labels = _availablePhotoAdditions
        .where((item) => _selectedPhotoAdditions.contains(item.id))
        .map((item) => item.title)
        .toList();
    return labels.join(', ');
  }

  @override
  void initState() {
    super.initState();
    _hydrateFromConvocation();
  }

  void _hydrateFromConvocation() {
    final info = widget.convocationData?.infoWisuda;
    final snapshot = widget.convocationData?.applicationSnapshot;

    _availableTogaSizes =
        info?.togaSizes.entries
            .map(
              (entry) => ConvocationTogaSizeOption(
                code: entry.key,
                fitLabel: entry.value,
                bodyHint: 'Detail ukuran akan menyesuaikan data dari backend.',
                details: [
                  'Kode ukuran: ${entry.key}',
                  'Kategori: ${entry.value}',
                ],
              ),
            )
            .toList() ??
        convocationTogaSizes;
    if (_availableTogaSizes.isEmpty) {
      _availableTogaSizes = convocationTogaSizes;
    }

    _availablePhotoPackages = info?.photoPackages.isNotEmpty == true
        ? info!.photoPackages
        : convocationPhotoPackages;
    _availablePhotoAdditions = info?.photoAdditions.isNotEmpty == true
        ? info!.photoAdditions
        : convocationPhotoAdditions;

    _paymentDeadline = info?.paymentDeadline.trim().isNotEmpty == true
        ? info!.paymentDeadline
        : convocationPhotoPaymentDeadline;

    _selectedTogaSize = _availableTogaSizes.first.code;
    final togaFromApplication = snapshot?.togaSize ?? '';
    if (togaFromApplication.isNotEmpty &&
        _availableTogaSizes.any((item) => item.code == togaFromApplication)) {
      _selectedTogaSize = togaFromApplication;
    }

    _selectedPhotoPackage = _availablePhotoPackages.first.code;
    if (_availablePhotoPackages.any((item) => item.code == 'N')) {
      _selectedPhotoPackage = 'N';
    }

    _selectedPhotoAdditions
      ..clear()
      ..addAll(
        snapshot?.photoAdditions.where(
              (code) => _availablePhotoAdditions.any((item) => item.id == code),
            ) ??
            const <String>[],
      );

    _biayaController.text = snapshot?.fee.trim().isNotEmpty == true
        ? snapshot!.fee
        : (info?.fee ?? '');
    _dateEndController.text = _paymentDeadline;
    _receiverController.text = snapshot?.receiver ?? '';
    _addressController.text = snapshot?.address ?? '';
    _cityController.text = snapshot?.city ?? '';
    _provinceController.text = snapshot?.province ?? '';
    _postalCodeController.text = snapshot?.postalCode ?? '';
    _phoneController.text = snapshot?.phone ?? '';
  }

  @override
  void dispose() {
    _biayaController.dispose();
    _dateEndController.dispose();
    _receiverController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (picked == null || !mounted) return;

    _dateEndController.text =
        '${picked.day.toString().padLeft(2, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.year.toString().padLeft(4, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await ConvocationService.submitApplication(
        idLogin: session.idLogin,
        token: session.token,
        request: ConvocationApplicationRequest(
          biaya: _biayaController.text.trim(),
          dateEnd: _dateEndController.text.trim(),
          togaSize: _selectedTogaSize,
          receiver: _receiverController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          phone: _phoneController.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim aplikasi wisuda: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _savePhotoOption() async {
    final session = await SessionService.loadSession();
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSavingPhotoOption = true);

    try {
      final message = await ConvocationService.submitApplicationOption(
        idLogin: session.idLogin,
        token: session.token,
        request: ConvocationApplicationOptionRequest(
          photoPackage: _selectedPhotoPackage,
          additions: _selectedPhotoAdditions.toList()..sort(),
          paymentDeadline: _paymentDeadline,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan paket foto: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSavingPhotoOption = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Aplikasi Wisuda'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Informasi Utama',
              icon: Icons.receipt_long_rounded,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _biayaController,
                    label: 'Biaya Wisuda',
                    keyboardType: TextInputType.number,
                    hintText: 'Contoh: 2400000',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Pilih Ukuran Toga',
              icon: Icons.checkroom_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih ukuran yang paling nyaman, lalu cek detail ukurannya di panel bawah.',
                    style: TextStyle(
                      color: AppThemePalette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableTogaSizes
                        .map(_buildTogaSizeCard)
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildTogaDetailCard(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Paket Foto',
              icon: Icons.photo_camera_back_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih paket foto tambahan dan simpan opsi Anda. Paket dan tambahan masih hardcoded sementara.',
                    style: TextStyle(
                      color: AppThemePalette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: _availablePhotoPackages
                        .map(_buildPhotoPackageCard)
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoPackageSummaryCard(),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppThemePalette.soft(0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryBlue.withAlpha(22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambahan Paket',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._availablePhotoAdditions.map(
                          _buildPhotoAdditionTile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Batas pembayaran: $_paymentDeadline',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSavingPhotoOption ? null : _savePhotoOption,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: BorderSide(color: primaryBlue.withAlpha(80)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSavingPhotoOption
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSavingPhotoOption
                            ? 'Menyimpan Paket Foto...'
                            : 'Simpan Paket Foto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Penerima dan Pengiriman',
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _receiverController,
                    label: 'Nama Penerima',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Alamat',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'Kota',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _provinceController,
                          label: 'Provinsi',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _postalCodeController,
                          label: 'Kode Pos',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Telepon',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Aplikasi'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue.withAlpha(238), AppThemePalette.dark(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form Aplikasi Wisuda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lengkapi data pengajuan dan pilih ukuran toga yang paling sesuai sebelum mengirim aplikasi wisuda.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryBlue.withAlpha(28)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryBlue),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTogaSizeCard(ConvocationTogaSizeOption option) {
    final isSelected = option.code == _selectedTogaSize;

    return InkWell(
      onTap: () => setState(() => _selectedTogaSize = option.code),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, AppThemePalette.dark(0.08)],
                )
              : null,
          color: isSelected ? null : AppThemePalette.fieldFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : primaryBlue.withAlpha(28),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppThemePalette.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.code,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.fitLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? Colors.white70
                    : AppThemePalette.textSecondary,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTogaDetailCard() {
    final option = _selectedTogaOption;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePalette.soft(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withAlpha(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ukuran ${option.code}',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            option.bodyHint,
            style: TextStyle(
              color: AppThemePalette.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          ...option.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 7, color: primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail,
                      style: TextStyle(
                        color: AppThemePalette.textPrimary,
                        height: 1.4,
                      ),
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

  Widget _buildPhotoPackageCard(ConvocationPhotoPackageOption option) {
    final isSelected = option.code == _selectedPhotoPackage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedPhotoPackage = option.code),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, AppThemePalette.dark(0.08)],
                  )
                : null,
            color: isSelected ? null : AppThemePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : primaryBlue.withAlpha(24),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppThemePalette.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(22)
                      : primaryBlue.withAlpha(14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.code,
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          option.title,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppThemePalette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (option.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withAlpha(28)
                                  : primaryBlue.withAlpha(14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Rekomendasi',
                              style: TextStyle(
                                color: isSelected ? Colors.white : primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.priceLabel,
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white70
                            : AppThemePalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? Colors.white : primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPackageSummaryCard() {
    final package = _selectedPhotoPackageOption;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppThemePalette.soft(0.92), AppThemePalette.soft(0.86)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pilihan',
            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _summaryRow('Paket', '${package.title} (${package.code})'),
          _summaryRow('Harga', package.priceLabel),
          _summaryRow('Tambahan', _selectedAdditionSummary),
          _summaryRow('Batas Bayar', _paymentDeadline),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: AppThemePalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAdditionTile(ConvocationPhotoAdditionOption option) {
    final isChecked = _selectedPhotoAdditions.contains(option.id);

    return CheckboxListTile(
      value: isChecked,
      contentPadding: EdgeInsets.zero,
      activeColor: primaryBlue,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        option.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        option.subtitle,
        style: TextStyle(color: AppThemePalette.textSecondary, height: 1.35),
      ),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedPhotoAdditions.add(option.id);
          } else {
            _selectedPhotoAdditions.remove(option.id);
          }
        });
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateEndController,
      readOnly: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Batas akhir wajib diisi';
        }
        return null;
      },
      onTap: _pickDate,
      decoration: InputDecoration(
        labelText: 'Batas Akhir',
        hintText: 'dd-MM-yyyy',
        suffixIcon: const Icon(Icons.calendar_month_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
