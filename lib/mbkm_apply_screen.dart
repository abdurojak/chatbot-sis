import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/mbkm_models.dart';
import 'package:chatbot/services/mbkm_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class MbkmApplyPage extends StatefulWidget {
  const MbkmApplyPage({super.key});

  @override
  State<MbkmApplyPage> createState() => _MbkmApplyPageState();
}

class _MbkmApplyPageState extends State<MbkmApplyPage> {
  static const String _defaultCompanyType = '2019';

  final _formKey = GlobalKey<FormState>();
  final _partnerSearchController = TextEditingController();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _moreInfoController = TextEditingController();
  final _employeeController = TextEditingController();
  final _dateStartController = TextEditingController();
  final _dateEndController = TextEditingController();
  final _dateSelectionController = TextEditingController();
  final _dateResultController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _idSemester;
  String? _selectedActivityTypeId;
  String? _selectedScaleKey;
  String? _selectedCompanyType = _defaultCompanyType;
  String _selectedPartner = '';
  List<MbkmPartnerOption> _partners = const [];
  List<MbkmActivityTypeOption> _activityTypes = const [];
  List<MbkmCompanyScaleOption> _scales = const [];

  Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _partnerSearchController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _moreInfoController.dispose();
    _employeeController.dispose();
    _dateStartController.dispose();
    _dateEndController.dispose();
    _dateSelectionController.dispose();
    _dateResultController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      if (session == null) {
        throw Exception('Sesi login tidak ditemukan');
      }

      final formData = await MbkmService.getApplyFormData(
        idLogin: session.idLogin,
        token: session.token,
      );

      if (!mounted) return;
      setState(() {
        _idSemester = formData.idSemester;
        _partners = formData.partners;
        _activityTypes = formData.activityTypes;
        _scales = formData.scales;
        _selectedActivityTypeId = formData.activityTypes.isNotEmpty
            ? formData.activityTypes.first.id
            : null;
        _selectedScaleKey = formData.scales.isNotEmpty
            ? formData.scales.first.key
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null || !mounted) {
      return;
    }

    controller.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  T? _findSelectedItem<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  MbkmPartnerOption? get _selectedPartnerOption =>
      _findSelectedItem(_partners, (item) => item.id == _selectedPartner);

  void _applyPartnerPrefill(MbkmPartnerOption? partner) {
    if (partner == null) {
      setState(() {
        _selectedPartner = '';
        _selectedCompanyType = _defaultCompanyType;
        _partnerSearchController.clear();
      });
      return;
    }

    setState(() {
      _partnerSearchController.text = partner.label;
      _selectedPartner = partner.id;
      _selectedCompanyType = partner.companyType.isNotEmpty
          ? partner.companyType
          : _defaultCompanyType;

      _companyController.text = partner.label;
      _employeeController.text = partner.numberOfEmployees;
      if (partner.scaleKey.isNotEmpty) {
        _selectedScaleKey = partner.scaleKey;
      }

      final detailParts = <String>[
        if (partner.field != '-') partner.field,
        if (partner.address != '-') 'Alamat: ${partner.address}',
        if (partner.contactPerson != '-') 'PIC: ${partner.contactPerson}',
      ];

      if (_descriptionController.text.trim().isEmpty &&
          detailParts.isNotEmpty) {
        _descriptionController.text = detailParts.join('. ');
      }

      if (_moreInfoController.text.trim().isEmpty && partner.hasWebsite) {
        _moreInfoController.text = partner.website;
      }
    });
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

    if (!mounted) return;

    if (_idSemester == null ||
        _selectedActivityTypeId == null ||
        _selectedScaleKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data referensi MBKM belum lengkap')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await MbkmService.applyMbkm(
        idLogin: session.idLogin,
        token: session.token,
        idSemester: _idSemester!,
        activityTypeId: _selectedActivityTypeId!,
        partner: _selectedPartner,
        title: _titleController.text.trim(),
        companyName: _companyController.text.trim(),
        description: _descriptionController.text.trim(),
        moreInfo: _moreInfoController.text.trim(),
        companyType: _selectedCompanyType ?? _defaultCompanyType,
        scale: _selectedScaleKey!,
        numberOfEmployees: _employeeController.text.trim(),
        dateStart: _dateStartController.text.trim(),
        dateEnd: _dateEndController.text.trim(),
        dateSelection: _dateSelectionController.text.trim(),
        dateResult: _dateResultController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengajukan MBKM: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan MBKM'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryBlue.withAlpha(235),
                          AppThemePalette.dark(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Form Pengajuan',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lengkapi data untuk mengajukan program MBKM.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField<MbkmActivityTypeOption>(
                    label: 'Jenis Aktivitas',
                    value: _findSelectedItem(
                      _activityTypes,
                      (item) => item.id == _selectedActivityTypeId,
                    ),
                    items: _activityTypes,
                    itemLabel: (item) => '${item.name} (${item.shortName})',
                    onChanged: (value) {
                      setState(() => _selectedActivityTypeId = value?.id);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_partners.isNotEmpty)
                    _buildSearchablePartnerField()
                  else
                    _buildInfoField(
                      label: 'Partner',
                      value: 'Belum ada data partner dari API',
                    ),
                  if (_selectedPartnerOption != null) ...[
                    const SizedBox(height: 12),
                    _buildPartnerSummary(_selectedPartnerOption!),
                  ],
                  const SizedBox(height: 12),
                  _buildTextField(controller: _titleController, label: 'Judul'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _companyController,
                    label: 'Nama Perusahaan',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Deskripsi',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _moreInfoController,
                    label: 'More Info URL',
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField<MbkmCompanyScaleOption>(
                    label: 'Skala Perusahaan',
                    value: _findSelectedItem(
                      _scales,
                      (item) => item.key == _selectedScaleKey,
                    ),
                    items: _scales,
                    itemLabel: (item) => item.value,
                    onChanged: (value) {
                      setState(() => _selectedScaleKey = value?.key);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _employeeController,
                    label: 'Jumlah Karyawan',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    controller: _dateStartController,
                    label: 'Tanggal Mulai',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    controller: _dateEndController,
                    label: 'Tanggal Selesai',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    controller: _dateSelectionController,
                    label: 'Tanggal Seleksi',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    controller: _dateResultController,
                    label: 'Tanggal Hasil',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoField(
                    label: 'Company Type',
                    value: _selectedCompanyType ?? _defaultCompanyType,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim Pengajuan'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchablePartnerField() {
    return DropdownMenu<MbkmPartnerOption>(
      controller: _partnerSearchController,
      width: double.infinity,
      enableSearch: true,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 320,
      expandedInsets: EdgeInsets.zero,
      initialSelection: _selectedPartnerOption,
      label: const Text('Partner'),
      hintText: 'Cari atau pilih partner',
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      inputDecorationTheme: InputDecorationTheme(
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
      dropdownMenuEntries: _partners
          .map(
            (item) => DropdownMenuEntry<MbkmPartnerOption>(
              value: item,
              label: item.label,
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 14),
                ),
              ),
            ),
          )
          .toList(),
      onSelected: _applyPartnerPrefill,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () => _pickDate(controller),
    );
  }

  Widget _buildInfoField({required String label, required String value}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildPartnerSummary(MbkmPartnerOption partner) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemePalette.soft(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_rounded, color: primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Partner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPartnerInfoRow('Nama', partner.label),
          _buildPartnerInfoRow('Bidang', partner.field),
          _buildPartnerInfoRow('Alamat', partner.address),
          _buildPartnerInfoRow('PIC', partner.contactPerson),
          _buildPartnerInfoRow('Email', partner.email),
          _buildPartnerInfoRow('Telepon', partner.phone),
        ],
      ),
    );
  }

  Widget _buildPartnerInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 320,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) {
        return items
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  itemLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList();
      },
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && value == null) {
          return '$label wajib dipilih';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
