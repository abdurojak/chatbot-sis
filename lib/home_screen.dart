import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/chat_models.dart';
import 'package:chatbot/models/auth_models.dart';
import 'package:chatbot/services/chat_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:chatbot/user_chat_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ChatPage langsung aktif
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppThemePalette.background,
          body: Stack(
            children: [
              Column(
                children: [
                  _header(),
                  Expanded(
                    child: IndexedStack(
                      index: selectedIndex,
                      children: [
                        const NotificationPage(),
                        ChatPage(themeTick: AppThemeController.instance),
                        const ProfilePage(),
                      ],
                    ),
                  ),
                ],
              ),
              _bottomBar(),
              _floatingChatButton(),
            ],
          ),
        );
      },
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
                  Expanded(
                    child: Text(
                      "Hello, $name!",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _headerMenu(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerMenu() {
    return PopupMenuButton<int>(
      color: AppThemePalette.surface,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      offset: const Offset(0, 46),
      icon: const Icon(Icons.menu_rounded, color: Colors.white),
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            enabled: false,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedBuilder(
              animation: AppThemeController.instance,
              builder: (menuContext, _) {
                final isDark = AppThemePalette.isDark;
                return SizedBox(
                  width: 72,
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await AppThemeController.instance.updateDarkMode(
                          !isDark,
                        );
                      },
                      child: Container(
                        width: 52,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppThemePalette.soft(0.82),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppThemePalette.divider),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppThemePalette.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ];
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
        clipper: CurvedDiscussionBottomBarClipper(),
        child: Container(
          height: 78,
          padding: const EdgeInsets.fromLTRB(48, 18, 48, 0),
          color: AppThemePalette.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navIcon(Icons.notifications, 0),
              const SizedBox(width: 56),
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
      bottom: 47,
      left: MediaQuery.of(context).size.width / 2 - 25,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppThemePalette.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 22,
          icon: Icon(
            Icons.chat_sharp,
            color: selectedIndex == 1 ? Colors.white : Colors.white70,
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
class CurvedDiscussionBottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final midX = size.width / 2;
    final path = Path()
      ..moveTo(0, 16)
      ..lineTo(midX - 58, 16)
      ..cubicTo(midX - 42, 16, midX - 40, 34, midX - 24, 39)
      ..cubicTo(midX - 10, 44, midX + 10, 44, midX + 24, 39)
      ..cubicTo(midX + 40, 34, midX + 42, 16, midX + 58, 16)
      ..lineTo(size.width, 16)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

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
  final Listenable? themeTick;

  const ChatPage({super.key, this.themeTick});

  static Color get primaryBlue => AppThemePalette.primary;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeTick ?? AppThemeController.instance,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _homeChatCard(
              title: 'Academic Assistant',
              subtitle: 'Tanya seputar akademik',
              icon: Icons.account_balance,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatDetailPage()),
                );
              },
            ),
            const SizedBox(height: 14),
            _homeChatCard(
              title: 'Ruang Diskusi',
              subtitle: 'Chat dengan dosen, kelas, dan kontak lainnya',
              icon: Icons.forum_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscussionPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _homeChatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              backgroundColor: AppThemePalette.surface,
              child: Icon(icon, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key});

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  String _keyword = '';
  String _selectedCategory = 'all';
  String _typeFilter = 'all';
  List<ChatContact> _contacts = const [];
  List<ChatSearchResult> _searchResults = const [];

  static Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<(String, String)> _getAuth() async {
    final session = await SessionService.loadSession();
    final token = session?.token;
    final idLogin = session?.idLogin;
    if (token == null || idLogin == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }
    return (idLogin, token);
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (idLogin, token) = await _getAuth();
      final contacts = await ChatService.getContactsWithAutoGenerate(
        idLogin: idLogin,
        token: token,
      );

      if (!mounted) return;
      setState(() {
        _contacts = contacts;
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

  Future<void> _searchContacts(String keyword) async {
    final trimmed = keyword.trim();
    setState(() => _keyword = trimmed);

    if (trimmed.length < 2) {
      setState(() => _searchResults = const []);
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final (idLogin, token) = await _getAuth();
      final results = await ChatService.searchContacts(
        idLogin: idLogin,
        token: token,
        keyword: trimmed,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mencari kontak: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _openUserChat(ChatContact contact) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatDetailPage(
          contact: contact,
          selectedCategory: _selectedCategory,
        ),
      ),
    );
    if (mounted) {
      await _loadContacts();
    }
  }

  List<ChatContact> get _visibleContacts {
    return _contacts.where((contact) {
      return switch (_typeFilter) {
        'unread' => contact.unreadCount > 0,
        'personal' => contact.destType != '3',
        'groups' => contact.destType == '3',
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Ruang Diskusi'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _categoryStrip(),
            const SizedBox(height: 8),
            _categoryDivider(),
            const SizedBox(height: 10),
            _typeFilterChips(),
            const SizedBox(height: 14),
            _searchBar(),
            const SizedBox(height: 18),
            if (_keyword.length >= 2) ...[
              _sectionTitle('Hasil Pencarian'),
              const SizedBox(height: 10),
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_searchResults.isEmpty)
                _emptyBox('Kontak tidak ditemukan.')
              else
                ..._searchResults.map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _contactCard(
                      result.contact,
                      sourceLabel: result.sourceLabel,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
            ],
            _sectionTitle('Kontak'),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _errorBox()
            else if (_contacts.isEmpty)
              _emptyBox('Belum ada kontak. Gunakan pencarian untuk mulai chat.')
            else if (_visibleContacts.isEmpty)
              _emptyBox('Tidak ada kontak untuk filter ini.')
            else
              ..._visibleContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _contactCard(contact),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET =================

  Widget _categoryDivider() {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppThemePalette.divider)),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }

  Widget _categoryStrip() {
    final categories = ['all', ...ChatService.categories];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _categoryTile(category);
        },
      ),
    );
  }

  Widget _categoryTile(String category) {
    final isSelected = _selectedCategory == category;
    final label = category == 'all' ? 'All' : category.toUpperCase();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 136,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemePalette.soft(0.78)
              : AppThemePalette.mutedSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppThemePalette.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _categoryIcon(category),
              color: isSelected
                  ? AppThemePalette.dark(0.22)
                  : AppThemePalette.negative(),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              '[$label]',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppThemePalette.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeFilterChips() {
    final filters = [
      ('all', 'All'),
      ('unread', 'Unread'),
      ('personal', 'Personal'),
      ('groups', 'Groups'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (value, label) = filters[index];
          final selected = _typeFilter == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: AppThemePalette.soft(0.78),
            backgroundColor: AppThemePalette.mutedSurface,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selected
                  ? AppThemePalette.textPrimary
                  : AppThemePalette.textSecondary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            onSelected: (_) => setState(() => _typeFilter = value),
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {});
        if (value.trim().length >= 2 || _keyword.isNotEmpty) {
          _searchContacts(value);
        }
      },
      onSubmitted: _searchContacts,
      decoration: InputDecoration(
        hintText: 'Cari kontak',
        hintStyle: TextStyle(color: AppThemePalette.textTertiary),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppThemePalette.textSecondary,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppThemePalette.textSecondary,
                ),
                onPressed: () {
                  _searchController.clear();
                  _searchContacts('');
                },
              ),
        filled: true,
        fillColor: AppThemePalette.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppThemePalette.textPrimary,
      ),
    );
  }

  Widget _contactCard(ChatContact contact, {String? sourceLabel}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openUserChat(contact),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppThemePalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withAlpha(26)),
          boxShadow: [
            BoxShadow(
              color: AppThemePalette.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppThemePalette.soft(0.78),
              child: Text(
                contact.initials,
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppThemePalette.textPrimary,
                    ),
                  ),
                  if ((sourceLabel ?? contact.sourceLabel).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      sourceLabel ?? contact.sourceLabel,
                      style: TextStyle(
                        color: AppThemePalette.negative(),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (contact.unreadCount > 0) ...[
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${contact.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (contact.lastTimeLabel.isNotEmpty)
                  Text(
                    contact.lastTimeLabel,
                    style: TextStyle(
                      color: AppThemePalette.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'krs' => Icons.assignment_rounded,
      'keuangan' => Icons.account_balance_wallet_rounded,
      'kuliah' => Icons.school_rounded,
      'ujian' => Icons.edit_document,
      'nilai' => Icons.grade_rounded,
      'wisuda' => Icons.workspace_premium_rounded,
      'bimbingan' => Icons.support_agent_rounded,
      'capstone' => Icons.lightbulb_rounded,
      'skripsi' => Icons.menu_book_rounded,
      _ => Icons.forum_rounded,
    };
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemePalette.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppThemePalette.textSecondary),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemePalette.isDark
            ? const Color(0xFF3B1D24)
            : const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppThemePalette.textPrimary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadContacts,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _FacultyThemeColor {
  final String name;
  final String hex;

  const _FacultyThemeColor({required this.name, required this.hex});

  Color get color => AppThemePalette.parseHex(hex);
}

class _ProfilePageState extends State<ProfilePage> {
  AuthSession? _session;
  List<DevAccountCredential> _savedAccounts = const [];
  bool _isLoading = true;

  static Color get primaryBlue => AppThemePalette.primary;
  static const _facultyThemeColors = [
    _FacultyThemeColor(name: 'Fakultas Hukum', hex: '#D71920'),
    _FacultyThemeColor(name: 'Fakultas Ekonomi', hex: '#F7C948'),
    _FacultyThemeColor(name: 'Fakultas Kedokteran', hex: '#2E7D32'),
    _FacultyThemeColor(name: 'Fakultas Kedokteran Gigi', hex: '#7B1FA2'),
    _FacultyThemeColor(
      name: 'Fakultas Teknik Sipil dan Perencanaan',
      hex: '#1565C0',
    ),
    _FacultyThemeColor(name: 'Fakultas Teknologi Industri', hex: '#03A9F4'),
    _FacultyThemeColor(
      name: 'Fakultas Teknologi Kebumian dan Energi',
      hex: '#0D47A1',
    ),
    _FacultyThemeColor(name: 'FALTL', hex: '#8BC34A'),
    _FacultyThemeColor(name: 'FSRD', hex: '#009688'),
    _FacultyThemeColor(name: 'Pascasarjana', hex: '#B86B2B'),
  ];

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
              Text(
                'Input manual idLogin dan token untuk kebutuhan testing lokal.',
                style: TextStyle(
                  height: 1.4,
                  color: AppThemePalette.textPrimary,
                ),
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
        const SizedBox(height: 16),
        _darkModeCard(),
        const SizedBox(height: 16),
        _facultyThemeCard(),
      ],
    );
  }

  Widget _darkModeCard() {
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
        value: AppThemePalette.isDark,
        activeThumbColor: primaryBlue,
        title: Text(
          'Dark Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: primaryBlue,
          ),
        ),
        subtitle: Text(
          'Aktifkan tampilan gelap untuk percobaan sementara.',
          style: TextStyle(color: AppThemePalette.textSecondary),
        ),
        secondary: Icon(
          AppThemePalette.isDark
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          color: primaryBlue,
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

  Widget _facultyThemeCard() {
    final activeHex = _session?.color?.toUpperCase();

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
          Row(
            children: [
              Icon(Icons.palette_rounded, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Pilih Warna Fakultas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Percobaan sementara untuk mengganti warna primary aplikasi.',
            style: TextStyle(height: 1.4, color: AppThemePalette.textPrimary),
          ),
          const SizedBox(height: 14),
          ..._facultyThemeColors.map((option) {
            final selected = activeHex == option.hex.toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _applyFacultyColor(option),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppThemePalette.soft(0.88)
                        : AppThemePalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? primaryBlue : AppThemePalette.divider,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: option.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppThemePalette.divider),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppThemePalette.textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: primaryBlue),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _applyFacultyColor(_FacultyThemeColor option) async {
    await AuthStorage.saveColor(option.hex);
    AppThemeController.instance.updatePrimaryColor(option.hex);
    await _loadProfileData();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Warna ${option.name} diterapkan')));
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
