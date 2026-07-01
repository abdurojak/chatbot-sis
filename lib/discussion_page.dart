part of 'home_screen.dart';

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
  String? _selectedCategory;
  String _typeFilter = 'all';
  List<ChatContact> _contacts = const [];
  List<ChatSearchResult> _searchResults = const [];

  static Color get primaryBlue => AppThemePalette.primary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!await _requireLogin()) {
        return;
      }

      if (mounted && _selectedCategory == null) {
        _showCategoryPicker();
      }
    });
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

  Future<bool> _requireLogin() async {
    final session = await SessionService.loadSession();
    if (session?.token != null && session?.idLogin != null) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return false;
  }

  Future<void> _loadContacts() async {
    final selectedCategory = _selectedCategory;
    if (selectedCategory == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (idLogin, token) = await _getAuth();
      final contacts = await ChatService.getContactsWithAutoGenerate(
        idLogin: idLogin,
        token: token,
        category: _categoryForContactRequest(selectedCategory),
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
      final results = await ChatService.searchContactsWithAutoGenerate(
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
          selectedCategory: _selectedCategory ?? 'all',
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
    final hasSelectedCategory = _selectedCategory != null;

    return Scaffold(
      backgroundColor: AppThemePalette.background,
      appBar: AppBar(
        title: const Text('Ruang Diskusi'),
        backgroundColor: AppThemePalette.topBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (hasSelectedCategory) {
            await _loadContacts();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _categoryStrip(),
            const SizedBox(height: 8),
            _categoryDivider(),
            const SizedBox(height: 10),
            if (!hasSelectedCategory)
              _emptyBox('Kategori belum dipilih.')
            else ...[
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
                _emptyBox(
                  'Belum ada kontak. Gunakan pencarian untuk mulai chat.',
                )
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
      onTap: () => _selectCategory(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 136,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemePalette.accentAvatar
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

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _contacts = const [];
      _searchResults = const [];
      _keyword = '';
      _searchController.clear();
      _typeFilter = 'all';
    });
    await _loadContacts();
  }

  String _categoryForContactRequest(String category) {
    return category == 'all' ? '' : category;
  }

  String _categoryLabel(String category) {
    return category == 'all' ? 'All' : category;
  }

  Future<void> _showCategoryPicker() async {
    final categories = ['all', ...ChatService.categories];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: _selectedCategory != null,
      enableDrag: _selectedCategory != null,
      showDragHandle: true,
      backgroundColor: AppThemePalette.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih kategori diskusi',
                    style: TextStyle(
                      color: AppThemePalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kontak akan dimuat sesuai kategori yang dipilih.',
                    style: TextStyle(color: AppThemePalette.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.6,
                          ),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategory == category;
                        return _categoryPickerTile(
                          category: category,
                          isSelected: isSelected,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _selectCategory(category);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryPickerTile({
    required String category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemePalette.accentAvatar
              : AppThemePalette.mutedSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryBlue : AppThemePalette.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _categoryIcon(category),
              color: isSelected ? AppThemePalette.dark(0.22) : primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _categoryLabel(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppThemePalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
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
            selectedColor: AppThemePalette.accentAvatar,
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
              backgroundColor: AppThemePalette.accentAvatar,
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
                if (contact.lastTimeLabel.isNotEmpty)
                  Text(
                    contact.lastTimeLabel,
                    style: TextStyle(
                      color: AppThemePalette.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 6),
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
