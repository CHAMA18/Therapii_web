import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_page.dart';
import 'package:therapii/pages/journal_admin_team_page.dart';
import 'package:therapii/utils/admin_access.dart';

class JournalAdminStudioPage extends StatefulWidget {
  const JournalAdminStudioPage({super.key});

  @override
  State<JournalAdminStudioPage> createState() => _JournalAdminStudioPageState();
}

class _JournalAdminStudioPageState extends State<JournalAdminStudioPage> {
  static const _prefsDraftKey = 'journal_admin_studio_draft_v1';

  final TextEditingController _titleController = TextEditingController(text: 'Building Resilience in Daily Life');
  final TextEditingController _quoteController = TextEditingController(
    text: 'Resilience is not just about bouncing back; it is about growing through what you go through.',
  );
  final TextEditingController _introController = TextEditingController(
    text:
        'In our fast-paced world, the ability to adapt to difficult situations is more crucial than ever. '
        'When we talk about resilience in a therapeutic context, we are not suggesting that you ignore your feelings.',
  );
  final TextEditingController _sectionTitleController = TextEditingController(text: 'The Psychology of Bouncing Back');
  final TextEditingController _sectionBodyController = TextEditingController(
    text:
        'Research indicates that resilience is not a fixed trait. It is a set of behaviors, thoughts, '
        'and actions that can be learned and developed by anyone.',
  );
  final TextEditingController _bulletsController =
      TextEditingController(text: 'Emotional Awareness\nRealistic Optimism\nSocial Support');
  final TextEditingController _continueController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  bool _publishImmediately = false;
  bool _isPublic = true;
  bool _hasUnsavedChanges = false;
  bool _isMainSidebarCollapsed = false;
  bool _isContentLibraryCollapsed = false;
  DateTime? _lastSavedAt;
  List<String> _tags = const ['Resilience', 'Anxiety'];

  @override
  void initState() {
    super.initState();
    _attachDirtyListeners();
    _loadDraft();
  }

  void _attachDirtyListeners() {
    final controllers = [
      _titleController,
      _quoteController,
      _introController,
      _sectionTitleController,
      _sectionBodyController,
      _bulletsController,
      _continueController,
      _summaryController,
      _dateController,
      _timeController,
    ];
    for (final controller in controllers) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!mounted) return;
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsDraftKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;

    _titleController.text = decoded['title'] as String? ?? _titleController.text;
    _quoteController.text = decoded['quote'] as String? ?? _quoteController.text;
    _introController.text = decoded['intro'] as String? ?? _introController.text;
    _sectionTitleController.text = decoded['sectionTitle'] as String? ?? _sectionTitleController.text;
    _sectionBodyController.text = decoded['sectionBody'] as String? ?? _sectionBodyController.text;
    _bulletsController.text = decoded['bullets'] as String? ?? _bulletsController.text;
    _continueController.text = decoded['continueText'] as String? ?? _continueController.text;
    _summaryController.text = decoded['summary'] as String? ?? _summaryController.text;
    _dateController.text = decoded['date'] as String? ?? _dateController.text;
    _timeController.text = decoded['time'] as String? ?? _timeController.text;
    _publishImmediately = decoded['publishImmediately'] as bool? ?? _publishImmediately;
    _isPublic = decoded['isPublic'] as bool? ?? _isPublic;

    final tags = decoded['tags'];
    if (tags is List) {
      _tags = tags.whereType<String>().where((e) => e.trim().isNotEmpty).toList(growable: false);
    }

    final lastSaved = decoded['lastSavedAt'] as String?;
    _lastSavedAt = lastSaved == null ? null : DateTime.tryParse(lastSaved);

    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
    }
  }

  Future<void> _saveDraft({bool publish = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'quote': _quoteController.text.trim(),
      'intro': _introController.text.trim(),
      'sectionTitle': _sectionTitleController.text.trim(),
      'sectionBody': _sectionBodyController.text.trim(),
      'bullets': _bulletsController.text.trim(),
      'continueText': _continueController.text.trim(),
      'summary': _summaryController.text.trim(),
      'date': _dateController.text.trim(),
      'time': _timeController.text.trim(),
      'publishImmediately': _publishImmediately,
      'isPublic': _isPublic,
      'tags': _tags,
      'lastSavedAt': now.toIso8601String(),
      'published': publish,
    };
    await prefs.setString(_prefsDraftKey, jsonEncode(payload));

    if (!mounted) return;
    setState(() {
      _lastSavedAt = now;
      _hasUnsavedChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(publish ? 'Article saved and queued for publishing.' : 'Draft saved.')),
    );
  }

  void _toggleVisibility(bool isPublic) {
    setState(() {
      _isPublic = isPublic;
      _hasUnsavedChanges = true;
    });
  }

  void _togglePublishImmediately(bool value) {
    setState(() {
      _publishImmediately = value;
      _hasUnsavedChanges = true;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList(growable: false);
      _hasUnsavedChanges = true;
    });
  }

  void _addTag() {
    final base = 'New Tag';
    var next = base;
    var i = 1;
    while (_tags.contains(next)) {
      i += 1;
      next = '$base $i';
    }
    setState(() {
      _tags = [..._tags, next];
      _hasUnsavedChanges = true;
    });
  }

  void _toggleMainSidebar() {
    setState(() {
      _isMainSidebarCollapsed = !_isMainSidebarCollapsed;
    });
  }

  void _toggleContentLibrary() {
    setState(() {
      _isContentLibraryCollapsed = !_isContentLibraryCollapsed;
    });
  }

  String get _saveStatusText {
    if (_hasUnsavedChanges) return 'Unsaved changes';
    final savedAt = _lastSavedAt;
    if (savedAt == null) return 'Not saved yet';
    final hh = savedAt.hour.toString().padLeft(2, '0');
    final mm = savedAt.minute.toString().padLeft(2, '0');
    return 'Saved at $hh:$mm';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quoteController.dispose();
    _introController.dispose();
    _sectionTitleController.dispose();
    _sectionBodyController.dispose();
    _bulletsController.dispose();
    _continueController.dispose();
    _summaryController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final canShowLibrary = width >= 1100;
    final showRightRail = width >= 1380;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Row(
          children: [
            _LeftSidebar(
              isCollapsed: _isMainSidebarCollapsed,
              onToggleCollapse: _toggleMainSidebar,
            ),
            if (canShowLibrary)
              _ContentLibrary(
                isCollapsed: _isContentLibraryCollapsed,
                onToggleCollapse: _toggleContentLibrary,
                draftTitle: _titleController.text.trim().isEmpty ? 'Untitled draft' : _titleController.text.trim(),
                draftSubtitle: _introController.text.trim().isEmpty
                    ? 'Start writing to see a live preview here...'
                    : _introController.text.trim(),
              ),
            Expanded(
              child: _EditorPanel(
                saveStatusText: _saveStatusText,
                titleController: _titleController,
                quoteController: _quoteController,
                introController: _introController,
                sectionTitleController: _sectionTitleController,
                sectionBodyController: _sectionBodyController,
                bulletsController: _bulletsController,
                continueController: _continueController,
              ),
            ),
            if (showRightRail)
              _PublishingRail(
                tags: _tags,
                summaryController: _summaryController,
                publishImmediately: _publishImmediately,
                onPublishImmediatelyChanged: _togglePublishImmediately,
                dateController: _dateController,
                timeController: _timeController,
                isPublic: _isPublic,
                onVisibilityChanged: _toggleVisibility,
                onDeleteTag: _removeTag,
                onAddTag: _addTag,
                onPublish: () => _saveDraft(publish: true),
                onSaveDraft: () => _saveDraft(),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeftSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const _LeftSidebar({
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  String _displayName() {
    final user = FirebaseAuthManager().currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final email = user?.email ?? '';
    final local = email.contains('@') ? email.split('@').first : email;
    return local.isNotEmpty ? local : 'Guest';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  String? _safePhotoUrl() {
    final raw = FirebaseAuthManager().currentUser?.photoURL?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return raw;
  }

  bool _isAdmin() {
    return AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName();
    final photoUrl = _safePhotoUrl();
    final hasPhoto = photoUrl != null;
    final isAdmin = _isAdmin();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 96 : 260,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isCollapsed ? 12 : 24, 24, isCollapsed ? 12 : 16, 8),
            child: Row(
              children: [
                const _LogoGlyph(),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Therapii',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: onToggleCollapse,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  icon: Icon(
                    isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 10 : 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _SidebarGroup(
                    title: 'Main',
                    collapsed: isCollapsed,
                    items: [
                      _NavItemData(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const JournalAdminDashboardPage()),
                          );
                        },
                      ),
                      const _NavItemData(icon: Icons.article_outlined, label: 'Articles', active: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SidebarGroup(
                    title: 'People',
                    collapsed: isCollapsed,
                    items: [
                      _NavItemData(
                        icon: Icons.group_outlined,
                        label: 'Team',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const JournalAdminTeamPage()),
                          );
                        },
                      ),
                      _NavItemData(
                        icon: Icons.people_alt_outlined,
                        label: 'Patients',
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const JournalAdminPatientsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SidebarGroup(
                    title: 'System',
                    collapsed: isCollapsed,
                    items: const [
                      _NavItemData(icon: Icons.analytics_outlined, label: 'Analytics'),
                      _NavItemData(icon: Icons.settings_outlined, label: 'Settings'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: isCollapsed
                ? Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                _initials(name),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.logout, color: Color(0xFF64748B), size: 20),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                _initials(name),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text(
                                  'View Profile',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2B8CEE).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: const Color(0xFF2B8CEE).withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: Color(0xFF2B8CEE),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.logout, color: Color(0xFF64748B), size: 20),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogoGlyph extends StatelessWidget {
  const _LogoGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2B8CEE).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/therapii_logo_blue.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SidebarGroup extends StatelessWidget {
  final String title;
  final List<_NavItemData> items;
  final bool collapsed;
  const _SidebarGroup({
    required this.title,
    required this.items,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ...items.map((item) => _SidebarItem(item, collapsed: collapsed)),
      ],
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavItemData({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });
}

class _SidebarItem extends StatelessWidget {
  final _NavItemData item;
  final bool collapsed;
  const _SidebarItem(this.item, {this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    if (collapsed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Tooltip(
          message: item.label,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 44,
              child: Icon(
                item.icon,
                size: 20,
                color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: item.onTap,
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          item.icon,
          size: 20,
          color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ContentLibrary extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final String draftTitle;
  final String draftSubtitle;
  const _ContentLibrary({
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.draftTitle,
    required this.draftSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 68 : 340,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: isCollapsed
          ? Column(
              children: [
                const SizedBox(height: 12),
                IconButton(
                  tooltip: 'Expand content library',
                  onPressed: onToggleCollapse,
                  icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.menu_book_rounded, color: Color(0xFF2B8CEE), size: 22),
                const SizedBox(height: 10),
                const RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Content Library',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Collapse content library',
                            onPressed: onToggleCollapse,
                            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add, color: Color(0xFF2B8CEE)),
                          ),
                        ],
                      ),
                      TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          hintText: 'Search articles...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          _LibraryTab(label: 'All', active: true),
                          _LibraryTab(label: 'Drafts'),
                          _LibraryTab(label: 'Published'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        _ArticleListItem(
                          status: 'Draft',
                          statusColor: Color(0xFFF59E0B),
                          title: draftTitle,
                          subtitle: draftSubtitle,
                          author: 'Dr. Emily Stone',
                          age: 'Just now',
                          highlighted: true,
                        ),
                        const _ArticleListItem(
                          status: 'Published',
                          statusColor: Color(0xFF10B981),
                          title: '5 Steps to Better Sleep Hygiene',
                          subtitle: 'Addressing insomnia through behavioral...',
                          author: 'Dr. Mark Chen',
                          age: '2d ago',
                        ),
                        const _ArticleListItem(
                          status: 'Published',
                          statusColor: Color(0xFF10B981),
                          title: 'Understanding CBT Core Principles',
                          subtitle: 'A guide for new therapy patients...',
                          author: 'Dr. Admin Portal',
                          age: '5d ago',
                        ),
                        const _ArticleListItem(
                          status: 'Scheduled',
                          statusColor: Color(0xFF64748B),
                          title: 'Managing Workplace Anxiety',
                          subtitle: 'Strategies for high-stress environments...',
                          author: 'Dr. Emily Stone',
                          age: 'Nov 14',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LibraryTab extends StatelessWidget {
  final String label;
  final bool active;
  const _LibraryTab({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF111418) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF111418) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  final String status;
  final Color statusColor;
  final String title;
  final String subtitle;
  final String author;
  final String age;
  final bool highlighted;

  const _ArticleListItem({
    required this.status,
    required this.statusColor,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.age,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEEF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlighted ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
              const Spacer(),
              Text(age, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(radius: 9, backgroundColor: Color(0xFFE2E8F0)),
              const SizedBox(width: 6),
              Text(author, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final String saveStatusText;
  final TextEditingController titleController;
  final TextEditingController quoteController;
  final TextEditingController introController;
  final TextEditingController sectionTitleController;
  final TextEditingController sectionBodyController;
  final TextEditingController bulletsController;
  final TextEditingController continueController;
  const _EditorPanel({
    required this.saveStatusText,
    required this.titleController,
    required this.quoteController,
    required this.introController,
    required this.sectionTitleController,
    required this.sectionBodyController,
    required this.bulletsController,
    required this.continueController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Dashboard > Articles > Editing: Building Resilience...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                saveStatusText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2632),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _ToolbarIcon(Icons.format_bold),
                          _ToolbarIcon(Icons.format_italic),
                          _ToolbarIcon(Icons.link),
                          _ToolbarDivider(),
                          _ToolbarIcon(Icons.title),
                          _ToolbarIcon(Icons.format_quote),
                          _ToolbarIcon(Icons.format_list_bulleted),
                          _ToolbarDivider(),
                          _ToolbarIcon(Icons.add_photo_alternate_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Article Title',
                            ),
                            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, height: 1.1),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: quoteController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(border: InputBorder.none),
                            style: const TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: introController,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(border: InputBorder.none),
                            style: const TextStyle(fontSize: 18, height: 1.8),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: sectionTitleController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(border: InputBorder.none),
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sectionBodyController,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(border: InputBorder.none),
                            style: const TextStyle(fontSize: 18, height: 1.8),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: bulletsController,
                            minLines: 3,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter one line per bullet point',
                            ),
                            style: const TextStyle(fontSize: 17, height: 1.8),
                          ),
                          const SizedBox(height: 20),
                          _ContinueBlock(controller: continueController),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  const _ToolbarIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, size: 20, color: Colors.white),
      splashRadius: 18,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class _ContinueBlock extends StatelessWidget {
  final TextEditingController controller;
  const _ContinueBlock({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 8,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: "Continue writing or type '/' for commands",
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PublishingRail extends StatelessWidget {
  final List<String> tags;
  final TextEditingController summaryController;
  final bool publishImmediately;
  final ValueChanged<bool> onPublishImmediatelyChanged;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onDeleteTag;
  final VoidCallback onAddTag;
  final Future<void> Function() onPublish;
  final Future<void> Function() onSaveDraft;
  const _PublishingRail({
    required this.tags,
    required this.summaryController,
    required this.publishImmediately,
    required this.onPublishImmediatelyChanged,
    required this.dateController,
    required this.timeController,
    required this.isPublic,
    required this.onVisibilityChanged,
    required this.onDeleteTag,
    required this.onAddTag,
    required this.onPublish,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publishing Intelligence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure AI tags and scheduling.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('AI Personalization Tags'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tags.map((tag) => _TagChip(label: tag, onRemove: () => onDeleteTag(tag))),
                      _AddChip(onTap: onAddTag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _PanelTitle('Summary / Meta Description'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: summaryController,
                    minLines: 4,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter a brief summary for search results...',
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PanelTitle('Publishing Schedule'),
                  const SizedBox(height: 8),
                  _ScheduleCard(
                    publishImmediately: publishImmediately,
                    onPublishImmediatelyChanged: onPublishImmediatelyChanged,
                    dateController: dateController,
                    timeController: timeController,
                  ),
                  const SizedBox(height: 20),
                  const _PanelTitle('Visibility'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _VisibilityButton(
                          label: 'Public',
                          icon: Icons.public,
                          active: isPublic,
                          onTap: () => onVisibilityChanged(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _VisibilityButton(
                          label: 'Private',
                          icon: Icons.lock_outline,
                          active: !isPublic,
                          onTap: () => onVisibilityChanged(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPublish,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF2B8CEE),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Publish Now', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSaveDraft,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save as Draft', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;
  const _PanelTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF1D4ED8)),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text('Add Tag', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final bool publishImmediately;
  final ValueChanged<bool> onPublishImmediatelyChanged;
  final TextEditingController dateController;
  final TextEditingController timeController;
  const _ScheduleCard({
    required this.publishImmediately,
    required this.onPublishImmediatelyChanged,
    required this.dateController,
    required this.timeController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Publish Immediately',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ),
              Switch(value: publishImmediately, onChanged: onPublishImmediatelyChanged),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: dateController,
            enabled: !publishImmediately,
            decoration: const InputDecoration(
              labelText: 'Date',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: timeController,
            enabled: !publishImmediately,
            decoration: const InputDecoration(
              labelText: 'Time',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _VisibilityButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
