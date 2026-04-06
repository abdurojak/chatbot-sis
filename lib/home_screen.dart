import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
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
      future: _loadHeaderData(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        Uint8List? photoBytes;
        String name = 'Mahasiswa';

        if (data != null) {
          final base64Photo = data['photo'];
          final nim = data['nim'];

          if (base64Photo != null && base64Photo.isNotEmpty) {
            final pureBase64 = base64Photo
                .split(',')
                .last; // buang "data:image/jpg;base64,"
            photoBytes = base64Decode(pureBase64);
          }

          name = nim ?? 'Mahasiswa';
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

  // ================= AMBIL DATA FOTO =================
  Future<Map<String, String?>> _loadHeaderData() async {
    final photo = await AuthStorage.getPhotoBase64();
    final nim = await AuthStorage.getNim();

    return {'photo': photo, 'nim': nim};
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
        _semesterTitle('Genap 2025/2026'),
        const SizedBox(height: 12),
        _chatCard(context),

        const SizedBox(height: 24),

        _semesterTitle('Gasal 2025/2026'),
        const SizedBox(height: 12),
        _chatCard(context),
      ],
    );
  }

  // ================= WIDGET =================

  Widget _semesterTitle(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Page', style: TextStyle(fontSize: 24)),
    );
  }
}
