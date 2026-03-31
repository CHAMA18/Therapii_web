import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/billing_page.dart' as therapii_billing;
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/services/app_page_state_service.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminSettingsPage extends StatefulWidget {
  const JournalAdminSettingsPage({super.key});

  @override
  State<JournalAdminSettingsPage> createState() =>
      _JournalAdminSettingsPageState();
}

class _JournalAdminSettingsPageState extends State<JournalAdminSettingsPage> {
  final TextEditingController _orgNameController =
      TextEditingController(text: 'Mindful Health Group');
  String _selectedTimezone = 'Pacific Time (PT) - US & Canada';
  String _selectedTab = 'General';

  static const _tabs = ['General', 'Security', 'Notifications', 'Billing'];
  static const _timezones = [
    'Pacific Time (PT) - US & Canada',
    'Mountain Time (MT) - US & Canada',
    'Central Time (CT) - US & Canada',
    'Eastern Time (ET) - US & Canada',
  ];

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  void _onSidebarNavigate(JournalAdminSidebarItem item) {
    switch (item) {
      case JournalAdminSidebarItem.dashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminDashboardPage()),
        );
        break;
      case JournalAdminSidebarItem.articles:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminStudioPage()),
        );
        break;
      case JournalAdminSidebarItem.team:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminTeamHubPage()),
        );
        break;
      case JournalAdminSidebarItem.patients:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const JournalAdminPatientsHubPage()),
        );
        break;
      case JournalAdminSidebarItem.analytics:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminAnalyticsPage()),
        );
        break;
      case JournalAdminSidebarItem.settings:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RememberAppPage(
      pageId: AppPageId.journalAdminSettings,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: Row(
            children: [
              JournalAdminSidebar(
                activeItem: JournalAdminSidebarItem.settings,
                onNavigate: _onSidebarNavigate,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildTabs(),
                          const SizedBox(height: 28),
                          const _SectionHeader(
                            title: 'Organization Profile',
                            subtitle:
                                'Update your organization\'s basic information and regional settings.',
                          ),
                          const SizedBox(height: 14),
                          _buildOrganizationCard(),
                          const SizedBox(height: 38),
                          _buildFooterActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Settings',
                style: TextStyle(
                  fontSize: 34 / 2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111418),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Configure your workspace and system preferences',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2B8CEE),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 0,
        children: _tabs
            .map((tab) => _SettingsTab(
                  label: tab,
                  active: _selectedTab == tab,
                  onTap: () {
                    if (tab == 'Billing') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const therapii_billing.BillingPage()),
                      );
                    } else {
                      setState(() => _selectedTab = tab);
                    }
                  },
                ))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildOrganizationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _orgNameField()),
                    const SizedBox(width: 20),
                    Expanded(child: _timezoneField()),
                  ],
                )
              else ...[
                _orgNameField(),
                const SizedBox(height: 18),
                _timezoneField(),
              ],
              const SizedBox(height: 18),
              const _SettingsFieldLabel('ORGANIZATION LOGO'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFCFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFD5DFEC),
                          style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.image_outlined,
                        size: 20, color: Color(0xFF9CA3AF)),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFD8E1EE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    child: const Text('Upload New',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444)),
                    child: const Text('Remove',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'JPG, PNG or SVG. Max size 2MB. Recommended 256x256px.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orgNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFieldLabel('ORGANIZATION NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: _orgNameController,
          decoration: _fieldDecoration(),
        ),
      ],
    );
  }

  Widget _timezoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFieldLabel('DEFAULT TIMEZONE'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTimezone,
          decoration: _fieldDecoration(),
          items: _timezones
              .map(
                (tz) => DropdownMenuItem<String>(
                  value: tz,
                  child: Text(
                    tz,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedTimezone = value);
          },
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9E2EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9E2EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B8CEE)),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Discard Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B8CEE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            ),
            child: const Text(
              'Save System Settings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30 / 2,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _SettingsFieldLabel extends StatelessWidget {
  final String text;

  const _SettingsFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SettingsTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF2B8CEE) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar();

  String _displayName() {
    final user = FirebaseAuthManager().currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final email = user?.email ?? '';
    final local = email.contains('@') ? email.split('@').first : email;
    return local.isNotEmpty ? local : 'Dr. Admin';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'DA';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final name = _displayName();
    final photoUrl = _safePhotoUrl();
    final hasPhoto = photoUrl != null;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
        border: Border(right: BorderSide(color: Color(0xFFE6EBF2))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B8CEE).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.self_improvement_rounded,
                      color: Color(0xFF2B8CEE), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'MindfulAdmin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111418),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SidebarSectionTitle('Overview'),
                  _SidebarItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const JournalAdminDashboardPage()),
                      );
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.article_outlined,
                    label: 'Articles',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const JournalAdminStudioPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const _SidebarSectionTitle('People'),
                  _SidebarItem(
                    icon: Icons.group_outlined,
                    label: 'Team',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const JournalAdminTeamHubPage()),
                      );
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Patients',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) =>
                                const JournalAdminPatientsHubPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const _SidebarSectionTitle('Insights'),
                  _SidebarItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const JournalAdminAnalyticsPage()),
                      );
                    },
                  ),
                  const _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    active: true,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFE6EBF2))),
            ),
            child: Row(
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111418),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Health Director',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF617589),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFF64748B), size: 20),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  final String label;
  const _SidebarSectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0x1A2B8CEE) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          size: 20,
          color: active ? const Color(0xFF2B8CEE) : const Color(0xFF617589),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF2B8CEE) : const Color(0xFF617589),
          ),
        ),
      ),
    );
  }
}
