part of 'home_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthSession? _session;
  bool _isLoading = true;

  static Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final session = await AuthStorage.loadSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            if (_session == null)
              _loginRequiredCard()
            else
              _profileSummaryCard(_session!),
            /*
            Developer mode is intentionally hidden for release builds.
            Re-enable this card when local manual session switching is needed.

            */
            const SizedBox(height: 16),
            _darkModeCard(),
            const SizedBox(height: 16),
            if (_session != null) ...[
              const SizedBox(height: 16),
              _logoutButton(),
            ],
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await AuthStorage.clear();
    AppThemeController.instance.updatePrimaryColor(null);
    if (!mounted) return;
    await _loadProfileData();
  }

  Widget _profileSummaryCard(AuthSession session) {
    final photoBytes = _decodePhoto(session.photoBase64);
    final roleLabel = _roleLabel(session.role);
    final statusLabel = session.isActive ? 'Aktif' : 'Tidak aktif';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppThemePalette.accentAvatar,
              backgroundImage: photoBytes != null
                  ? MemoryImage(photoBytes)
                  : null,
              child: photoBytes == null
                  ? Icon(Icons.person_rounded, color: primaryBlue, size: 42)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              session.studentName.trim().isNotEmpty
                  ? session.studentName
                  : 'Nama belum tersedia',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // const SizedBox(height: 4),
          // Center(
          //   child: Text(
          //     roleLabel == 'Mahasiswa' ? (session.nim) : 'Profil Pengguna',
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       color: primaryBlue,
          //       fontSize: 17,
          //       fontWeight: FontWeight.w900,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryBlue.withAlpha(210),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$roleLabel $statusLabel',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _profileInfoRow('Nim', session.nim),
          _profileInfoRow('ID Login', session.idLogin),
          _profileInfoRow('User ID', session.userId),
          _profileInfoRow('Status', statusLabel),
        ],
      ),
    );
  }

  Widget _profileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: AppThemePalette.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginRequiredCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppThemePalette.accentAvatar,
            child: Icon(Icons.lock_rounded, color: primaryBlue, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            'Login Required',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masuk untuk melihat profil akademik Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppThemePalette.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((_) => _loadProfileData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Logout'),
    );
  }

  Uint8List? _decodePhoto(String? photoBase64) {
    if (photoBase64 == null || photoBase64.trim().isEmpty) {
      return null;
    }

    try {
      final pureBase64 = photoBase64.split(',').last;
      return base64Decode(pureBase64);
    } catch (_) {
      return null;
    }
  }

  String _roleLabel(String? role) {
    return switch (role) {
      'STD' => 'Mahasiswa',
      'DSN' => 'Dosen',
      'OTW' => 'Orang Tua/Wali',
      null || '' => 'Pengguna',
      _ => role,
    };
  }

  Widget _darkModeCard() {
    final isDark = AppThemePalette.isDark;
    final modeTitle = isDark ? 'Dark Mode' : 'Light Mode';
    final modeSubtitle = isDark
        ? 'Mode gelap diaktifkan.'
        : 'Mode terang diaktifkan.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: isDark,
        activeThumbColor: primaryBlue,
        title: Text(
          modeTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: primaryBlue,
          ),
        ),
        subtitle: Text(
          modeSubtitle,
          style: TextStyle(color: AppThemePalette.textSecondary),
        ),
        secondary: Icon(
          _themeModeIcon(),
          color: _themeModeIconColor(primaryBlue),
        ),
        onChanged: (enabled) async {
          await AppThemeController.instance.updateDarkMode(enabled);
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}
