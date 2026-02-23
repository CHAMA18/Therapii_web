import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminPatientsPage extends StatelessWidget {
  const JournalAdminPatientsPage({super.key});

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
            const Expanded(child: _PatientsMainContent()),
          ],
        ),
      ),
    );
  }
}

class _PatientsSidebar extends StatelessWidget {
  const _PatientsSidebar();

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

class _PatientsMainContent extends StatefulWidget {
  const _PatientsMainContent();

  @override
  State<_PatientsMainContent> createState() => _PatientsMainContentState();
}

class _PatientsMainContentState extends State<_PatientsMainContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _userDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _therapistDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _summaryDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _conversationDocs;

  Object? _usersError;
  Object? _therapistsError;
  Object? _summariesError;
  Object? _conversationsError;

  String _selectedStatus = 'All Statuses';
  String _selectedTherapist = 'All Therapists';

  late final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions;

  bool get _isLoading =>
      _userDocs == null || _therapistDocs == null || _summaryDocs == null || _conversationDocs == null;

  @override
  void initState() {
    super.initState();
    _subscriptions = [
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
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    late final List<_PatientRowData> rows;
    late final int atRiskCount;
    late final int activeCount;
    late final int newThisWeek;
    late final List<String> therapistOptions;
    try {
      final computed = _buildRows();
      rows = computed.rows;
      atRiskCount = computed.atRiskCount;
      activeCount = computed.activeCount;
      newThisWeek = computed.newThisWeek;
      therapistOptions = computed.therapistOptions;
    } catch (error) {
      return _PatientsRenderError(message: 'Unable to render patient data: $error');
    }

    final selectedTherapist =
        therapistOptions.contains(_selectedTherapist) ? _selectedTherapist : therapistOptions.first;
    final selectedStatus = _selectedStatus;
    final query = _searchController.text.trim().toLowerCase();

    final filteredRows = rows.where((row) {
      if (selectedStatus != 'All Statuses' && row.statusLabel != selectedStatus) return false;
      if (selectedTherapist != 'All Therapists' && row.therapistName != selectedTherapist) return false;
      if (query.isEmpty) return true;
      final haystack = '${row.name} ${row.uniqueId} ${row.therapistName}'.toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);

    final errorCount = [
      _usersError,
      _therapistsError,
      _summariesError,
      _conversationsError,
    ].whereType<Object>().length;

    return Column(
      children: [
        Container(
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
                      'Admin Patients Management Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111418),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Oversee patient health status and AI sentiment tracking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF617589),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const _PulseDot(),
                    const SizedBox(width: 7),
                    Text(
                      '$atRiskCount patients at risk',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBE123C),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add patient flow is not wired yet.')),
                  );
                },
                icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2B8CEE),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                label: const Text('Add New Patient'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (errorCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    '$errorCount live data stream(s) failed. Remaining sections are still showing real-time data.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6EBF2)),
                ),
                child: _PatientsFilterBar(
                  searchController: _searchController,
                  selectedStatus: selectedStatus,
                  selectedTherapist: selectedTherapist,
                  therapistOptions: therapistOptions,
                  onSearchChanged: (_) => setState(() {}),
                  onStatusChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                  },
                  onTherapistChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedTherapist = value);
                  },
                ),
              ),
              const SizedBox(height: 14),
              _PatientsTableCard(
                rows: filteredRows,
                totalCount: rows.length,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final cards = [
                    _PatientsSummaryCard(
                      title: 'TOTAL ACTIVE PATIENTS',
                      value: '$activeCount Patients',
                      icon: Icons.people_alt_rounded,
                      tone: const Color(0xFF2B8CEE),
                      bg: const Color(0x1A2B8CEE),
                    ),
                    _PatientsSummaryCard(
                      title: 'AT RISK ALERTS',
                      value: '$atRiskCount Critical Cases',
                      icon: Icons.warning_amber_rounded,
                      tone: const Color(0xFFEF4444),
                      bg: const Color(0x1AEF4444),
                    ),
                    _PatientsSummaryCard(
                      title: 'NEW PATIENTS THIS WEEK',
                      value: '+$newThisWeek Growth',
                      icon: Icons.person_add_alt_1_rounded,
                      tone: const Color(0xFF10B981),
                      bg: const Color(0x1A10B981),
                    ),
                  ];
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[1]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[2]),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 10),
                      cards[1],
                      const SizedBox(height: 10),
                      cards[2],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  _PatientsDerivedData _buildRows() {
    final users = _userDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final therapists = _therapistDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final summaries = _summaryDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final conversations = _conversationDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final therapistNameById = <String, String>{};
    for (final therapistDoc in therapists) {
      final data = therapistDoc.data();
      therapistNameById[therapistDoc.id] = _bestTherapistName(data, therapistDoc.id);
    }

    final latestSummaryByPatient = <String, Map<String, dynamic>>{};
    for (final summaryDoc in summaries) {
      final data = summaryDoc.data();
      final patientId = _toNonEmptyString(data['patient_id']);
      if (patientId == null) continue;
      final createdAt = _pickDate(data, const ['created_at', 'feedback_updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final existing = latestSummaryByPatient[patientId];
      if (existing == null) {
        latestSummaryByPatient[patientId] = {
          'data': data,
          'created': createdAt,
        };
      } else {
        final existingCreated = existing['created'] as DateTime;
        if (createdAt.isAfter(existingCreated)) {
          latestSummaryByPatient[patientId] = {
            'data': data,
            'created': createdAt,
          };
        }
      }
    }

    final latestConversationAtByPatient = <String, DateTime>{};
    for (final conversationDoc in conversations) {
      final data = conversationDoc.data();
      final patientId = _toNonEmptyString(data['patient_id']);
      if (patientId == null) continue;
      final updatedAt = _pickDate(data, const ['updated_at', 'last_message_at', 'created_at']);
      if (updatedAt == null) continue;
      final current = latestConversationAtByPatient[patientId];
      if (current == null || updatedAt.isAfter(current)) {
        latestConversationAtByPatient[patientId] = updatedAt;
      }
    }

    final rows = <_PatientRowData>[];
    var atRiskCount = 0;
    var activeCount = 0;
    var newThisWeek = 0;
    final therapistOptions = <String>{'All Therapists'};
    final now = DateTime.now();

    for (final userDoc in users) {
      final data = userDoc.data();
      if (!_isPatient(data)) continue;

      final createdAt = _pickDate(data, const ['created_at', 'updated_at']);
      if (createdAt != null && now.difference(createdAt).inDays <= 7) {
        newThisWeek++;
      }

      final patientId = userDoc.id;
      final therapistId = _toNonEmptyString(data['therapist_id']);
      final therapistName = therapistId == null
          ? 'Pending Assignment'
          : (therapistNameById[therapistId] ?? 'Assigned Therapist');
      therapistOptions.add(therapistName);

      final summaryWrap = latestSummaryByPatient[patientId];
      final summaryData = summaryWrap?['data'] as Map<String, dynamic>?;
      final summaryText = _toNonEmptyString(summaryData?['summary']) ?? '';
      final feedbackText = _toNonEmptyString(summaryData?['therapist_feedback']) ?? '';
      final sentiment = _deriveSentiment(summaryText, feedbackText);

      final convoAt = latestConversationAtByPatient[patientId];
      final summaryAt = summaryWrap?['created'] as DateTime?;
      final profileAt = _pickDate(data, const ['updated_at', 'created_at']);
      final lastActivity = _latestDate([convoAt, summaryAt, profileAt]);

      final onboardingCompleted = data['patient_onboarding_completed'] == true;
      final status = _deriveStatus(
        sentiment: sentiment,
        onboardingCompleted: onboardingCompleted,
        lastActivity: lastActivity,
      );

      if (status.label == 'At Risk') atRiskCount++;
      if (status.label == 'Active') activeCount++;

      rows.add(
        _PatientRowData(
          id: patientId,
          name: _bestPatientName(data, patientId),
          statusLabel: status.label,
          statusColor: status.color,
          uniqueId: _patientCode(patientId),
          therapistName: therapistName,
          sentimentLabel: sentiment.label,
          sentimentColor: sentiment.color,
          activityTitle: _activityTitle(status.label, summaryText),
          activityTime: lastActivity == null ? 'Unknown' : _formatRelative(lastActivity),
        ),
      );
    }

    rows.sort((a, b) {
      final rank = <String, int>{
        'At Risk': 0,
        'Onboarding': 1,
        'Active': 2,
        'Inactive': 3,
      };
      final rankA = rank[a.statusLabel] ?? 9;
      final rankB = rank[b.statusLabel] ?? 9;
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.name.compareTo(b.name);
    });

    return _PatientsDerivedData(
      rows: rows,
      atRiskCount: atRiskCount,
      activeCount: activeCount,
      newThisWeek: newThisWeek,
      therapistOptions: therapistOptions.toList()..sort(),
    );
  }

  bool _isPatient(Map<String, dynamic> data) {
    final role = _toNonEmptyString(data['role'])?.toLowerCase();
    if (role == 'patient') return true;
    if (role == 'therapist' || role == 'admin') return false;
    return data['is_therapist'] != true;
  }

  String _bestPatientName(Map<String, dynamic> data, String fallbackId) {
    final first = _toNonEmptyString(data['first_name']);
    final last = _toNonEmptyString(data['last_name']);
    final full = [first, last].whereType<String>().join(' ').trim();
    if (full.isNotEmpty) return full;
    final email = _toNonEmptyString(data['email']);
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Patient ${fallbackId.substring(0, fallbackId.length < 6 ? fallbackId.length : 6).toUpperCase()}';
  }

  String _bestTherapistName(Map<String, dynamic> data, String therapistId) {
    final full = _toNonEmptyString(data['full_name']);
    if (full != null) return full;
    final first = _toNonEmptyString(data['first_name']);
    final last = _toNonEmptyString(data['last_name']);
    final joined = [first, last].whereType<String>().join(' ').trim();
    if (joined.isNotEmpty) return joined;
    final email = _toNonEmptyString(data['contact_email']) ?? _toNonEmptyString(data['email']);
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Therapist ${therapistId.substring(0, therapistId.length < 6 ? therapistId.length : 6).toUpperCase()}';
  }

  _SentimentData _deriveSentiment(String summary, String feedback) {
    final text = '$summary $feedback'.toLowerCase();
    if (text.contains('suicid') ||
        text.contains('self-harm') ||
        text.contains('intrusive') ||
        text.contains('panic') ||
        text.contains('hopeless') ||
        text.contains('unsafe')) {
      return const _SentimentData(label: 'Critical', color: Color(0xFFEF4444));
    }
    if (text.contains('anxious') ||
        text.contains('sad') ||
        text.contains('low mood') ||
        text.contains('stress') ||
        text.contains('overwhelm')) {
      return const _SentimentData(label: 'Concerning', color: Color(0xFFF59E0B));
    }
    if (text.contains('calm') || text.contains('improv') || text.contains('positive') || text.contains('progress')) {
      return const _SentimentData(label: 'Positive', color: Color(0xFF10B981));
    }
    return const _SentimentData(label: 'Neutral', color: Color(0xFF64748B));
  }

  _StatusData _deriveStatus({
    required _SentimentData sentiment,
    required bool onboardingCompleted,
    required DateTime? lastActivity,
  }) {
    if (sentiment.label == 'Critical') {
      return const _StatusData(label: 'At Risk', color: Color(0xFFEF4444));
    }
    if (!onboardingCompleted) {
      return const _StatusData(label: 'Onboarding', color: Color(0xFF2B8CEE));
    }
    if (lastActivity == null) {
      return const _StatusData(label: 'Inactive', color: Color(0xFF94A3B8));
    }
    final days = DateTime.now().difference(lastActivity).inDays;
    if (days <= 14) {
      return const _StatusData(label: 'Active', color: Color(0xFF10B981));
    }
    return const _StatusData(label: 'Inactive', color: Color(0xFF94A3B8));
  }

  String _activityTitle(String status, String summary) {
    if (status == 'At Risk') return 'Flagged Content';
    if (status == 'Onboarding') return 'Account Created';
    if (summary.trim().isNotEmpty) return 'Journaling Complete';
    return 'Profile Updated';
  }

  String _patientCode(String id) {
    final numeric = id.codeUnits.fold<int>(0, (sum, code) => (sum * 31 + code) % 100000);
    return 'PA-${numeric.toString().padLeft(5, '0')}';
  }

  DateTime? _pickDate(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;
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

  DateTime? _latestDate(List<DateTime?> dates) {
    DateTime? latest;
    for (final date in dates) {
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest;
  }

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) return 'Just now';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  String? _toNonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class _PatientsDerivedData {
  final List<_PatientRowData> rows;
  final int atRiskCount;
  final int activeCount;
  final int newThisWeek;
  final List<String> therapistOptions;

  const _PatientsDerivedData({
    required this.rows,
    required this.atRiskCount,
    required this.activeCount,
    required this.newThisWeek,
    required this.therapistOptions,
  });
}

class _PatientRowData {
  final String id;
  final String name;
  final String statusLabel;
  final Color statusColor;
  final String uniqueId;
  final String therapistName;
  final String sentimentLabel;
  final Color sentimentColor;
  final String activityTitle;
  final String activityTime;

  const _PatientRowData({
    required this.id,
    required this.name,
    required this.statusLabel,
    required this.statusColor,
    required this.uniqueId,
    required this.therapistName,
    required this.sentimentLabel,
    required this.sentimentColor,
    required this.activityTitle,
    required this.activityTime,
  });
}

class _SentimentData {
  final String label;
  final Color color;
  const _SentimentData({required this.label, required this.color});
}

class _StatusData {
  final String label;
  final Color color;
  const _StatusData({required this.label, required this.color});
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PatientsFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final String selectedTherapist;
  final List<String> therapistOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTherapistChanged;

  const _PatientsFilterBar({
    required this.searchController,
    required this.selectedStatus,
    required this.selectedTherapist,
    required this.therapistOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTherapistChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final statusItems = const ['All Statuses', 'Active', 'Onboarding', 'At Risk', 'Inactive'];
        if (wide) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search patients by name, ID or therapist...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown(
                items: statusItems,
                value: selectedStatus,
                onChanged: onStatusChanged,
              ),
              const SizedBox(width: 10),
              _FilterDropdown(
                items: therapistOptions,
                value: selectedTherapist,
                onChanged: onTherapistChanged,
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                label: const Text('More Filters'),
              ),
            ],
          );
        }
        return Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search patients by name, ID or therapist...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterDropdown(
                    items: statusItems,
                    value: selectedStatus,
                    onChanged: onStatusChanged,
                  ),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    items: therapistOptions,
                    value: selectedTherapist,
                    onChanged: onTherapistChanged,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedItems = items.toSet().toList(growable: false);
    final hasValue = normalizedItems.contains(value);
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: Colors.white,
        ),
        child: DropdownButton<String>(
          value: hasValue ? value : null,
          hint: normalizedItems.isEmpty ? const Text('No options') : Text(normalizedItems.first),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          items: normalizedItems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: normalizedItems.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _PatientsTableCard extends StatelessWidget {
  final List<_PatientRowData> rows;
  final int totalCount;

  const _PatientsTableCard({
    required this.rows,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        children: [
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No patients found for the selected filters.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1120),
                child: Column(
                  children: [
                    const _PatientsTableHeader(),
                    for (final row in rows) _PatientsTableRow(row: row),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE6EBF2))),
            ),
            child: Row(
              children: [
                Text(
                  'SHOWING ${rows.length} OF $totalCount PATIENTS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientsTableHeader extends StatelessWidget {
  const _PatientsTableHeader();

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Color(0xFF94A3B8),
    letterSpacing: 0.6,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EBF2))),
      ),
      child: const Row(
        children: [
          SizedBox(width: 250, child: Text('PATIENT DETAILS', style: _headerStyle)),
          SizedBox(width: 120, child: Text('UNIQUE ID', style: _headerStyle)),
          SizedBox(width: 180, child: Text('ASSIGNED THERAPIST', style: _headerStyle)),
          SizedBox(width: 140, child: Text('AI SENTIMENT', style: _headerStyle)),
          SizedBox(width: 190, child: Text('LAST ACTIVITY', style: _headerStyle)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('QUICK ACTIONS', style: _headerStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientsTableRow extends StatelessWidget {
  final _PatientRowData row;
  const _PatientsTableRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 20, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111418)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: row.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          row.statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: row.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              row.uniqueId,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              row.therapistName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: row.therapistName == 'Pending Assignment' ? FontWeight.w500 : FontWeight.w700,
                color: row.therapistName == 'Pending Assignment' ? const Color(0xFF94A3B8) : const Color(0xFF111418),
                fontStyle: row.therapistName == 'Pending Assignment' ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: row.sentimentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  row.sentimentLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: row.sentimentColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.activityTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111418),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  row.activityTime,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionIcon(icon: Icons.account_circle_outlined, color: const Color(0xFF2B8CEE)),
                _ActionIcon(icon: Icons.chat_bubble_outline_rounded, color: const Color(0xFF64748B)),
                _ActionIcon(icon: Icons.monitor_heart_outlined, color: const Color(0xFF2B8CEE)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ActionIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _PatientsSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tone;
  final Color bg;
  const _PatientsSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111418),
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

class _PatientsRenderError extends StatelessWidget {
  final String message;
  const _PatientsRenderError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patients view failed to render',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ],
        ),
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
