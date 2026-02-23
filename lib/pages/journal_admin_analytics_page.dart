import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminAnalyticsPage extends StatelessWidget {
  const JournalAdminAnalyticsPage({super.key});

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminPatientsHubPage()),
        );
        break;
      case JournalAdminSidebarItem.analytics:
        return;
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
              activeItem: JournalAdminSidebarItem.analytics,
              onNavigate: (item) => _onSidebarNavigate(context, item),
            ),
            const Expanded(child: _AnalyticsContent()),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSidebar extends StatelessWidget {
  const _AnalyticsSidebar();

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
                  _SidebarItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Patients',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const JournalAdminPatientsHubPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const _SidebarSectionTitle('Insights'),
                  const _SidebarItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    active: true,
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

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AnalyticsHeader(),
          SizedBox(height: 16),
          _SentimentTrendsCard(),
          SizedBox(height: 16),
          _MiddleInsightsRow(),
          SizedBox(height: 16),
          _ClinicalOutcomesCard(),
        ],
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader();

  @override
  Widget build(BuildContext context) {
    final dateRange = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Text(
            'Jan 1, 2024 - Jan 30, 2024',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );

    final exportButton = FilledButton.icon(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2B8CEE),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
      icon: const Icon(Icons.download_rounded, size: 16),
      label: const Text(
        'Export Report',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleBlock = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights & Reporting',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111418),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Advanced system-wide therapeutic performance metrics',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 980) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  dateRange,
                  exportButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            dateRange,
            const SizedBox(width: 10),
            exportButton,
          ],
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SentimentTrendsCard extends StatelessWidget {
  const _SentimentTrendsCard();

  @override
  Widget build(BuildContext context) {
    return const _CardShell(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emotional Sentiment Trends',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111418),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Aggregate patient mood trajectories over time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _LegendDot(label: 'STABILITY', color: Color(0xFF2B8CEE)),
              SizedBox(width: 10),
              _LegendDot(label: 'JOY', color: Color(0xFF32C79A)),
              SizedBox(width: 10),
              _LegendDot(label: 'ANXIETY', color: Color(0xFFF26F86)),
            ],
          ),
          SizedBox(height: 14),
          _SentimentTrendChart(),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _SentimentTrendChart extends StatelessWidget {
  const _SentimentTrendChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _SentimentChartPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(child: _AxisLabel('WEEK 1')),
                Expanded(child: _AxisLabel('WEEK 2')),
                Expanded(child: _AxisLabel('WEEK 3')),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _AxisLabel('WEEK 4'),
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

class _AxisLabel extends StatelessWidget {
  final String text;
  const _AxisLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class _SentimentChartPainter extends CustomPainter {
  static const _gridColor = Color(0xFFE6EBF2);
  static const _stabilityColor = Color(0xFF2B8CEE);
  static const _joyColor = Color(0xFF32C79A);
  static const _anxietyColor = Color(0xFFF26F86);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _gridColor
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _paintSeries(
      canvas: canvas,
      size: size,
      values: const [0.84, 0.56, 0.66, 0.34],
      color: _stabilityColor,
      stroke: 5,
    );
    _paintSeries(
      canvas: canvas,
      size: size,
      values: const [0.62, 0.54, 0.44, 0.34],
      color: _joyColor,
      stroke: 4,
    );
    _paintSeries(
      canvas: canvas,
      size: size,
      values: const [0.46, 0.56, 0.86, 0.78],
      color: _anxietyColor,
      stroke: 4,
    );
  }

  void _paintSeries({
    required Canvas canvas,
    required Size size,
    required List<double> values,
    required Color color,
    required double stroke,
  }) {
    if (values.length < 2) return;
    final points = List<Offset>.generate(values.length, (index) {
      final x = size.width * (index / (values.length - 1));
      final y = size.height * values[index].clamp(0.0, 1.0);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = (p1.dx + p2.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiddleInsightsRow extends StatelessWidget {
  const _MiddleInsightsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1050) {
          return const Column(
            children: [
              _JournalingEngagementCard(),
              SizedBox(height: 16),
              _MostDiscussedThemesCard(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _JournalingEngagementCard()),
            SizedBox(width: 16),
            Expanded(flex: 2, child: _MostDiscussedThemesCard()),
          ],
        );
      },
    );
  }
}

class _JournalingEngagementCard extends StatelessWidget {
  const _JournalingEngagementCard();

  @override
  Widget build(BuildContext context) {
    const bars = <double>[0.14, 0.24, 0.62, 0.70, 0.50, 0.27, 0.18, 0.40, 0.47, 0.36, 0.21, 0.09];
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journaling Engagement',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111418),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Peak times of user activity across the day',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1A2B8CEE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'HIGH VOLUME',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF2B8CEE),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 165,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (index) {
                final isPrimaryPeak = index >= 2 && index <= 4;
                final isSecondaryPeak = index >= 7 && index <= 9;
                final color = isPrimaryPeak
                    ? const Color(0xFF2B8CEE)
                    : isSecondaryPeak
                    ? const Color(0xFF8CB8E8)
                    : const Color(0xFFE7EDF5);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 150 * bars[index],
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _TimeTick('00:00'),
              Spacer(),
              _TimeTick('04:00'),
              Spacer(),
              _TimeTick('08:00'),
              Spacer(),
              _TimeTick('12:00'),
              Spacer(),
              _TimeTick('16:00'),
              Spacer(),
              _TimeTick('20:00'),
              Spacer(),
              _TimeTick('23:59'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeTick extends StatelessWidget {
  final String label;
  const _TimeTick(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9.5,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MostDiscussedThemesCard extends StatelessWidget {
  const _MostDiscussedThemesCard();

  @override
  Widget build(BuildContext context) {
    const chips = [
      _ThemeChipData('Relationships (42%)', Color(0xFFE8F3FF), Color(0xFF2B8CEE)),
      _ThemeChipData('Career Growth (18%)', Color(0xFFE6F8F2), Color(0xFF22A37A)),
      _ThemeChipData('Self-Esteem (15%)', Color(0xFFFFF4E8), Color(0xFFDD8B18)),
      _ThemeChipData('Social Anxiety', Color(0xFFFFECF2), Color(0xFFE34978)),
      _ThemeChipData('Mindfulness', Color(0xFFF3EDFF), Color(0xFF7E50E9)),
      _ThemeChipData('Sleep Quality', Color(0xFFF3F6FB), Color(0xFF5C7DA3)),
      _ThemeChipData('Grief', Color(0xFFE9EDFF), Color(0xFF5A67D8)),
    ];

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Discussed Themes',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Primary journaling topics this month',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map((chip) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: chip.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chip.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: chip.textColor,
                        ),
                      ),
                    ))
                .toList(growable: false),
          ),
          const SizedBox(height: 22),
          const Center(
            child: _TopicDonut(),
          ),
        ],
      ),
    );
  }
}

class _ThemeChipData {
  final String label;
  final Color background;
  final Color textColor;
  const _ThemeChipData(this.label, this.background, this.textColor);
}

class _TopicDonut extends StatelessWidget {
  const _TopicDonut();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      height: 122,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(122),
            painter: _DonutPainter(),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '12',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111418),
                ),
              ),
              Text(
                'TOPICS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final stroke = size.width * 0.12;
    final segments = [
      (const Color(0xFF2B8CEE), 0.44),
      (const Color(0xFF32C79A), 0.20),
      (const Color(0xFFE6EBF2), 0.36),
    ];

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = math.pi * 2 * segment.$2;
      final paint = Paint()
        ..color = segment.$1
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClinicalOutcomesCard extends StatelessWidget {
  const _ClinicalOutcomesCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Outcomes',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111418),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Comparative pre- and post-therapy assessment scores',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const _MetricPill(label: 'PHQ-9', active: true),
              const SizedBox(width: 6),
              const _MetricPill(label: 'GAD-7'),
              const SizedBox(width: 6),
              const _MetricPill(label: 'DASS-21'),
            ],
          ),
          const SizedBox(height: 18),
          const _OutcomeRow(
            label: 'Emotional Regulation Index',
            progress: 0.78,
            color: Color(0xFF4D95E6),
            pre: '4.2',
            post: '7.8',
          ),
          const SizedBox(height: 14),
          const _OutcomeRow(
            label: 'Interpersonal Effectiveness',
            progress: 0.64,
            color: Color(0xFF4CC197),
            pre: '3.1',
            post: '6.4',
          ),
          const SizedBox(height: 14),
          const _OutcomeRow(
            label: 'Anxiety Management Score',
            progress: 0.81,
            color: Color(0xFF7473E9),
            pre: '2.8',
            post: '8.1',
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final bool active;

  const _MetricPill({
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x1A2B8CEE) : const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final String pre;
  final String post;

  const _OutcomeRow({
    required this.label,
    required this.progress,
    required this.color,
    required this.pre,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            Text(
              'PRE: $pre',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'POST: $post',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: progress.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE9EEF6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
