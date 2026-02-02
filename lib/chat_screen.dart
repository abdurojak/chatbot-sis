import 'package:chatbot/login_screen.dart';
import 'package:flutter/material.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key});

  @override
  State<ChatDetailPage> createState() => ChatDetailPageState();
}

class ChatDetailPageState extends State<ChatDetailPage> {
  static const Color primaryBlue = Color(0xFF1E73BE);

  late List<Widget> chatWidgets;

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

      _userBubble("Kartu Rencana Studi"),

      const SizedBox(height: 12),

      _botMenu(),

      const SizedBox(height: 12),
    ];
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
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          const CircleAvatar(
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
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _botBubbleTransaksiKrs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Silakan pilih mata kuliah yang akan kamu ambil pada semester ini.\n\n"
            "Setelah selesai, ajukan KRS untuk diproses oleh Dosen Pembimbing Akademik.",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                'Pengisian KRS',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
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

  // ================= BOT MENU =================
  Widget _botMenu() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _menuItem(
              title: 'Prosedur KRS',
              onTap: () {
                print('Klik Prosedur KRS');
              },
            ),
            _menuItem(
              title: 'Persyaratan KRS',
              onTap: () {
                print('Klik Persyaratan KRS');
              },
            ),
            _menuItem(
              title: 'Transaksi KRS',
              onTap: () {
                setState(() {
                  chatWidgets.add(_userBubble("Transaksi KRS"));
                  chatWidgets.add(const SizedBox(height: 12));
                  chatWidgets.add(_botBubbleTransaksiKrs(context));
                });
              },
            ),
            _menuItem(
              title: 'Hasil KRS',
              onTap: () {
                print('Klik Hasil KRS');
              },
            ),
          ],
        ),
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
              style: const TextStyle(
                color: Color(0xFF1E73BE),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: Color(0xFF1E73BE)),
          ],
        ),
      ),
    );
  }

  // ================= INPUT BAR =================
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
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {},
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
