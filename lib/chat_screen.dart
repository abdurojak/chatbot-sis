import 'package:chatbot/component/chat_helper.dart';
import 'package:chatbot/component/app_theme.dart';
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

  late List<Widget> chatWidgets;

  final TextEditingController _controller = TextEditingController();
  final String senderId = "test_user";

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    chatWidgets = [
      _botBubble(
        "Halo! Saya Academic Assistant, asisten akademik digital "
        "yang siap menemani anda.\n\n"
        "Saya bisa membantu anda mengecek status pembayaran, "
        "KRS, hasil akademik, jadwal perkuliahan, hingga "
        "memberikan solusi awal untuk berbagai kendala akademikmu.\n\n"
        "Tinggal bilang kebutuhanmu, saya bantu ya",
      ),

      const SizedBox(height: 12),

      // _userBubble("Kartu Rencana Studi"),

      // const SizedBox(height: 12),

      // _botMenu(),

      // const SizedBox(height: 12),
    ];
  }

  void addBotWidgets(List<Widget> widgets) {
    setState(() {
      chatWidgets.addAll(widgets);
      chatWidgets.add(const SizedBox(height: 12));
    });
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      chatWidgets.add(_userBubble(message));
      chatWidgets.add(const SizedBox(height: 12));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    final url = Uri.parse("http://103.28.161.71:5005/webhooks/rest/webhook");
    // final url = Uri.parse("https://chatbot-sis.free.beeceptor.com");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"sender": senderId, "message": message}),
    );

    final data = jsonDecode(response.body) as List;

    for (var item in data) {
      if (item["text"] != null) {
        setState(() {
          chatWidgets.add(_botBubble(item["text"]));
          chatWidgets.add(const SizedBox(height: 12));
        });
      }

      if (item["buttons"] != null) {
        setState(() {
          chatWidgets.add(_botMenuFromApi(item["buttons"]));
          chatWidgets.add(const SizedBox(height: 12));
        });
      }
    }
  }

  Widget _botMenuFromApi(List buttons) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePalette.soft(0.88),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          _header(context),

          // ================= CHAT CONTENT =================
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: chatWidgets,
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
        color: primaryBlue,
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
            backgroundColor: Colors.white,
            child: Icon(Icons.account_balance, color: primaryBlue),
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
          color: AppThemePalette.soft(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14)),
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
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: primaryBlue,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                _controller.clear();
                sendMessage(text);
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
