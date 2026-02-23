import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminPatientsHubPage extends StatelessWidget {
  const JournalAdminPatientsHubPage({super.key});

  void _onSidebarNavigate(BuildContext context, JournalAdminSidebarItem item) {
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
        return;
      case JournalAdminSidebarItem.analytics:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminAnalyticsPage()),
        );
        break;
      case JournalAdminSidebarItem.settings:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminSettingsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Row(
          children: [
            JournalAdminSidebar(
              activeItem: JournalAdminSidebarItem.patients,
              onNavigate: (item) => _onSidebarNavigate(context, item),
            ),
            const Expanded(child: _PatientsHubContent()),
          ],
        ),
      ),
    );
  }
}

class _PatientsHubContent extends StatelessWidget {
  const _PatientsHubContent();

  static const _rows = <_PatientRowData>[
    _PatientRowData(
      name: 'Elena Richardson',
      statusLabel: 'Active',
      statusBg: Color(0xFFE7FAF2),
      statusFg: Color(0xFF16A34A),
      id: 'PA-\n88219',
      therapist: 'Dr. Sarah\nStone',
      therapistTone: Color(0xFFE5E7EB),
      sentiment: 'Positive',
      sentimentColor: Color(0xFF10B981),
      activity: 'Journaling\nComplete',
      activityMeta: 'Today, 10:24 AM',
      avatarColor: Color(0xFFE7F0FF),
    ),
    _PatientRowData(
      name: 'Julian Thorne',
      statusLabel: 'At Risk',
      statusBg: Color(0xFFFFE9EE),
      statusFg: Color(0xFFEF476F),
      id: 'PA-\n44910',
      therapist: 'Dr. Michael\nChen',
      therapistTone: Color(0xFFE8F3D8),
      sentiment: 'Critical',
      sentimentColor: Color(0xFFEF476F),
      activity: 'Flagged\nContent',
      activityMeta: '2 hours ago',
      avatarColor: Color(0xFFF1F5F9),
      riskAction: true,
    ),
    _PatientRowData(
      name: 'Marcus J. (Test Account)',
      statusLabel: 'Onboarding',
      statusBg: Color(0xFFEAF2FF),
      statusFg: Color(0xFF4F8CEB),
      id: 'PA-\n10292',
      therapist: 'Pending\nAssignment',
      therapistTone: Color(0xFFF3F4F6),
      sentiment: 'Neutral',
      sentimentColor: Color(0xFFCBD5E1),
      activity: 'Account\nCreated',
      activityMeta: 'Yesterday, 4:15 PM',
      avatarColor: Color(0xFFE5D9C5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PatientsHeader(),
              const SizedBox(height: 20),
              const _SearchAndFiltersBar(),
              const SizedBox(height: 20),
              _PatientsTable(rows: _rows),
              const SizedBox(height: 20),
              const _PatientsSummaryRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientsHeader extends StatelessWidget {
  const _PatientsHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD4DC)),
              ),
              child: const Text(
                '4 PATIENTS AT RISK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF476F),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2B8CEE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: const Text(
                'Add New Patient',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );

        final titleBlock = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Patients Management Hub',
              style: TextStyle(
                fontSize: 31 / 2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111418),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Oversee patient health status and AI sentiment tracking',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              actions,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            actions,
          ],
        );
      },
    );
  }
}

class _SearchAndFiltersBar extends StatelessWidget {
  const _SearchAndFiltersBar();

  @override
  Widget build(BuildContext context) {
    Widget filterChip(String text, {bool withArrow = true, IconData? leading}) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9E2EE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              Icon(leading, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            if (withArrow) ...[
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final searchField = Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD9E2EE)),
            ),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                hintText: 'Search patients by name, ID or therapist...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [
                searchField,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    filterChip('All Statuses'),
                    filterChip('All Therapists'),
                    filterChip('More Filters', withArrow: false, leading: Icons.tune_rounded),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              filterChip('All Statuses'),
              const SizedBox(width: 10),
              filterChip('All Therapists'),
              const SizedBox(width: 10),
              filterChip('More Filters', withArrow: false, leading: Icons.tune_rounded),
            ],
          );
        },
      ),
    );
  }
}

class _PatientsTable extends StatelessWidget {
  final List<_PatientRowData> rows;

  const _PatientsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 960.0;
          final tableWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        _TableHeadCell('PATIENT DETAILS', flex: 28),
                        _TableHeadCell('UNIQUE\nID', flex: 10),
                        _TableHeadCell('ASSIGNED\nTHERAPIST', flex: 16),
                        _TableHeadCell('AI\nSENTIMENT', flex: 12),
                        _TableHeadCell('LAST ACTIVITY', flex: 16),
                        _TableHeadCell('QUICK ACTIONS', flex: 12),
                      ],
                    ),
                  ),
                  ...rows.map((row) => _PatientDataRow(data: row)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE8EDF4))),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'SHOWING 1-10 OF 142 PATIENTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        _pagerIcon(Icons.chevron_left_rounded),
                        const SizedBox(width: 8),
                        _pagerNumber('1', active: true),
                        const SizedBox(width: 8),
                        _pagerNumber('2'),
                        const SizedBox(width: 8),
                        _pagerNumber('3'),
                        const SizedBox(width: 8),
                        _pagerIcon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pagerNumber(String value, {bool active = false}) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2B8CEE) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _pagerIcon(IconData icon) {
    return Icon(icon, size: 18, color: const Color(0xFF94A3B8));
  }
}

class _TableHeadCell extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeadCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          height: 1.3,
        ),
      ),
    );
  }
}

class _PatientDataRow extends StatelessWidget {
  final _PatientRowData data;

  const _PatientDataRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE8EDF4))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 28,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: data.avatarColor,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: data.name == 'Marcus J. (Test Account)' ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: data.statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          data.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: data.statusFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              data.id,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: data.therapistTone,
                  child: const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.therapist,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: data.therapist.contains('Pending') ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                      fontStyle: data.therapist.contains('Pending') ? FontStyle.italic : FontStyle.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: data.sentimentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  data.sentiment,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: data.sentiment == 'Neutral' ? const Color(0xFF94A3B8) : data.sentimentColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.activity,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.activityMeta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionIcon(Icons.account_circle_outlined),
                _actionIcon(data.riskAction ? Icons.priority_high_rounded : Icons.chat_bubble_outline_rounded,
                    color: data.riskAction ? const Color(0xFFEF476F) : const Color(0xFF64748B)),
                _actionIcon(Icons.show_chart_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, {Color color = const Color(0xFF94A3B8)}) {
    return Icon(icon, size: 21, color: color);
  }
}

class _PatientRowData {
  final String name;
  final String statusLabel;
  final Color statusBg;
  final Color statusFg;
  final String id;
  final String therapist;
  final Color therapistTone;
  final String sentiment;
  final Color sentimentColor;
  final String activity;
  final String activityMeta;
  final Color avatarColor;
  final bool riskAction;

  const _PatientRowData({
    required this.name,
    required this.statusLabel,
    required this.statusBg,
    required this.statusFg,
    required this.id,
    required this.therapist,
    required this.therapistTone,
    required this.sentiment,
    required this.sentimentColor,
    required this.activity,
    required this.activityMeta,
    required this.avatarColor,
    this.riskAction = false,
  });
}

class _PatientsSummaryRow extends StatelessWidget {
  const _PatientsSummaryRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final cards = const [
          _SummaryCard(
            icon: Icons.format_list_bulleted_rounded,
            title: 'TOTAL ACTIVE PATIENTS',
            value: '128 Patients',
            tint: Color(0xFFEAF2FF),
            iconColor: Color(0xFF2B8CEE),
          ),
          _SummaryCard(
            icon: Icons.warning_amber_rounded,
            title: 'AT RISK ALERTS',
            value: '4 Critical Cases',
            tint: Color(0xFFFFEEF1),
            iconColor: Color(0xFFEF476F),
          ),
          _SummaryCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'NEW PATIENTS THIS WEEK',
            value: '+18 Growth',
            tint: Color(0xFFEBF9F3),
            iconColor: Color(0xFF22C55E),
          ),
        ];

        if (compact) {
          return Column(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: card,
                    ))
                .toList(growable: false),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 35 / 2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
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

class _PatientsHubSidebar extends StatelessWidget {
  const _PatientsHubSidebar();

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
                  child: const Icon(Icons.self_improvement_rounded, color: Color(0xFF2B8CEE), size: 20),
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
                        MaterialPageRoute(builder: (_) => const JournalAdminDashboardPage()),
                      );
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.article_outlined,
                    label: 'Articles',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const JournalAdminStudioPage()),
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
                        MaterialPageRoute(builder: (_) => const JournalAdminTeamHubPage()),
                      );
                    },
                  ),
                  const _SidebarItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Patients',
                    active: true,
                  ),
                  const SizedBox(height: 16),
                  const _SidebarSectionTitle('Insights'),
                  _SidebarItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const JournalAdminAnalyticsPage()),
                      );
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const JournalAdminSettingsPage()),
                      );
                    },
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
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
