import 'package:chatbot/component/chat_helper.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key});

  @override
  State<ChatDetailPage> createState() => ChatDetailPageState();
}

class ChatDetailPageState extends State<ChatDetailPage> {
  Color get primaryBlue => AppThemePalette.primary;
  static const String _sisBotIconAsset = 'assets/images/sis_bot_icon.png';
  Color get _botBubbleColor => AppThemePalette.isDark
      ? AppThemePalette.accentAvatar
      : AppThemePalette.soft(0.9);
  Color get _botMenuColor => AppThemePalette.isDark
      ? AppThemePalette.accentAvatar
      : AppThemePalette.soft(0.88);

  final List<Widget> chatWidgets = [];
  bool _isBotTyping = false;

  final TextEditingController _controller = TextEditingController();
  final String senderId = "test_user";
  late final String _anonymousSenderId = _createAnonymousSenderId();
  String? _idLogin;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSessionData();

    chatWidgets.addAll([
      _botBubble(
        "Halo! Saya Academic Assistant, asisten akademik digital "
        "yang siap menemani anda.\n\n"
        "Saya bisa membantu anda mengecek status pembayaran, "
        "KRS, hasil akademik, jadwal perkuliahan, hingga "
        "memberikan solusi awal untuk berbagai kendala akademikmu.\n\n"
        "Tinggal bilang kebutuhanmu, saya bantu ya",
      ),

      // _userBubble("Kartu Rencana Studi"),

      // const SizedBox(height: 12),

      // _botMenu(),

      // const SizedBox(height: 12),
    ]);
  }

  Future<void> _loadSessionData() async {
    final session = await SessionService.loadSession();
    if (!mounted) return;

    setState(() {
      _idLogin = session?.idLogin;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void addBotWidgets(List<Widget> widgets) {
    _appendWidgets(widgets);
  }

  void _appendWidgets(List<Widget> widgets) {
    if (!mounted) return;

    setState(() {
      chatWidgets.addAll(widgets.where((widget) => widget is! SizedBox));
    });

    _scrollToBottom();
  }

  void _setBotTyping(bool value) {
    if (!mounted || _isBotTyping == value) return;

    setState(() {
      _isBotTyping = value;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> sendMessage(String message) async {
    _appendWidgets([_userBubble(message)]);
    _setBotTyping(true);

    final url = Uri.parse("http://103.28.161.71:5005/webhooks/rest/webhook");
    try {
      // final url = Uri.parse("https://chatbot-sis.free.beeceptor.com");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": _senderIdentifier,
          "message": message,
          // "idLogin": _idLogin,
          // if (_idLogin != null && _idLogin!.isNotEmpty) "idLogin": _idLogin,
        }),
      );

      final data = jsonDecode(response.body) as List;
      final nextWidgets = <Widget>[];

      for (final item in data) {
        if (item["text"] != null) {
          nextWidgets.add(_botBubble(item["text"]));
        }

        if (item["buttons"] != null) {
          nextWidgets.add(_botMenuFromApi(item["buttons"]));
        }
      }

      _setBotTyping(false);

      if (nextWidgets.isEmpty) {
        _appendWidgets([
          _botBubble("Belum ada respons dari server. Coba beberapa saat lagi."),
        ]);
        return;
      }

      _appendWidgets(nextWidgets);
    } catch (_) {
      _setBotTyping(false);
      _appendWidgets([
        _botBubble(
          "Terjadi kendala saat mengambil balasan. Silakan coba lagi.",
        ),
      ]);
    }
  }

  String get _senderIdentifier {
    final idLogin = _idLogin?.trim();
    if (idLogin != null && idLogin.isNotEmpty) {
      return idLogin;
    }

    return _anonymousSenderId;
  }

  String _createAnonymousSenderId() {
    final now = DateTime.now().toIso8601String();
    return 'guest_${sha1.convert(utf8.encode(now)).toString()}';
  }

  @visibleForTesting
  String get senderIdentifierForTest => _senderIdentifier;

  Widget _botMenuFromApi(List buttons) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _botMenuColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buttons.map<Widget>((btn) {
            return _menuItem(
              title: btn["title"],
              onTap: () async {
                final payload = btn["payload"];

                final handled = await BotActionHandle.handle(
                  context,
                  payload: payload,
                  sendMessage: sendMessage,
                  addBotWidgets: addBotWidgets,
                );

                if (!handled) {
                  sendMessage(payload);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @visibleForTesting
  Widget buildBotMenuForTest(List buttons) => _botMenuFromApi(buttons);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePalette.background,

      body: Column(
        children: [
          _header(context),

          // ================= CHAT CONTENT =================
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: _buildChatChildren(),
            ),
          ),

          // ================= INPUT =================
          _inputBar(),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      decoration: BoxDecoration(
        color: AppThemePalette.topBar,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          CircleAvatar(
            radius: 22,
            backgroundColor: AppThemePalette.surface,
            child: ImageIcon(
              const AssetImage(_sisBotIconAsset),
              color: primaryBlue,
              size: 26,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Trisakti Bot',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Academic Assistant',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BOT BUBBLE =================
  Widget _botBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _botBubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: AppThemePalette.textPrimary),
        ),
      ),
    );
  }

  // ================= USER BUBBLE =================
  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppThemePalette.mutedSurface,
            child: Icon(
              Icons.person,
              size: 16,
              color: AppThemePalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({required String title, required VoidCallback onTap}) {
    final color = AppThemePalette.isDark ? Colors.white : primaryBlue;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: color),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    final inputFillColor = AppThemePalette.isDark
        ? const Color(0xFF111827)
        : const Color(0xFFE8EDF5);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: AppThemePalette.topBar,
      child: Row(
        children: [
          // IconButton(
          //   icon: const Icon(Icons.add, color: Colors.white),
          //   onPressed: () {},
          // ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputFillColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: AppThemePalette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppThemePalette.textTertiary),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () async {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                FocusScope.of(context).unfocus();
                _controller.clear();
                await sendMessage(text);
              }
            },
          ),

          // IconButton(
          //   icon: const Icon(Icons.camera_alt, color: Colors.white),
          //   onPressed: () {},
          // ),
        ],
      ),
    );
  }

  Widget _botTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _botBubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _TypingDot(delay: 0),
            SizedBox(width: 6),
            _TypingDot(delay: 120),
            SizedBox(width: 6),
            _TypingDot(delay: 240),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChatChildren() {
    final items = <Widget>[...chatWidgets];
    if (_isBotTyping) {
      items.add(_botTypingBubble());
    }

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(const SizedBox(height: 12));
      }
    }

    return children;
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppThemePalette.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
