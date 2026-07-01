import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/models/chat_models.dart';
import 'package:chatbot/services/chat_service.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:flutter/material.dart';

class UserChatDetailPage extends StatefulWidget {
  final ChatContact contact;
  final String selectedCategory;

  const UserChatDetailPage({
    super.key,
    required this.contact,
    this.selectedCategory = ChatService.defaultCategory,
  });

  @override
  State<UserChatDetailPage> createState() => _UserChatDetailPageState();
}

class _UserChatDetailPageState extends State<UserChatDetailPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String? _idLogin;
  late String _selectedCategory;
  late String _sendCategory;
  List<ChatMessage> _messages = const [];

  Color get primaryBlue => AppThemePalette.primary;
  bool get _canChooseCategory => widget.contact.destType == '3';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _sendCategory = widget.selectedCategory == 'all'
        ? ChatService.defaultCategory
        : widget.selectedCategory;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await SessionService.loadSession();
      final token = session?.token;
      final idLogin = session?.idLogin;
      if (token == null || idLogin == null) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final messages = await ChatService.getContactContent(
        idLogin: idLogin,
        token: token,
        idReceiver: widget.contact.idReceiver,
        destType: widget.contact.destType,
      );

      if (!mounted) return;
      setState(() {
        _idLogin = idLogin;
        _messages = messages;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    final session = await SessionService.loadSession();
    final token = session?.token;
    final idLogin = session?.idLogin;
    if (token == null || idLogin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await ChatService.sendMessage(
        idLogin: idLogin,
        token: token,
        idReceiver: widget.contact.idReceiver,
        destType: widget.contact.destType,
        category: _messageCategory,
        message: text,
      );
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String get _messageCategory {
    return _sendCategory;
  }

  List<String> get _categoryOptions {
    return {ChatService.defaultCategory, ...ChatService.categories}.toList();
  }

  List<ChatMessage> get _visibleMessages {
    return ChatMessage.filterByCategory(_messages, _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: AppThemePalette.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _errorState()
                  : _messageList(),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 40, 16, 18),
      decoration: BoxDecoration(
        color: AppThemePalette.topBar,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppThemePalette.accentAvatar,
            child: Text(
              widget.contact.initials,
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.contact.destTypeLabel} • ${_categoryLabel(_selectedCategory)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                ChatDebugIds(
                  idSender: _idLogin ?? '-',
                  idReceiver: widget.contact.idReceiver,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppThemePalette.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    final messages = _visibleMessages;
    if (messages.isEmpty) {
      return _emptyMessageState();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        return _messageBubble(message);
      },
    );
  }

  Widget _emptyMessageState() {
    final isAllCategory = _selectedCategory == 'all';
    final categoryLabel = _categoryLabel(_selectedCategory);
    final description = isAllCategory
        ? 'Percakapan dengan ${widget.contact.name} masih kosong.'
        : 'Belum ada pesan pada kategori $categoryLabel untuk kontak ini.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppThemePalette.soft(0.7),
                        AppThemePalette.soft(0.9),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.forum_rounded,
                    color: AppThemePalette.dark(0.22),
                    size: 42,
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppThemePalette.negative(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppThemePalette.background,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Belum Ada Pesan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppThemePalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemePalette.textSecondary,
                  height: 1.45,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppThemePalette.soft(0.86),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Tulis pesan pertama di bawah',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage message) {
    final isMine = message.isMine(_idLogin ?? '');
    final bubbleColor = isMine ? primaryBlue : AppThemePalette.surface;
    final textColor = isMine ? Colors.white : AppThemePalette.textPrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withAlpha(38)
                      : AppThemePalette.soft(0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  message.category,
                  style: TextStyle(
                    color: isMine ? Colors.white : primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.message,
                style: TextStyle(color: textColor, height: 1.35),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  message.timeLabel,
                  style: TextStyle(
                    color: isMine
                        ? Colors.white70
                        : AppThemePalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppThemePalette.surface,
          boxShadow: [
            BoxShadow(
              color: AppThemePalette.shadow,
              blurRadius: 16,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _canChooseCategory ? 132 : 104,
              ),
              child: _categorySelector(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan',
                  hintStyle: TextStyle(color: AppThemePalette.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: AppThemePalette.fieldFill,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    return category == 'all' ? 'ALL' : category.toUpperCase();
  }

  Widget _categorySelector() {
    final decoration = BoxDecoration(
      color: AppThemePalette.soft(0.86),
      borderRadius: BorderRadius.circular(14),
    );

    if (!_canChooseCategory) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: decoration,
        child: Text(
          _categoryLabel(_messageCategory),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: decoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sendCategory,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: AppThemePalette.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryBlue,
            size: 18,
          ),
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          selectedItemBuilder: (context) {
            return _categoryOptions.map((category) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _categoryLabel(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: _categoryOptions.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                _categoryLabel(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppThemePalette.textPrimary),
              ),
            );
          }).toList(),
          onChanged: (category) {
            if (category == null) return;
            setState(() {
              _sendCategory = category;
              _selectedCategory = category;
            });
            _scrollToBottom();
          },
        ),
      ),
    );
  }
}

class ChatDebugIds extends StatelessWidget {
  final String idSender;
  final String idReceiver;

  const ChatDebugIds({
    super.key,
    required this.idSender,
    required this.idReceiver,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'IdSender: $idSender | IdReceiver: $idReceiver',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
