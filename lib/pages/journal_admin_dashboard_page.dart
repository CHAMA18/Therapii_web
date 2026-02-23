import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminDashboardPage extends StatelessWidget {
  const JournalAdminDashboardPage({super.key});

  void _onSidebarNavigate(BuildContext context, JournalAdminSidebarItem item) {
    switch (item) {
      case JournalAdminSidebarItem.dashboard:
        return;
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
              activeItem: JournalAdminSidebarItem.dashboard,
              onNavigate: (item) => _onSidebarNavigate(context, item),
            ),
            const Expanded(child: _DashboardContent()),
          ],
        ),
      ),
    );
  }
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar();

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
                    active: true,
                    onTap: () {},
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

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _therapistDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _userDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _conversationDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _summaryDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _sessionDocs;

  Object? _therapistsError;
  Object? _usersError;
  Object? _conversationsError;
  Object? _summariesError;
  Object? _sessionsError;

  late final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions;

  bool get _isLoading {
    return _therapistDocs == null ||
        _userDocs == null ||
        _conversationDocs == null ||
        _summaryDocs == null ||
        _sessionDocs == null;
  }

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      _firestore.collection('therapists').snapshots().listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            _therapistDocs = snapshot.docs;
            _therapistsError = null;
          });
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _therapistsError = error;
            _therapistDocs ??= <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          });
        },
      ),
      _firestore.collection('users').snapshots().listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            _userDocs = snapshot.docs;
            _usersError = null;
          });
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _usersError = error;
            _userDocs ??= <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          });
        },
      ),
      _firestore.collection('conversations').snapshots().listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            _conversationDocs = snapshot.docs;
            _conversationsError = null;
          });
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _conversationsError = error;
            _conversationDocs ??= <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          });
        },
      ),
      _firestore.collection('ai_conversation_summaries').snapshots().listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            _summaryDocs = snapshot.docs;
            _summariesError = null;
          });
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _summariesError = error;
            _summaryDocs ??= <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          });
        },
      ),
      _firestore.collection('therapy_sessions').snapshots().listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            _sessionDocs = snapshot.docs;
            _sessionsError = null;
          });
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _sessionsError = error;
            _sessionDocs ??= <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          });
        },
      ),
    ];
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final liveData = _buildLiveData();
    final errorCount = [
      _therapistsError,
      _usersError,
      _conversationsError,
      _summariesError,
      _sessionsError,
    ].whereType<Object>().length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xCCFFFFFF),
              border: Border(bottom: BorderSide(color: Color(0xFFE6EBF2))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'System Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111418),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Monitoring health & patient engagement in real-time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF617589),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const JournalAdminStudioPage()),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B8CEE),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  label: const Text('New Article'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorCount > 0) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      '$errorCount live data stream(s) failed. Remaining cards are still showing live data.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
                _MetricsGrid(cards: liveData.metricCards),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1120;
                    if (!wide) {
                      return Column(
                        children: [
                          _EngagementCard(
                            points: liveData.engagementPoints,
                            subtitle: liveData.engagementSubtitle,
                          ),
                          const SizedBox(height: 16),
                          _AlertsCard(alerts: liveData.alerts),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _EngagementCard(
                            points: liveData.engagementPoints,
                            subtitle: liveData.engagementSubtitle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _AlertsCard(alerts: liveData.alerts)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1120;
                    if (!wide) {
                      return Column(
                        children: [
                          _RecentArticlesCard(rows: liveData.recentSummaryRows),
                          const SizedBox(height: 16),
                          _UpcomingContentCard(rows: liveData.upcomingSessions),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _RecentArticlesCard(rows: liveData.recentSummaryRows)),
                        const SizedBox(width: 16),
                        Expanded(child: _UpcomingContentCard(rows: liveData.upcomingSessions)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _DashboardLiveData _buildLiveData() {
    final now = DateTime.now();
    final therapists = _therapistDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final users = _userDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final conversations = _conversationDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final summaries = _summaryDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final sessions = _sessionDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final userMapById = <String, Map<String, dynamic>>{
      for (final doc in users) doc.id: doc.data(),
    };

    final therapistNameById = <String, String>{};
    var pendingApprovals = 0;
    var staleTherapists = 0;
    for (final doc in therapists) {
      final data = doc.data();
      final approvalStatus = _toNonEmptyString(data['approval_status'])?.toLowerCase() ?? '';
      if (approvalStatus.isEmpty ||
          approvalStatus == 'pending' ||
          approvalStatus == 'resubmitted' ||
          approvalStatus == 'needs_review') {
        pendingApprovals++;
      }
      final updatedAt = _pickDate(data, const ['updated_at', 'approval_requested_at', 'created_at']);
      if (updatedAt != null && updatedAt.isBefore(now.subtract(const Duration(days: 14)))) {
        staleTherapists++;
      }
      final userId = _toNonEmptyString(data['user_id']) ?? doc.id;
      therapistNameById[doc.id] = _bestDisplayName(data, userMapById[userId]);
    }

    final conversationDates = <DateTime>[];
    final patientEvents = <_PatientActivityEvent>[];
    var activeConversations7d = 0;
    var previousConversations7d = 0;
    var highUnreadBacklog = 0;
    for (final doc in conversations) {
      final data = doc.data();
      final conversationAt = _pickDate(data, const ['updated_at', 'last_message_at', 'created_at']);
      if (conversationAt != null) {
        conversationDates.add(conversationAt);
        if (conversationAt.isAfter(now.subtract(const Duration(days: 7)))) {
          activeConversations7d++;
        } else if (conversationAt.isAfter(now.subtract(const Duration(days: 14)))) {
          previousConversations7d++;
        }
      }
      final unread = _toInt(data['therapist_unread_count']);
      if (unread >= 5) highUnreadBacklog++;

      final patientId = _toNonEmptyString(data['patient_id']);
      if (patientId != null && conversationAt != null) {
        patientEvents.add(_PatientActivityEvent(patientId: patientId, at: conversationAt));
      }
    }

    final summaryDates = <DateTime>[];
    final feedbackDates = <DateTime>[];
    var summaries7d = 0;
    var summariesPrev7d = 0;
    for (final doc in summaries) {
      final data = doc.data();
      final createdAt = _pickDate(data, const ['created_at', 'updated_at']);
      if (createdAt != null) {
        summaryDates.add(createdAt);
        if (createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
          summaries7d++;
        } else if (createdAt.isAfter(now.subtract(const Duration(days: 14)))) {
          summariesPrev7d++;
        }
      }
      final hasFeedback = _toNonEmptyString(data['therapist_feedback']) != null;
      if (hasFeedback) {
        final feedbackAt = _pickDate(data, const ['feedback_updated_at', 'created_at']);
        if (feedbackAt != null) feedbackDates.add(feedbackAt);
      }
      final patientId = _toNonEmptyString(data['patient_id']);
      if (patientId != null && createdAt != null) {
        patientEvents.add(_PatientActivityEvent(patientId: patientId, at: createdAt));
      }
    }

    final patientUsers = users.where((doc) => _isPatient(doc.data())).toList(growable: false);
    final knownPatientIds = patientEvents.map((e) => e.patientId).toSet();
    final totalActivePatients = patientUsers.isNotEmpty ? patientUsers.length : knownPatientIds.length;

    final activePatients30d = _uniquePatientCountInRange(
      patientEvents,
      fromInclusive: now.subtract(const Duration(days: 30)),
      toExclusive: now,
    );
    final activePatientsPrev30d = _uniquePatientCountInRange(
      patientEvents,
      fromInclusive: now.subtract(const Duration(days: 60)),
      toExclusive: now.subtract(const Duration(days: 30)),
    );

    final engagementRate = conversations.isEmpty ? 0.0 : (activeConversations7d / conversations.length) * 100;
    final previousEngagementRate = conversations.isEmpty ? 0.0 : (previousConversations7d / conversations.length) * 100;
    final summaryCoverage = activeConversations7d == 0 ? 0.0 : (summaries7d / activeConversations7d) * 100;
    final previousSummaryCoverage = previousConversations7d == 0 ? 0.0 : (summariesPrev7d / previousConversations7d) * 100;

    final metricCards = <_MetricData>[
      _MetricData(
        title: 'Total Active Patients',
        value: _formatInt(totalActivePatients),
        trend: _trendLabel(activePatients30d.toDouble(), activePatientsPrev30d.toDouble()),
        icon: Icons.person_pin_circle_outlined,
        iconColor: const Color(0xFF2B8CEE),
        sparkColor: const Color(0xFF2B8CEE),
        points: _uniqueSeriesFromEvents(patientEvents, 11),
      ),
      _MetricData(
        title: 'Journaling Sessions',
        value: _formatInt(summaries.length),
        trend: _trendLabel(summaries7d.toDouble(), summariesPrev7d.toDouble()),
        icon: Icons.edit_note_rounded,
        iconColor: const Color(0xFFA855F7),
        sparkColor: const Color(0xFFA855F7),
        points: _countSeriesFromDates(summaryDates, 7),
      ),
      _MetricData(
        title: 'Engagement Rate',
        value: '${engagementRate.clamp(0, 100).toStringAsFixed(1)}%',
        trend: _trendLabel(engagementRate, previousEngagementRate),
        icon: Icons.rocket_launch_outlined,
        iconColor: const Color(0xFFF97316),
        sparkColor: const Color(0xFFF97316),
        points: _countSeriesFromDates(conversationDates, 6),
      ),
      _MetricData(
        title: 'AI Summary Coverage',
        value: '${summaryCoverage.clamp(0, 100).toStringAsFixed(0)}%',
        trend: _trendLabel(summaryCoverage, previousSummaryCoverage),
        icon: Icons.sentiment_very_satisfied_outlined,
        iconColor: const Color(0xFF10B981),
        sparkColor: const Color(0xFF10B981),
        points: _countSeriesFromDates(feedbackDates, 5),
      ),
    ];

    final alerts = <_AlertData>[];
    if (pendingApprovals > 0) {
      alerts.add(
        _AlertData(
          title: 'Pending Therapist Approvals',
          message: '$pendingApprovals therapist profile(s) are waiting for admin review.',
          time: 'Live',
          tone: const Color(0xFFEF4444),
          action: 'REVIEW APPLICATIONS',
        ),
      );
    }
    if (highUnreadBacklog > 0) {
      alerts.add(
        _AlertData(
          title: 'Unread Message Backlog',
          message: '$highUnreadBacklog conversation(s) have 5+ unread patient messages.',
          time: 'Live',
          tone: const Color(0xFFF59E0B),
          action: 'CHECK CONVERSATIONS',
        ),
      );
    }
    if (staleTherapists > 0) {
      alerts.add(
        _AlertData(
          title: 'Inactive Team Profiles',
          message: '$staleTherapists therapist account(s) have been inactive for more than 14 days.',
          time: 'Live',
          tone: const Color(0xFF2B8CEE),
          action: 'RE-ENGAGE TEAM',
        ),
      );
    }
    final upcoming24h = sessions.where((doc) {
      final data = doc.data();
      final scheduledAt = _pickDate(data, const ['scheduled_at']);
      if (scheduledAt == null) return false;
      final status = _toNonEmptyString(data['status'])?.toLowerCase() ?? 'scheduled';
      return (status == 'scheduled' || status == 'ongoing') &&
          scheduledAt.isAfter(now) &&
          scheduledAt.isBefore(now.add(const Duration(hours: 24)));
    }).length;
    if (upcoming24h == 0) {
      alerts.add(
        const _AlertData(
          title: 'No Sessions in Next 24h',
          message: 'No scheduled therapy sessions were found for the next 24 hours.',
          time: 'Live',
          tone: Color(0xFF0EA5E9),
          action: 'SCHEDULE CHECK',
        ),
      );
    }
    final visibleAlerts = alerts.take(3).toList(growable: false);

    final summaryList = [...summaries]
      ..sort((a, b) {
        final aDate = _pickDate(a.data(), const ['created_at', 'updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _pickDate(b.data(), const ['created_at', 'updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    final recentSummaryRows = summaryList.take(3).map((doc) {
      final data = doc.data();
      final createdAt = _pickDate(data, const ['created_at', 'updated_at']);
      final summaryText = _toNonEmptyString(data['summary']) ?? 'AI summary generated';
      final patientId = _toNonEmptyString(data['patient_id']) ?? doc.id;
      final transcriptLength = data['transcript'] is List ? (data['transcript'] as List).length : 0;
      final hasFeedback = _toNonEmptyString(data['therapist_feedback']) != null;
      return _RecentSummaryData(
        title: _truncate(summaryText, max: 52),
        subtitle: 'Patient ${_shortId(patientId)} • ${createdAt == null ? 'Unknown time' : _formatRelative(createdAt)}',
        metric: transcriptLength > 0 ? '$transcriptLength msgs' : 'No transcript',
        completion: hasFeedback ? 'Feedback reviewed' : 'Awaiting feedback',
        metricColor: hasFeedback ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      );
    }).toList(growable: false);

    final scheduledSessions = sessions.where((doc) {
      final data = doc.data();
      final scheduledAt = _pickDate(data, const ['scheduled_at']);
      if (scheduledAt == null) return false;
      final status = _toNonEmptyString(data['status'])?.toLowerCase() ?? 'scheduled';
      return (status == 'scheduled' || status == 'ongoing') && scheduledAt.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final aDate = _pickDate(a.data(), const ['scheduled_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _pickDate(b.data(), const ['scheduled_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    final upcomingRows = <_UpcomingSessionData>[];
    for (var i = 0; i < scheduledSessions.length && i < 3; i++) {
      final data = scheduledSessions[i].data();
      final scheduledAt = _pickDate(data, const ['scheduled_at']);
      if (scheduledAt == null) continue;
      final patientId = _toNonEmptyString(data['user_id']) ?? _toNonEmptyString(data['patient_id']) ?? '';
      final therapistId = _toNonEmptyString(data['therapist_id']) ?? '';
      final patientName = _nameFromUser(userMapById[patientId]) ?? _shortId(patientId);
      final therapistName = therapistNameById[therapistId] ?? _nameFromUser(userMapById[therapistId]) ?? _shortId(therapistId);
      upcomingRows.add(
        _UpcomingSessionData(
          month: _monthLabel(scheduledAt.month),
          day: scheduledAt.day.toString().padLeft(2, '0'),
          title: 'Session with $patientName',
          tag: 'Therapist: $therapistName',
          active: i == 0,
        ),
      );
    }

    return _DashboardLiveData(
      metricCards: metricCards,
      engagementPoints: _countSeriesFromDates(conversationDates, 9),
      engagementSubtitle:
          '$activeConversations7d active conversation${activeConversations7d == 1 ? '' : 's'} in the last 7 days',
      alerts: visibleAlerts,
      recentSummaryRows: recentSummaryRows,
      upcomingSessions: upcomingRows,
    );
  }

  DateTime? _pickDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {}
      }
    }
    return null;
  }

  bool _isPatient(Map<String, dynamic> userData) {
    final role = _toNonEmptyString(userData['role'])?.toLowerCase();
    if (role == 'patient') return true;
    if (role == 'therapist' || role == 'admin') return false;
    final isTherapist = userData['is_therapist'] == true;
    return !isTherapist;
  }

  String _bestDisplayName(Map<String, dynamic> therapistData, Map<String, dynamic>? userData) {
    final fullName = _toNonEmptyString(therapistData['full_name']);
    if (fullName != null) return fullName;

    final first = _toNonEmptyString(therapistData['first_name']);
    final last = _toNonEmptyString(therapistData['last_name']);
    final therapistName = [first, last].whereType<String>().join(' ').trim();
    if (therapistName.isNotEmpty) return therapistName;

    final userName = _nameFromUser(userData);
    if (userName != null) return userName;

    final email = _toNonEmptyString(therapistData['contact_email']) ??
        _toNonEmptyString(therapistData['email']) ??
        _toNonEmptyString(userData?['email']);
    if (email != null) return email.split('@').first;
    return 'Unknown Therapist';
  }

  String? _nameFromUser(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    final first = _toNonEmptyString(userData['first_name']);
    final last = _toNonEmptyString(userData['last_name']);
    final joined = [first, last].whereType<String>().join(' ').trim();
    if (joined.isNotEmpty) return joined;
    final email = _toNonEmptyString(userData['email']);
    if (email != null) return email.split('@').first;
    return null;
  }

  String? _toNonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatInt(int value) {
    final digits = value.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  String _trendLabel(double current, double previous) {
    if (current == 0 && previous == 0) return 'Stable';
    if (previous == 0) return current > 0 ? '+100%' : 'Stable';
    final diff = ((current - previous) / previous) * 100;
    if (diff.abs() < 1) return 'Stable';
    final rounded = diff.round();
    return '${rounded > 0 ? '+' : ''}$rounded%';
  }

  List<double> _countSeriesFromDates(List<DateTime> dates, int days) {
    if (days <= 1) return <double>[dates.length.toDouble()];
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    final buckets = List<int>.filled(days, 0);
    for (final date in dates) {
      final day = DateTime(date.year, date.month, date.day);
      final diff = anchor.difference(day).inDays;
      if (diff >= 0 && diff < days) {
        buckets[days - 1 - diff] += 1;
      }
    }
    return buckets.map((count) => count.toDouble()).toList(growable: false);
  }

  List<double> _uniqueSeriesFromEvents(List<_PatientActivityEvent> events, int days) {
    if (days <= 1) return <double>[events.length.toDouble()];
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    final buckets = List<Set<String>>.generate(days, (_) => <String>{});
    for (final event in events) {
      final day = DateTime(event.at.year, event.at.month, event.at.day);
      final diff = anchor.difference(day).inDays;
      if (diff >= 0 && diff < days) {
        buckets[days - 1 - diff].add(event.patientId);
      }
    }
    return buckets.map((ids) => ids.length.toDouble()).toList(growable: false);
  }

  int _uniquePatientCountInRange(
    List<_PatientActivityEvent> events, {
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) {
    final ids = <String>{};
    for (final event in events) {
      if (!event.at.isBefore(fromInclusive) && event.at.isBefore(toExclusive)) {
        ids.add(event.patientId);
      }
    }
    return ids.length;
  }

  String _truncate(String value, {required int max}) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= max) return normalized;
    return '${normalized.substring(0, max - 1)}...';
  }

  String _shortId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Unknown';
    if (value.length <= 6) return value.toUpperCase();
    return value.substring(0, 6).toUpperCase();
  }

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _monthLabel(int month) {
    const months = <String>['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    if (month < 1 || month > 12) return 'N/A';
    return months[month - 1];
  }
}

class _DashboardLiveData {
  final List<_MetricData> metricCards;
  final List<double> engagementPoints;
  final String engagementSubtitle;
  final List<_AlertData> alerts;
  final List<_RecentSummaryData> recentSummaryRows;
  final List<_UpcomingSessionData> upcomingSessions;

  const _DashboardLiveData({
    required this.metricCards,
    required this.engagementPoints,
    required this.engagementSubtitle,
    required this.alerts,
    required this.recentSummaryRows,
    required this.upcomingSessions,
  });
}

class _MetricData {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color iconColor;
  final Color sparkColor;
  final List<double> points;

  const _MetricData({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.iconColor,
    required this.sparkColor,
    required this.points,
  });
}

class _AlertData {
  final String title;
  final String message;
  final String time;
  final Color tone;
  final String action;

  const _AlertData({
    required this.title,
    required this.message,
    required this.time,
    required this.tone,
    required this.action,
  });
}

class _RecentSummaryData {
  final String title;
  final String subtitle;
  final String metric;
  final String completion;
  final Color metricColor;

  const _RecentSummaryData({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.completion,
    required this.metricColor,
  });
}

class _UpcomingSessionData {
  final String month;
  final String day;
  final String title;
  final String tag;
  final bool active;

  const _UpcomingSessionData({
    required this.month,
    required this.day,
    required this.title,
    required this.tag,
    this.active = false,
  });
}

class _PatientActivityEvent {
  final String patientId;
  final DateTime at;

  const _PatientActivityEvent({required this.patientId, required this.at});
}

class _MetricsGrid extends StatelessWidget {
  final List<_MetricData> cards;
  const _MetricsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 1240 ? 4 : width >= 900 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (_, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final positive = data.trend.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                data.trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: positive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111418),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: _Sparkline(points: data.points, color: data.sparkColor),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;
  const _Sparkline({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(points: points, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minY = points.reduce(math.min);
    final maxY = points.reduce(math.max);
    final span = (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalized = (points[i] - minY) / span;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _EngagementCard extends StatelessWidget {
  final List<double> points;
  final String subtitle;

  const _EngagementCard({
    required this.points,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Engagement over Time',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF617589),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: _AreaChartPainter(
                points: points,
                color: const Color(0xFF2B8CEE),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _AreaChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minY = points.reduce(math.min);
    final maxY = points.reduce(math.max);
    final span = (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY);

    final line = Path();
    final area = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (((points[i] - minY) / span) * (size.height - 18)) - 8;
      if (i == 0) {
        line.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(size.width, size.height);
    area.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(area, fillPaint);
    canvas.drawPath(line, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _AlertsCard extends StatelessWidget {
  final List<_AlertData> alerts;
  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Critical Alerts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111418)),
                ),
              ),
              _Badge('${alerts.length} ACTION REQ.'),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No active critical alerts from live Firestore data.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
          for (var i = 0; i < alerts.length; i++) ...[
            _AlertItem(
              title: alerts[i].title,
              message: alerts[i].message,
              time: alerts[i].time,
              tone: alerts[i].tone,
              action: alerts[i].action,
            ),
            if (i < alerts.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFFDC2626),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final Color tone;
  final String action;
  const _AlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.tone,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: tone, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tone),
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            action,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentArticlesCard extends StatelessWidget {
  final List<_RecentSummaryData> rows;
  const _RecentArticlesCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent AI Session Summaries',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111418)),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'No AI summary records found yet.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            _ArticlePerformanceRow(
              title: rows[i].title,
              subtitle: rows[i].subtitle,
              metric: rows[i].metric,
              completion: rows[i].completion,
              metricColor: rows[i].metricColor,
            ),
            if (i < rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ArticlePerformanceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String metric;
  final String completion;
  final Color metricColor;
  const _ArticlePerformanceRow({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.completion,
    required this.metricColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFF2B8CEE), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111418)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: metricColor),
              ),
              const SizedBox(height: 2),
              Text(
                completion,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingContentCard extends StatelessWidget {
  final List<_UpcomingSessionData> rows;
  const _UpcomingContentCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Scheduled Sessions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111418)),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'No upcoming sessions found in Firestore.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            _ScheduleRow(
              month: rows[i].month,
              day: rows[i].day,
              title: rows[i].title,
              tag: rows[i].tag,
              active: rows[i].active,
            ),
            if (i < rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String tag;
  final bool active;
  const _ScheduleRow({
    required this.month,
    required this.day,
    required this.title,
    required this.tag,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        color: active ? const Color(0xFFF8FBFF) : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111418)),
                ),
                const SizedBox(height: 2),
                Text(
                  tag,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
