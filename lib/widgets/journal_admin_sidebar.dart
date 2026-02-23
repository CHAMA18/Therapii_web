import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/utils/admin_access.dart';

enum JournalAdminSidebarItem {
  dashboard,
  articles,
  team,
  patients,
  analytics,
  settings,
}

class JournalAdminSidebar extends StatefulWidget {
  final JournalAdminSidebarItem activeItem;
  final ValueChanged<JournalAdminSidebarItem> onNavigate;

  const JournalAdminSidebar({
    super.key,
    required this.activeItem,
    required this.onNavigate,
  });

  @override
  State<JournalAdminSidebar> createState() => _JournalAdminSidebarState();
}

class _JournalAdminSidebarState extends State<JournalAdminSidebar> {
  static bool _persistedCollapsed = false;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = _persistedCollapsed;
  }

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

  void _handleNavigate(JournalAdminSidebarItem item) {
    if (item == widget.activeItem) return;
    widget.onNavigate(item);
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
      width: _isCollapsed ? 96 : 260,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_isCollapsed ? 12 : 24, 24, _isCollapsed ? 12 : 16, 8),
            child: Row(
              children: [
                const _LogoGlyph(),
                if (!_isCollapsed) ...[
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
                  tooltip: _isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                      _persistedCollapsed = _isCollapsed;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  icon: Icon(
                    _isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 10 : 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _SidebarGroup(
                    title: 'Main',
                    collapsed: _isCollapsed,
                    items: [
                      _SidebarNavItemData(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        active: widget.activeItem == JournalAdminSidebarItem.dashboard,
                        onTap: () => _handleNavigate(JournalAdminSidebarItem.dashboard),
                      ),
                      _SidebarNavItemData(
                        icon: Icons.article_outlined,
                        label: 'Articles',
                        active: widget.activeItem == JournalAdminSidebarItem.articles,
                        onTap: () => _handleNavigate(JournalAdminSidebarItem.articles),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SidebarGroup(
                    title: 'People',
                    collapsed: _isCollapsed,
                    items: [
                      _SidebarNavItemData(
                        icon: Icons.group_outlined,
                        label: 'Team',
                        active: widget.activeItem == JournalAdminSidebarItem.team,
                        onTap: () => _handleNavigate(JournalAdminSidebarItem.team),
                      ),
                      _SidebarNavItemData(
                        icon: Icons.people_alt_outlined,
                        label: 'Patients',
                        active: widget.activeItem == JournalAdminSidebarItem.patients,
                        onTap: () => _handleNavigate(JournalAdminSidebarItem.patients),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SidebarGroup(
                    title: 'System',
                    collapsed: _isCollapsed,
                    items: [
                      _SidebarNavItemData(
                        icon: Icons.analytics_outlined,
                        label: 'Analytics',
                        active: widget.activeItem == JournalAdminSidebarItem.analytics,
                        onTap: () => _handleNavigate(JournalAdminSidebarItem.analytics),
                      ),
                      _SidebarNavItemData(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        active: widget.activeItem == JournalAdminSidebarItem.settings,
                        onTap: () => _handleNavigate(JournalAdminSidebarItem.settings),
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
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: _isCollapsed
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
                        onPressed: () => Navigator.of(context).maybePop(),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                        onPressed: () => Navigator.of(context).maybePop(),
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
  final List<_SidebarNavItemData> items;
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
        ...items.map((item) => _SidebarNavItem(item, collapsed: collapsed)),
      ],
    );
  }
}

class _SidebarNavItemData {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _SidebarNavItemData({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });
}

class _SidebarNavItem extends StatelessWidget {
  final _SidebarNavItemData item;
  final bool collapsed;

  const _SidebarNavItem(this.item, {this.collapsed = false});

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
