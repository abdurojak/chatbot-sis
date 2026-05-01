import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/auth_models.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ChatPage langsung aktif
  int selectedIndex = 1;

  final List<Widget> pages = const [
    NotificationPage(),
    ChatPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          Column(
            children: [
              _header(),
              Expanded(
                child: IndexedStack(index: selectedIndex, children: pages),
              ),
            ],
          ),

          // Bottom bar
          _bottomBar(),

          // Floating Chat Button (TENGAH)
          _floatingChatButton(),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return FutureBuilder(
      future: AuthStorage.loadSession(),
      builder: (context, snapshot) {
        final session = snapshot.data;

        Uint8List? photoBytes;
        String name = 'Mahasiswa';

        if (session != null) {
          final base64Photo = session.photoBase64;
          final nim = session.nim;

          if (base64Photo != null && base64Photo.isNotEmpty) {
            try {
              final pureBase64 = base64Photo
                  .split(',')
                  .last; // buang "data:image/jpg;base64,"
              photoBytes = base64Decode(pureBase64);
            } catch (_) {
              photoBytes = null;
            }
          }

          name = nim;
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          decoration: BoxDecoration(
            color: AppThemePalette.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: photoBytes != null
                        ? MemoryImage(photoBytes)
                        : null,
                    child: photoBytes == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Hello, $name!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= BOTTOM BAR =================
  Widget _bottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipPath(
        clipper: BottomBarClipper(),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 48),
          color: AppThemePalette.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navIcon(Icons.notifications, 0),
              const SizedBox(width: 48), // ruang tombol tengah
              _navIcon(Icons.person_outline, 2),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FLOATING CHAT BUTTON =================
  Widget _floatingChatButton() {
    return Positioned(
      bottom: 38,
      left: MediaQuery.of(context).size.width / 2 - 32,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppThemePalette.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          iconSize: 30,
          icon: Icon(
            Icons.chat,
            color: selectedIndex == 1
                ? const Color.fromARGB(255, 255, 255, 255)
                : AppThemePalette.soft(0.45),
          ),
          onPressed: () {
            setState(() => selectedIndex = 1);
          },
        ),
      ),
    );
  }

  // ================= NAV ICON =================
  Widget _navIcon(IconData icon, int index) {
    final isActive = selectedIndex == index;

    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? Colors.white : Colors.white.withAlpha(153),
      ),
      onPressed: () {
        setState(() => selectedIndex = index);
      },
    );
  }
}

// ================= PAGES =================
class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 40; // ⬅️ BESARIN INI untuk lebih lebar

    final path = Path();

    path.lineTo(size.width / 2 - radius, 0);

    // setengah lingkaran sempurna
    path.arcTo(
      Rect.fromCircle(center: Offset(size.width / 2, 0), radius: radius),
      math.pi,
      -math.pi,
      false,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Notification Page', style: TextStyle(fontSize: 24)),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static Color get primaryBlue => AppThemePalette.primary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        // _semesterTitle('Genap 2025/2026'),
        const SizedBox(height: 12),
        _chatCard(context),

        const SizedBox(height: 24),

        // _semesterTitle('Gasal 2025/2026'),
        // const SizedBox(height: 12),
        // _chatCard(context),
      ],
    );
  }

  // ================= WIDGET =================

  Widget _chatCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatDetailPage()),
          // MaterialPageRoute(builder: (_) => const PerwalianPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppThemePalette.cardGradient(),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(Icons.account_balance, color: primaryBlue),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Academic Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Academic Assistant',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '12.00',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppThemePalette.dark(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthSession? _session;
  List<DevAccountCredential> _savedAccounts = const [];
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
    final accounts = await AuthStorage.loadDevAccountHistory();
    if (!mounted) return;
    setState(() {
      _session = session;
      _savedAccounts = accounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryBlue.withAlpha(40)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.developer_mode_rounded, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Development Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Input manual idLogin dan token untuk kebutuhan testing lokal.',
                style: TextStyle(height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _showDevSessionDialog(context, _session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Input idLogin & token'),
              ),
              const SizedBox(height: 10),
              if (_savedAccounts.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _showAccountPicker(context),
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Pilih Akun Tersimpan'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDevSessionDialog(
    BuildContext context,
    AuthSession? session,
  ) async {
    if (!context.mounted) return;

    final idLoginController = TextEditingController(
      text: session?.idLogin ?? '',
    );
    final tokenController = TextEditingController(text: session?.token ?? '');
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() => isSaving = true);

              try {
                final idLogin = idLoginController.text.trim();
                final token = tokenController.text.trim();

                await AuthStorage.saveManualSession(
                  idLogin: idLogin,
                  token: token,
                );
                await AuthStorage.saveDevAccountHistory(
                  idLogin: idLogin,
                  token: token,
                );

                if (!dialogContext.mounted || !dialogBuilderContext.mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                await _loadProfileData();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Akun aktif berhasil diganti')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan session: $e')),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Development Session'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: idLoginController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'idLogin wajib diisi';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'idLogin'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tokenController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'token wajib diisi';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'token'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    idLoginController.dispose();
    tokenController.dispose();
  }

  Future<void> _showAccountPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _savedAccounts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final account = _savedAccounts[index];
              final isActive =
                  _session?.idLogin == account.idLogin &&
                  _session?.token == account.token;
              return ListTile(
                leading: Icon(
                  isActive
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: primaryBlue,
                ),
                title: Text(
                  account.idLogin,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  account.token.length > 18
                      ? '${account.token.substring(0, 18)}...'
                      : account.token,
                ),
                onTap: () async {
                  await AuthStorage.saveManualSession(
                    idLogin: account.idLogin,
                    token: account.token,
                  );
                  if (!mounted || !sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  await _loadProfileData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Akun aktif: ${account.idLogin}')),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
