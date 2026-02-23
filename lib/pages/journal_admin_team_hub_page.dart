import 'package:flutter/material.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminTeamHubPage extends StatelessWidget {
  const JournalAdminTeamHubPage({super.key});

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
        return;
      case JournalAdminSidebarItem.patients:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminPatientsHubPage()),
        );
        break;
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
              activeItem: JournalAdminSidebarItem.team,
              onNavigate: (item) => _onSidebarNavigate(context, item),
            ),
            const Expanded(child: _TeamHubContent()),
          ],
        ),
      ),
    );
  }
}

class _TeamHubContent extends StatelessWidget {
  const _TeamHubContent();

  static const _rows = <_TeamRowData>[
    _TeamRowData(
      name: 'Dr. Sarah Stone',
      email: 'sarah.stone@mindful.ai',
      avatarBg: Color(0xFFF3F4EE),
      role: 'Senior Therapist',
      roleBg: Color(0xFFEAF2FF),
      roleFg: Color(0xFF4B8EED),
      status: 'Online',
      statusBg: Color(0xFFE9F9F2),
      statusFg: Color(0xFF10B981),
      assignmentMain: '14 Patients',
      assignmentSub: '8 Active Articles',
      lastLogin: 'Just now',
    ),
    _TeamRowData(
      name: 'Marcus J.',
      email: 'm.jordan@mindful.ai',
      avatarBg: Color(0xFFF3F4F6),
      role: 'Content Editor',
      roleBg: Color(0xFFF2E9FF),
      roleFg: Color(0xFFA855F7),
      status: 'Away',
      statusBg: Color(0xFFFFF3E2),
      statusFg: Color(0xFFF59E0B),
      assignmentMain: '24 Articles',
      assignmentSub: 'Drafting Stage',
      lastLogin: '42 mins ago',
    ),
    _TeamRowData(
      name: 'Dr. Michael Chen',
      email: 'm.chen@mindful.ai',
      avatarBg: Color(0xFFEAF6DE),
      role: 'Therapist',
      roleBg: Color(0xFFEAF2FF),
      roleFg: Color(0xFF4B8EED),
      status: 'Offline',
      statusBg: Color(0xFFF1F5F9),
      statusFg: Color(0xFF94A3B8),
      assignmentMain: '8 Patients',
      assignmentSub: '0 New Requests',
      lastLogin: '3 days ago',
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
              const _TeamHeader(),
              const SizedBox(height: 20),
              const _SearchAndFiltersBar(),
              const SizedBox(height: 20),
              _TeamTable(rows: _rows),
              const SizedBox(height: 20),
              const _TeamSummaryRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader();

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
                color: const Color(0xFFEAF9F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCDEFE2)),
              ),
              child: const Text(
                '8 ACTIVE TODAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22A37A),
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
                'Invite New Member',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );

        final titleBlock = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Team Management Hub',
              style: TextStyle(
                fontSize: 31 / 2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111418),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your specialized therapeutic team and roles',
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
                hintText: 'Search by name, role or email...',
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
                    filterChip('All Roles'),
                    filterChip('All Statuses'),
                    filterChip('Filters', withArrow: false, leading: Icons.tune_rounded),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              filterChip('All Roles'),
              const SizedBox(width: 10),
              filterChip('All Statuses'),
              const SizedBox(width: 10),
              filterChip('Filters', withArrow: false, leading: Icons.tune_rounded),
            ],
          );
        },
      ),
    );
  }
}

class _TeamTable extends StatelessWidget {
  final List<_TeamRowData> rows;

  const _TeamTable({required this.rows});

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
                        _HeadCell('MEMBER', flex: 30),
                        _HeadCell('ROLE', flex: 16),
                        _HeadCell('STATUS', flex: 14),
                        _HeadCell('ASSIGNMENTS', flex: 16),
                        _HeadCell('LAST LOGIN', flex: 14),
                        _HeadCell('QUICK ACTIONS', flex: 10),
                      ],
                    ),
                  ),
                  ...rows.map((row) => _TeamDataRow(data: row)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE8EDF4))),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'SHOWING 1-10 OF 12 TEAM MEMBERS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFFCBD5E1)),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B8CEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '2',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
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
}

class _HeadCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeadCell(this.label, {required this.flex});

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
        ),
      ),
    );
  }
}

class _TeamDataRow extends StatelessWidget {
  final _TeamRowData data;

  const _TeamDataRow({required this.data});

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
            flex: 30,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: data.avatarBg,
                  child: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
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
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: _badge(data.role, data.roleBg, data.roleFg),
          ),
          Expanded(
            flex: 14,
            child: _status(data.status, data.statusBg, data.statusFg),
          ),
          Expanded(
            flex: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.assignmentMain,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.assignmentSub,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              data.lastLogin,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Expanded(
            flex: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.playlist_add_check_rounded, size: 20, color: Color(0xFF94A3B8)),
                Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF94A3B8)),
                Icon(Icons.person_2_outlined, size: 20, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _status(String label, Color bg, Color fg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRowData {
  final String name;
  final String email;
  final Color avatarBg;
  final String role;
  final Color roleBg;
  final Color roleFg;
  final String status;
  final Color statusBg;
  final Color statusFg;
  final String assignmentMain;
  final String assignmentSub;
  final String lastLogin;

  const _TeamRowData({
    required this.name,
    required this.email,
    required this.avatarBg,
    required this.role,
    required this.roleBg,
    required this.roleFg,
    required this.status,
    required this.statusBg,
    required this.statusFg,
    required this.assignmentMain,
    required this.assignmentSub,
    required this.lastLogin,
  });
}

class _TeamSummaryRow extends StatelessWidget {
  const _TeamSummaryRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final cards = const [
          _SummaryCard(
            icon: Icons.groups_2_rounded,
            title: 'TOTAL TEAM MEMBERS',
            value: '12 Professionals',
            tint: Color(0xFFEAF2FF),
            iconColor: Color(0xFF2B8CEE),
          ),
          _SummaryCard(
            icon: Icons.speed_rounded,
            title: 'AVG. RESPONSE TIME',
            value: '4.2 Minutes',
            tint: Color(0xFFEBF9F3),
            iconColor: Color(0xFF10B981),
          ),
          _SummaryCard(
            icon: Icons.verified_rounded,
            title: 'ACTIVE TODAY',
            value: '8 Online Now',
            tint: Color(0xFFF3EDFF),
            iconColor: Color(0xFFA855F7),
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
