import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/utils/admin_access.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminTeamPage extends StatelessWidget {
  const JournalAdminTeamPage({super.key});

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
            const Expanded(child: _TeamMainContent()),
          ],
        ),
      ),
    );
  }
}

class _TeamSidebar extends StatelessWidget {
  const _TeamSidebar();

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
                  const _SidebarItem(
                    icon: Icons.group_outlined,
                    label: 'Team',
                    active: true,
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

class _TeamMainContent extends StatefulWidget {
  const _TeamMainContent();

  @override
  State<_TeamMainContent> createState() => _TeamMainContentState();
}

class _TeamMainContentState extends State<_TeamMainContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _therapistDocs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _userDocs;

  Object? _therapistsError;
  Object? _usersError;

  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Statuses';

  late final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions;

  bool get _isLoading => _therapistDocs == null || _userDocs == null;

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

    final errorCount = [_therapistsError, _usersError].whereType<Object>().length;
    late final List<_TeamMember> members;
    late final List<String> roleOptions;
    late final String selectedRole;
    late final String selectedStatus;
    late final List<_TeamMember> filteredMembers;
    late final int activeToday;
    late final int totalAssignedPatients;
    late final int updated7d;
    try {
      members = _buildMembers();
      roleOptions = <String>{
        'All Roles',
        ...members.map((member) => member.role),
      }.toList()
        ..sort((a, b) {
          if (a == 'All Roles') return -1;
          if (b == 'All Roles') return 1;
          return a.compareTo(b);
        });

      selectedRole = roleOptions.contains(_selectedRole) ? _selectedRole : 'All Roles';
      const statusOptions = <String>['All Statuses', 'Online', 'Away', 'Offline'];
      selectedStatus = statusOptions.contains(_selectedStatus) ? _selectedStatus : 'All Statuses';
      final query = _searchController.text.trim().toLowerCase();

      filteredMembers = members.where((member) {
        if (selectedRole != 'All Roles' && member.role != selectedRole) return false;
        if (selectedStatus != 'All Statuses' && member.status != selectedStatus) return false;
        if (query.isEmpty) return true;
        final haystack = '${member.name} ${member.email} ${member.role}'.toLowerCase();
        return haystack.contains(query);
      }).toList(growable: false);

      final now = DateTime.now();
      activeToday = members.where((member) {
        final lastActive = member.lastActiveAt;
        return lastActive != null && now.difference(lastActive).inHours < 24;
      }).length;
      totalAssignedPatients = members.fold<int>(0, (sum, member) => sum + member.patientCount);
      updated7d = members.where((member) {
        final lastActive = member.lastActiveAt;
        return lastActive != null && now.difference(lastActive).inDays < 7;
      }).length;
    } catch (error) {
      return _TeamRenderError(message: 'Unable to render team data: $error');
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          decoration: const BoxDecoration(
            color: Color(0xCCFFFFFF),
            border: Border(bottom: BorderSide(color: Color(0xFFE6EBF2))),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Admin Team Management Hub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _ActiveTodayBadge(activeCount: activeToday, compact: true),
                        const SizedBox(width: 8),
                        const _InviteMemberButton(compact: true),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Admin Team Management Hub',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111418),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage your specialized therapeutic team and roles',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF617589),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ActiveTodayBadge(activeCount: activeToday),
                  const SizedBox(width: 12),
                  const _InviteMemberButton(),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (members.isEmpty && errorCount == 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'No team profiles found yet. Live data is connected and waiting for therapist/admin records.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
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
                    '$errorCount live data stream(s) failed. Team table still reflects remaining real-time data.',
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
                child: _TeamFilterBar(
                  searchController: _searchController,
                  roleOptions: roleOptions,
                  selectedRole: selectedRole,
                  selectedStatus: selectedStatus,
                  onSearchChanged: (_) => setState(() {}),
                  onRoleChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRole = value);
                  },
                  onStatusChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                  },
                ),
              ),
              const SizedBox(height: 14),
              _TeamTableCard(
                members: filteredMembers,
                totalCount: members.length,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricCard(
                            title: 'TOTAL TEAM MEMBERS',
                            value: '${members.length} Members',
                            icon: Icons.groups_rounded,
                            tone: const Color(0xFF2B8CEE),
                            bg: const Color(0x1A2B8CEE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryMetricCard(
                            title: 'ASSIGNED PATIENTS',
                            value: '${_formatInt(totalAssignedPatients)} Total',
                            icon: Icons.people_alt_rounded,
                            tone: const Color(0xFF10B981),
                            bg: const Color(0x1A10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryMetricCard(
                            title: 'UPDATED LAST 7 DAYS',
                            value: '$updated7d Profiles',
                            icon: Icons.check_circle_rounded,
                            tone: const Color(0xFFA855F7),
                            bg: const Color(0x1AA855F7),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _SummaryMetricCard(
                        title: 'TOTAL TEAM MEMBERS',
                        value: '${members.length} Members',
                        icon: Icons.groups_rounded,
                        tone: const Color(0xFF2B8CEE),
                        bg: const Color(0x1A2B8CEE),
                      ),
                      const SizedBox(height: 10),
                      _SummaryMetricCard(
                        title: 'ASSIGNED PATIENTS',
                        value: '${_formatInt(totalAssignedPatients)} Total',
                        icon: Icons.people_alt_rounded,
                        tone: const Color(0xFF10B981),
                        bg: const Color(0x1A10B981),
                      ),
                      const SizedBox(height: 10),
                      _SummaryMetricCard(
                        title: 'UPDATED LAST 7 DAYS',
                        value: '$updated7d Profiles',
                        icon: Icons.check_circle_rounded,
                        tone: const Color(0xFFA855F7),
                        bg: const Color(0x1AA855F7),
                      ),
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

  List<_TeamMember> _buildMembers() {
    final therapists = _therapistDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final users = _userDocs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final userMapById = <String, Map<String, dynamic>>{
      for (final doc in users) doc.id: doc.data(),
    };

    final patientCountByTherapist = <String, int>{};
    for (final userDoc in users) {
      final userData = userDoc.data();
      final therapistId = _toNonEmptyString(userData['therapist_id']);
      if (therapistId == null) continue;
      patientCountByTherapist.update(therapistId, (value) => value + 1, ifAbsent: () => 1);
    }

    final members = <_TeamMember>[];
    final seenMemberIds = <String>{};

    for (final therapistDoc in therapists) {
      final therapistData = therapistDoc.data();
      final userId = _toNonEmptyString(therapistData['user_id']) ?? therapistDoc.id;
      final userData = userMapById[userId] ?? userMapById[therapistDoc.id];
      final email = _pickEmail(therapistData, userData) ?? '';
      final role = _deriveRole(therapistData, email);
      final statusInfo = _deriveStatus(
        _pickDate(therapistData, const ['updated_at', 'approval_requested_at', 'created_at']) ??
            _pickDate(userData ?? const <String, dynamic>{}, const ['updated_at', 'created_at']),
      );
      final patientCount = patientCountByTherapist[therapistDoc.id] ?? patientCountByTherapist[userId] ?? 0;

      members.add(
        _TeamMember(
          id: therapistDoc.id,
          name: _pickName(therapistData, userData),
          email: email.isEmpty ? 'No email on record' : email,
          role: role,
          roleTone: _roleTone(role),
          status: statusInfo.label,
          statusTone: statusInfo.tone,
          patientCount: patientCount,
          assignmentsPrimary: '$patientCount Patient${patientCount == 1 ? '' : 's'}',
          assignmentsSecondary: _secondaryAssignments(therapistData),
          lastLogin: statusInfo.lastSeenText,
          avatarUrl: _pickAvatarUrl(therapistData, userData),
          lastActiveAt: statusInfo.lastActiveAt,
        ),
      );
      seenMemberIds.add(therapistDoc.id);
      seenMemberIds.add(userId);
    }

    for (final userDoc in users) {
      final userData = userDoc.data();
      final email = _toNonEmptyString(userData['email']);
      if (!AdminAccess.isAdminEmail(email)) continue;
      if (seenMemberIds.contains(userDoc.id)) continue;

      final statusInfo = _deriveStatus(
        _pickDate(userData, const ['updated_at', 'created_at']),
      );
      members.add(
        _TeamMember(
          id: userDoc.id,
          name: _pickName(const <String, dynamic>{}, userData),
          email: email ?? 'No email on record',
          role: 'Admin',
          roleTone: _roleTone('Admin'),
          status: statusInfo.label,
          statusTone: statusInfo.tone,
          patientCount: 0,
          assignmentsPrimary: 'Admin Access',
          assignmentsSecondary: 'Platform administration',
          lastLogin: statusInfo.lastSeenText,
          avatarUrl: _pickAvatarUrl(const <String, dynamic>{}, userData),
          lastActiveAt: statusInfo.lastActiveAt,
        ),
      );
      seenMemberIds.add(userDoc.id);
    }

    members.sort((a, b) {
      final aDate = a.lastActiveAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastActiveAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return members;
  }

  String _pickName(Map<String, dynamic> therapistData, Map<String, dynamic>? userData) {
    final fullName = _toNonEmptyString(therapistData['full_name']);
    if (fullName != null) return fullName;

    final first = _toNonEmptyString(therapistData['first_name']);
    final last = _toNonEmptyString(therapistData['last_name']);
    final therapistJoined = [first, last].whereType<String>().join(' ').trim();
    if (therapistJoined.isNotEmpty) return therapistJoined;

    final userFirst = _toNonEmptyString(userData?['first_name']);
    final userLast = _toNonEmptyString(userData?['last_name']);
    final userJoined = [userFirst, userLast].whereType<String>().join(' ').trim();
    if (userJoined.isNotEmpty) return userJoined;

    final email = _pickEmail(therapistData, userData);
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Unknown';
  }

  String? _pickEmail(Map<String, dynamic> therapistData, Map<String, dynamic>? userData) {
    return _toNonEmptyString(therapistData['contact_email']) ??
        _toNonEmptyString(therapistData['email']) ??
        _toNonEmptyString(userData?['email']);
  }

  String? _pickAvatarUrl(Map<String, dynamic> therapistData, Map<String, dynamic>? userData) {
    final raw = _toNonEmptyString(therapistData['profile_photo_url']) ??
        _toNonEmptyString(therapistData['profile_image_url']) ??
        _toNonEmptyString(userData?['avatar_url']);
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return raw;
  }

  String _deriveRole(Map<String, dynamic> therapistData, String email) {
    if (AdminAccess.isAdminEmail(email)) return 'Admin';
    final explicitRole = _toNonEmptyString(therapistData['role']) ??
        _toNonEmptyString(therapistData['professional_title']) ??
        _toNonEmptyString(therapistData['title']);
    if (explicitRole != null) return _toTitleCase(explicitRole);

    final approval = _toNonEmptyString(therapistData['approval_status'])?.toLowerCase() ?? '';
    if (approval == 'rejected') return 'Rejected Therapist';
    if (approval == 'pending' || approval == 'resubmitted' || approval == 'needs_review' || approval.isEmpty) {
      return 'Pending Therapist';
    }
    return 'Therapist';
  }

  String _secondaryAssignments(Map<String, dynamic> therapistData) {
    final approval = _toNonEmptyString(therapistData['approval_status'])?.toLowerCase() ?? '';
    final specialization = _toNonEmptyString(therapistData['specialization']) ??
        _toNonEmptyString(therapistData['practice_name']) ??
        _toNonEmptyString(therapistData['state']);

    String statusText;
    if (approval == 'approved') {
      statusText = 'Approved profile';
    } else if (approval == 'rejected') {
      statusText = 'Rejected profile';
    } else if (approval == 'pending' || approval == 'resubmitted' || approval == 'needs_review' || approval.isEmpty) {
      statusText = 'Awaiting approval';
    } else {
      statusText = _toTitleCase(approval);
    }

    if (specialization == null) return statusText;
    return '$statusText • $specialization';
  }

  Color _roleTone(String role) {
    final normalized = role.toLowerCase();
    if (normalized.contains('admin')) return const Color(0xFF2B8CEE);
    if (normalized.contains('pending')) return const Color(0xFFF59E0B);
    if (normalized.contains('rejected')) return const Color(0xFFEF4444);
    if (normalized.contains('editor')) return const Color(0xFFA855F7);
    return const Color(0xFF2B8CEE);
  }

  _StatusInfo _deriveStatus(DateTime? lastActiveAt) {
    if (lastActiveAt == null) {
      return const _StatusInfo(
        label: 'Offline',
        tone: Color(0xFF64748B),
        lastSeenText: 'Unknown',
        lastActiveAt: null,
      );
    }
    final diff = DateTime.now().difference(lastActiveAt);
    if (diff.inHours < 4) {
      return _StatusInfo(
        label: 'Online',
        tone: const Color(0xFF10B981),
        lastSeenText: _formatRelative(lastActiveAt),
        lastActiveAt: lastActiveAt,
      );
    }
    if (diff.inHours < 36) {
      return _StatusInfo(
        label: 'Away',
        tone: const Color(0xFFF59E0B),
        lastSeenText: _formatRelative(lastActiveAt),
        lastActiveAt: lastActiveAt,
      );
    }
    return _StatusInfo(
      label: 'Offline',
      tone: const Color(0xFF64748B),
      lastSeenText: _formatRelative(lastActiveAt),
      lastActiveAt: lastActiveAt,
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

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _toTitleCase(String value) {
    final normalized = value.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return value;
    final words = normalized.split(RegExp(r'\s+'));
    return words
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String? _toNonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _formatInt(int value) {
    final digits = value.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }
}

class _StatusInfo {
  final String label;
  final Color tone;
  final String lastSeenText;
  final DateTime? lastActiveAt;

  const _StatusInfo({
    required this.label,
    required this.tone,
    required this.lastSeenText,
    required this.lastActiveAt,
  });
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActiveTodayBadge extends StatelessWidget {
  final int activeCount;
  final bool compact;
  const _ActiveTodayBadge({required this.activeCount, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const _PulseDot(),
          const SizedBox(width: 7),
          Text(
            '$activeCount ACTIVE TODAY',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteMemberButton extends StatelessWidget {
  final bool compact;
  const _InviteMemberButton({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite flow is not wired yet.')),
        );
      },
      icon: const Icon(Icons.person_add_alt_rounded, size: 18),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2B8CEE),
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 12 : 14),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 8 : 10),
      ),
      label: Text(compact ? 'Invite' : 'Invite New Member'),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, role or email...',
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
    );
  }
}

class _TeamFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> roleOptions;
  final String selectedRole;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onStatusChanged;

  const _TeamFilterBar({
    required this.searchController,
    required this.roleOptions,
    required this.selectedRole,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        if (wide) {
          return Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown(
                items: roleOptions,
                value: selectedRole,
                onChanged: onRoleChanged,
              ),
              const SizedBox(width: 10),
              _FilterDropdown(
                items: const ['All Statuses', 'Online', 'Away', 'Offline'],
                value: selectedStatus,
                onChanged: onStatusChanged,
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                label: const Text('Live Filters'),
              ),
            ],
          );
        }

        return Column(
          children: [
            _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterDropdown(
                    items: roleOptions,
                    value: selectedRole,
                    onChanged: onRoleChanged,
                  ),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    items: const ['All Statuses', 'Online', 'Away', 'Offline'],
                    value: selectedStatus,
                    onChanged: onStatusChanged,
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    label: const Text('Live Filters'),
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

class _TeamRenderError extends StatelessWidget {
  final String message;
  const _TeamRenderError({required this.message});

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
              'Team view failed to render',
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

class _TeamTableCard extends StatelessWidget {
  final List<_TeamMember> members;
  final int totalCount;
  const _TeamTableCard({
    required this.members,
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
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No team records match this live filter.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1080),
                child: Column(
                  children: [
                    const _TeamTableHeader(),
                    for (final member in members) _TeamTableRow(member: member),
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
                  'SHOWING ${members.length} OF $totalCount TEAM MEMBERS',
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

class _TeamTableHeader extends StatelessWidget {
  const _TeamTableHeader();

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
          SizedBox(width: 250, child: Text('MEMBER', style: _headerStyle)),
          SizedBox(width: 170, child: Text('ROLE', style: _headerStyle)),
          SizedBox(width: 130, child: Text('STATUS', style: _headerStyle)),
          SizedBox(width: 170, child: Text('ASSIGNMENTS', style: _headerStyle)),
          SizedBox(width: 120, child: Text('LAST LOGIN', style: _headerStyle)),
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

class _TeamTableRow extends StatelessWidget {
  final _TeamMember member;
  const _TeamTableRow({required this.member});

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
                ClipOval(
                  child: member.avatarUrl == null
                      ? Container(
                          width: 40,
                          height: 40,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                        )
                      : Image.network(
                          member.avatarUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111418),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        member.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 170,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: member.roleTone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                member.role,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: member.roleTone,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: member.statusTone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: member.statusTone.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: member.statusTone, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    member.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: member.statusTone,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.assignmentsPrimary,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111418),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  member.assignmentsSecondary,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              member.lastLogin,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionIcon(
                  icon: Icons.edit_note_rounded,
                  color: const Color(0xFF2B8CEE),
                  onTap: () {},
                ),
                _ActionIcon(
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF64748B),
                  onTap: () {},
                ),
                _ActionIcon(
                  icon: Icons.person_remove_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: () {},
                ),
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
  final VoidCallback onTap;
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
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

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tone;
  final Color bg;
  const _SummaryMetricCard({
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

class _TeamMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final Color roleTone;
  final String status;
  final Color statusTone;
  final int patientCount;
  final String assignmentsPrimary;
  final String assignmentsSecondary;
  final String lastLogin;
  final String? avatarUrl;
  final DateTime? lastActiveAt;

  const _TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleTone,
    required this.status,
    required this.statusTone,
    required this.patientCount,
    required this.assignmentsPrimary,
    required this.assignmentsSecondary,
    required this.lastLogin,
    this.avatarUrl,
    required this.lastActiveAt,
  });
}
