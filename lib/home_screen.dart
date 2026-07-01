import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/chat_models.dart';
import 'package:chatbot/models/auth_models.dart';
import 'package:chatbot/models/notification_models.dart';
import 'package:chatbot/services/chat_service.dart';
import 'package:chatbot/services/notification_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:chatbot/login_screen.dart';
import 'package:chatbot/user_chat_screen.dart';
import 'package:flutter/material.dart';

part 'home_screen_widgets.dart';
part 'notification_page.dart';
part 'chat_page.dart';
part 'discussion_page.dart';
part 'profile_page.dart';

IconData _themeModeIcon() {
  return AppThemePalette.isDark
      ? Icons.dark_mode_rounded
      : Icons.light_mode_rounded;
}

Color _themeModeIconColor(Color fallback) {
  return AppThemePalette.isDark ? AppThemePalette.primary : fallback;
}

String _timeGreeting(DateTime time) {
  final hour = time.hour;
  if (hour >= 4 && hour < 11) return 'Selamat pagi';
  if (hour >= 11 && hour < 15) return 'Selamat siang';
  if (hour >= 15 && hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String _firstName(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) return 'Mahasiswa';
  return trimmedName.split(RegExp(r'\s+')).first;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ChatPage langsung aktif
  int selectedIndex = 1;
  int _notificationCount = 0;
  int _notificationRefreshTick = 0;

  Color get _navigationBarColor => AppThemePalette.topBar;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<bool> _hasLoginSession() async {
    final session = await SessionService.loadSession();
    return session?.token != null && session?.idLogin != null;
  }

  Future<void> _requireLoginOrOpenNotifications() async {
    if (!await _hasLoginSession()) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (mounted) {
        await _loadNotificationCount();
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      selectedIndex = 0;
      _notificationRefreshTick++;
    });
    await _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final session = await SessionService.loadSession();
    final idLogin = session?.idLogin;
    final token = session?.token;

    if (idLogin == null || token == null) {
      if (mounted) {
        setState(() => _notificationCount = 0);
      }
      return;
    }

    try {
      final result = await NotificationService.openNotifications(
        idLogin: idLogin,
        token: token,
      );
      if (!mounted) return;
      setState(() => _notificationCount = result.count);
    } catch (_) {
      if (mounted) {
        setState(() => _notificationCount = 0);
      }
    }
  }

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
                        NotificationPage(
                          refreshTick: _notificationRefreshTick,
                          onChanged: _loadNotificationCount,
                        ),
                        ChatPage(
                          themeTick: AppThemeController.instance,
                          notificationCount: _notificationCount,
                          onOpenNotifications: _requireLoginOrOpenNotifications,
                        ),
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

        String name = 'Mahasiswa';

        if (session != null) {
          final displayName = session.studentName.trim().isNotEmpty
              ? session.studentName
              : 'Mahasiswa';

          name = _firstName(displayName);
        }

        final greeting = _timeGreeting(DateTime.now());

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          decoration: BoxDecoration(
            color: _navigationBarColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "$greeting, $name!".toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _themeToggleButton(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeToggleButton() {
    final isDark = AppThemePalette.isDark;
    return IconButton(
      tooltip: isDark ? 'Light Mode' : 'Dark Mode',
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(42),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _themeModeIcon(),
          color: _themeModeIconColor(Colors.white),
          size: 22,
        ),
      ),
      onPressed: () async {
        await _setDarkMode(!AppThemeController.instance.isDarkMode);
      },
    );
  }

  Future<void> _setDarkMode(bool enabled) async {
    await AppThemeController.instance.updateDarkMode(enabled);
    if (mounted) {
      setState(() {});
    }
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
          color: _navigationBarColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navIcon(Icons.notifications, 0, count: _notificationCount),
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
          color: _navigationBarColor,
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
  Widget _navIcon(IconData icon, int index, {int count = 0}) {
    final isActive = selectedIndex == index;

    return IconButton(
      icon: NotificationBadge(
        count: count,
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withAlpha(153),
        ),
      ),
      onPressed: () async {
        if (index == 0) {
          await _requireLoginOrOpenNotifications();
          return;
        }
        setState(() => selectedIndex = index);
      },
    );
  }
}

// ================= PAGES =================
