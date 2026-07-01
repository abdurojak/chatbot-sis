part of 'home_screen.dart';

class NotificationPage extends StatefulWidget {
  final int refreshTick;
  final Future<void> Function()? onChanged;

  const NotificationPage({super.key, this.refreshTick = 0, this.onChanged});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  String? _error;
  NotificationResult? _result;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didUpdateWidget(covariant NotificationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      final idLogin = session?.idLogin;
      final token = session?.token;
      if (idLogin == null || token == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final result = await NotificationService.openNotifications(
        idLogin: idLogin,
        token: token,
      );
      if (!mounted) return;
      setState(() => _result = result);
      await widget.onChanged?.call();
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
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Text(
            'Notifikasi',
            style: TextStyle(
              color: AppThemePalette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_result?.count ?? 0} notifikasi',
            style: TextStyle(color: AppThemePalette.textSecondary),
          ),
          const SizedBox(height: 18),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _notificationMessageBox(_error!, isError: true)
          else if ((_result?.items ?? const []).isEmpty)
            _notificationMessageBox('Belum ada notifikasi.')
          else
            ..._result!.items.map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _notificationCard(notification),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notificationCard(AppNotification notification) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemePalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isUnread
              ? AppThemePalette.primary.withAlpha(80)
              : AppThemePalette.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppThemePalette.accentAvatar,
            child: Icon(
              Icons.notifications_active_rounded,
              color: AppThemePalette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        notification.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppThemePalette.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (notification.isUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppThemePalette.negative(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: AppThemePalette.textPrimary,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (notification.createdAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    notification.createdAt,
                    style: TextStyle(
                      color: AppThemePalette.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationMessageBox(String message, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isError
            ? (AppThemePalette.isDark
                  ? const Color(0xFF3B1D24)
                  : const Color(0xFFFFF4F4))
            : AppThemePalette.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppThemePalette.textPrimary),
          ),
          if (isError) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadNotifications,
              child: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }
}
