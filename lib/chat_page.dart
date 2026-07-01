part of 'home_screen.dart';

class ChatPage extends StatelessWidget {
  final Listenable? themeTick;
  final int notificationCount;
  final VoidCallback? onOpenNotifications;

  const ChatPage({
    super.key,
    this.themeTick,
    this.notificationCount = 0,
    this.onOpenNotifications,
  });

  static Color get primaryBlue => AppThemePalette.primary;
  static const String _sisBotIconAsset = 'assets/images/sis_bot_icon.png';
  static const Color _darkSlateCardStart = Color(0xFF1E293B);
  static const Color _darkSlateCardEnd = Color(0xFF334155);

  LinearGradient get _homeCardGradient {
    if (!AppThemePalette.isDark) {
      return AppThemePalette.cardGradient();
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_darkSlateCardStart, _darkSlateCardEnd],
    );
  }

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
              iconAsset: _sisBotIconAsset,
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
            const SizedBox(height: 14),
            _homeChatCard(
              title: 'Notifikasi',
              subtitle: 'Lihat pemberitahuan akademik terbaru',
              icon: Icons.notifications_active_rounded,
              badgeCount: notificationCount,
              onTap: onOpenNotifications ?? () {},
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
    String? iconAsset,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _homeCardGradient,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppThemePalette.background,
              child: NotificationBadge(
                count: badgeCount,
                child: iconAsset == null
                    ? Icon(icon, color: AppThemePalette.negative())
                    : ImageIcon(
                        AssetImage(iconAsset),
                        color: AppThemePalette.negative(),
                        size: 26,
                      ),
              ),
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
