import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/pages/listen_page.dart';
import 'package:therapii/pages/new_patient_info_page.dart';
import 'package:therapii/pages/therapist_details_page.dart';
import 'package:therapii/pages/patient_chat_page.dart';
import 'package:therapii/pages/patient_profile_page.dart';
import 'package:therapii/services/invitation_service.dart';
import 'package:therapii/services/user_service.dart';
import 'package:therapii/models/invitation_code.dart';
import 'package:therapii/models/user.dart' as AppUser;
import 'package:therapii/widgets/shimmer_widgets.dart';
import 'package:therapii/widgets/common_settings_drawer.dart';
import 'package:therapii/services/chat_service.dart';
import 'package:therapii/models/chat_conversation.dart';
import 'package:therapii/services/ai_conversation_service.dart';
import 'package:therapii/models/ai_conversation_summary.dart';
import 'package:therapii/pages/ai_summary_detail_page.dart';
import 'package:therapii/services/voice_checkin_service.dart';
import 'package:therapii/models/voice_checkin.dart';
import 'package:therapii/pages/voice_checkin_detail_page.dart';
import 'package:therapii/widgets/therapist_approval_gate.dart';
import 'package:therapii/theme_mode_controller.dart';

enum TopNavSection { patients, listen }

class MyPatientsPage extends StatefulWidget {
  const MyPatientsPage({super.key});

  @override
  State<MyPatientsPage> createState() => _MyPatientsPageState();
}

class _MyPatientsPageState extends State<MyPatientsPage> {
  final TopNavSection _selected = TopNavSection.patients;

  final _invitationService = InvitationService();
  final _userService = UserService();
  final _chatService = ChatService();
  final _aiService = AiConversationService();

  bool _loading = true;
  String? _error;
  List<AppUser.User> _activePatients = [];
  List<InvitationCode> _pendingInvites = [];
  String? _therapistId;
  bool _showAllPatients = false;
  String? _approvalStatus;
  DateTime? _approvalRequestedAt;
  bool _checkingApproval = false;
  bool _signingOut = false;
  AppUser.User? _therapist;

  String _truncate(String text, {int max = 60}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max).trim()}...';
  }

  String _formatMonthDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthLabel = months[date.month - 1];
    return '$monthLabel ${date.day}';
  }

  String _subtitleForConversation(ChatConversation? convo) {
    final lastAt = convo?.lastMessageAt;
    if (lastAt != null) {
      return 'Last Message ${_formatMonthDay(lastAt)}';
    }

    final lastMessage = (convo?.lastMessageText ?? '').trim();
    if (lastMessage.isNotEmpty) {
      return _truncate(lastMessage, max: 40);
    }

    return 'Last Message —';
  }

  Widget _buildPatientTile(AppUser.User user) {
    final displayName = user.fullName.isNotEmpty ? user.fullName : user.email;
    final therapistId = _therapistId;
    Future openChat() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientChatPage(otherUser: user),
          ),
        );

    if (therapistId == null) {
      return _PatientTile(
        name: displayName,
        lastMessage: 'Last Message —',
        onOpenChat: openChat,
      );
    }

    return StreamBuilder<ChatConversation?>(
      stream: _chatService.streamConversation(
        therapistId: therapistId,
        patientId: user.id,
      ),
      builder: (context, snapshot) {
        final convo = snapshot.data;
        final subtitle = _subtitleForConversation(convo);
        final unread = convo?.therapistUnreadCount ?? 0;
        return _PatientTile(
          name: displayName,
          lastMessage: subtitle,
          unreadCount: unread,
          onOpenChat: openChat,
          onViewDetails: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatientProfilePage(
                patient: user,
                therapistId: therapistId,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveAiConversationsSection(BuildContext context) {
    final therapistId = _therapistId;
    if (therapistId == null) {
      return const SizedBox.shrink();
    }

    final patientLookup = {
      for (final patient in _activePatients) patient.id: patient,
    };

    return StreamBuilder<List<ChatConversation>>(
      stream: _chatService.streamTherapistConversations(
        therapistId: therapistId,
        limit: 20,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: const [
              ShimmerListTile(),
              SizedBox(height: 12),
              ShimmerListTile(),
            ],
          );
        }

        if (snapshot.hasError) {
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Failed to load AI conversations. Please try again later.',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          );
        }

        final conversations = snapshot.data ?? [];
        if (conversations.isEmpty) {
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text(
              'No active AI conversations yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          );
        }

        final tiles = <Widget>[];
        for (var i = 0; i < conversations.length; i++) {
          final convo = conversations[i];
          final patient = patientLookup[convo.patientId];
          tiles.add(
            _AiConversationTile(
              name: _patientDisplayName(patient),
              subtitle: _subtitleForConversation(convo),
              unreadCount: convo.therapistUnreadCount,
              onTap: patient != null
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatientChatPage(otherUser: patient),
                        ),
                      )
                  : null,
            ),
          );
          if (i != conversations.length - 1) {
            tiles.add(const SizedBox(height: 12));
          }
        }

        return Column(children: tiles);
      },
    );
  }

  Widget _buildAiSummariesSection(BuildContext context) {
    final therapistId = _therapistId;
    if (therapistId == null) {
      return const SizedBox.shrink();
    }

    final patientLookup = {for (final p in _activePatients) p.id: p};

    return StreamBuilder<List<AiConversationSummary>>(
      stream: _aiService.streamTherapistSummaries(therapistId: therapistId, limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: const [ShimmerListTile(), SizedBox(height: 12), ShimmerListTile()]);
        }
        if (snapshot.hasError) {
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Failed to load AI summaries. Please try again later.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text('No AI summaries yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          );
        }

        final tiles = <Widget>[];
        for (var i = 0; i < items.length; i++) {
          final s = items[i];
          final patient = patientLookup[s.patientId];
          tiles.add(_AiSummaryTile(
            name: _patientDisplayName(patient),
            dateLabel: _formatMonthDay(s.createdAt),
            snippet: _truncate(s.summary, max: 70),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AiSummaryDetailPage(summary: s)),
            ),
          ));
          if (i != items.length - 1) tiles.add(const SizedBox(height: 12));
        }
        return Column(children: tiles);
      },
    );
  }

  Widget _buildVoiceCheckinsSection(BuildContext context) {
    final therapistId = _therapistId;
    if (therapistId == null) return const SizedBox.shrink();

    final patientLookup = {for (final p in _activePatients) p.id: p};
    final svc = VoiceCheckinService();

    return StreamBuilder<List<VoiceCheckin>>(
      stream: svc.streamTherapistCheckins(therapistId: therapistId, limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: const [ShimmerListTile(), SizedBox(height: 12), ShimmerListTile()]);
        }
        if (snapshot.hasError) {
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Failed to load voice check-ins. Please try again later.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text('No voice check-ins yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          );
        }

        final tiles = <Widget>[];
        for (var i = 0; i < items.length; i++) {
          final c = items[i];
          final patient = patientLookup[c.patientId];
          final name = _patientDisplayName(patient);
          tiles.add(_VoiceCheckinTile(
            name: name,
            dateLabel: _formatMonthDay(c.createdAt),
            duration: Duration(seconds: c.durationSeconds),
            onOpen: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VoiceCheckinDetailPage(
                    checkin: c,
                    patient: patient,
                  ),
                ),
              );
            },
          ));
          if (i != items.length - 1) tiles.add(const SizedBox(height: 12));
        }
        return Column(children: tiles);
      },
    );
  }

  String _patientDisplayName(AppUser.User? user) {
    if (user == null) return 'Unknown patient';
    if (user.fullName.isNotEmpty) {
      return user.fullName;
    }
    return user.email;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _confirmAndDelete(InvitationCode inv) async {
    final me = FirebaseAuthManager().currentUser;
    if (me == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invitation?'),
        content: const Text('This will remove the invitation permanently. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _invitationService.deleteInvitation(invitationId: inv.id, therapistId: me.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation deleted')));
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadDataInternal(silentApprovalCheck: false);
  }

  Future<void> _loadDataInternal({required bool silentApprovalCheck}) async {
    try {
      final me = FirebaseAuthManager().currentUser;
      if (me == null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWelcomePage(initialTab: AuthTab.login)),
          (route) => false,
        );
        return;
      }

      final therapistId = me.uid;

      final therapistSnapshot = await FirebaseFirestore.instance.collection('therapists').doc(therapistId).get();
      final therapistData = therapistSnapshot.data() ?? <String, dynamic>{};
      final status = (therapistData['approval_status'] as String?)?.toLowerCase() ?? 'pending';
      final timestamp = (therapistData['approval_requested_at'] as Timestamp? ??
              therapistData['updated_at'] as Timestamp? ??
              therapistData['created_at'] as Timestamp?)
          ?.toDate();

      // Load therapist user for greeting/header
      AppUser.User? therapistUser;
      try {
        therapistUser = await _userService.getUser(therapistId);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _therapistId = therapistId;
        _approvalStatus = status;
        _approvalRequestedAt = timestamp;
        _therapist = therapistUser;
      });

      if (status != 'approved') {
        if (!mounted) return;
        setState(() {
          _activePatients = [];
          _pendingInvites = [];
          _loading = false;
          _showAllPatients = false;
        });
        return;
      }

      final invites = await _invitationService.getTherapistInvitations(therapistId);
      final accepted = invites.where((i) => i.isUsed && i.patientId != null).toList();
      final pending = invites.where((i) => !i.isUsed).toList();

      final patientIds = accepted.map((e) => e.patientId!).toSet().toList();
      final users = await _userService.getUsersByIds(patientIds);

      if (!mounted) return;
      setState(() {
        _activePatients = users;
        _pendingInvites = pending;
        _loading = false;
        _showAllPatients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshApprovalStatus() async {
    if (_checkingApproval) return;
    setState(() => _checkingApproval = true);
    await _loadDataInternal(silentApprovalCheck: true);
    if (!mounted) return;
    setState(() {
      _checkingApproval = false;
      _loading = false;
    });
  }

  Future<void> _openTherapistProfileEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TherapistDetailsPage()),
    );
    if (!mounted) return;
    await _loadDataInternal(silentApprovalCheck: true);
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await FirebaseAuthManager().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWelcomePage(initialTab: AuthTab.login)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const int maxVisiblePatients = 10;
    final bool hasMorePatients = _activePatients.length > maxVisiblePatients;
    final List<AppUser.User> patientsToDisplay =
        _showAllPatients || !hasMorePatients ? _activePatients : _activePatients.take(maxVisiblePatients).toList();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 1200 ? 40.0 : screenWidth >= 900 ? 28.0 : 16.0;
    final contentMaxWidth = screenWidth >= 1400 ? 980.0 : 900.0;
    final appBarDivider = theme.colorScheme.outline.withValues(alpha: 0.12);
    final onSurface = theme.colorScheme.onSurface;
    final therapistName = _therapist?.fullName.isNotEmpty == true ? _therapist!.fullName : 'Therapist';
    final therapistInitial = (_therapist?.firstName ?? therapistName)[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF5F7FB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Patients',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.brightness_2_rounded,
            ),
            tooltip: 'Toggle theme',
            onPressed: themeModeController.toggleLightDark,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => showSettingsPopup(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: appBarDivider),
        ),
      ),
      body: SafeArea(
        child: Builder(builder: (innerContext) {
          if (!_loading) {
            final status = (_approvalStatus ?? '').toLowerCase();
            if (status.isNotEmpty && status != 'approved') {
              return TherapistApprovalGate(
                status: _approvalStatus ?? 'pending',
                requestedAt: _approvalRequestedAt,
                refreshing: _checkingApproval,
                signingOut: _signingOut,
                onRefresh: _refreshApprovalStatus,
                onUpdateProfile: _openTherapistProfileEditor,
                onSignOut: _signOut,
              );
            }
          }

          return RefreshIndicator.adaptive(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 640;
                      final useStackedActions = constraints.maxWidth < 760;
                      final actionGap = useStackedActions ? 12.0 : 16.0;
                      final inviteTile = _HeroTile(
                        gradient: true,
                        title: 'Invite New Patient',
                        subtitle: 'Share a code to securely connect.',
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NewPatientInfoPage()),
                        ),
                      );
                      final listenTile = _HeroTile(
                        gradient: false,
                        title: 'Listen',
                        subtitle: 'AI summaries, transcripts and voice updates.',
                        icon: Icons.graphic_eq_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ListenPage()),
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 24),
                            child: isCompact
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _HeaderTextBlock(
                                        greeting: _greeting(),
                                        therapistName: therapistName,
                                      ),
                                      const SizedBox(height: 16),
                                      _TherapistAvatarChip(initial: therapistInitial),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _HeaderTextBlock(
                                          greeting: _greeting(),
                                          therapistName: therapistName,
                                        ),
                                      ),
                                      _TherapistAvatarChip(initial: therapistInitial),
                                    ],
                                  ),
                          ),
                          if (useStackedActions) ...[
                            inviteTile,
                            SizedBox(height: actionGap),
                            listenTile,
                          ] else
                            Row(
                              children: [
                                Expanded(flex: 11, child: inviteTile),
                                SizedBox(width: actionGap),
                                Expanded(flex: 10, child: listenTile),
                              ],
                            ),
                          const SizedBox(height: 28),
                          _ActivePatientsCard(
                            isLoading: _loading,
                            error: _error,
                            patients: patientsToDisplay,
                            hasMorePatients: hasMorePatients,
                            showAllPatients: _showAllPatients,
                            onShowAll: () => setState(() => _showAllPatients = true),
                            onManage: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NewPatientInfoPage()),
                            ),
                            buildPatientTile: _buildPatientTile,
                          ),
                          const SizedBox(height: 26),
                          _PendingInvitesCard(
                            invites: _pendingInvites,
                            onDelete: _confirmAndDelete,
                            onGenerateInvite: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NewPatientInfoPage()),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeaderTextBlock extends StatelessWidget {
  final String greeting;
  final String therapistName;
  const _HeaderTextBlock({
    required this.greeting,
    required this.therapistName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: theme.textTheme.titleMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.58),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          therapistName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your patients, invites and conversations in one place.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: onSurface.withValues(alpha: 0.5),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TherapistAvatarChip extends StatelessWidget {
  final String initial;
  const _TherapistAvatarChip({required this.initial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  final TopNavSection selected;
  final VoidCallback onMenuTap;
  final VoidCallback onPatientsTap;
  final VoidCallback onListenTap;
  const _TopNav({
    required this.selected,
    required this.onMenuTap,
    required this.onPatientsTap,
    required this.onListenTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        IconButton(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu),
          color: theme.colorScheme.onSurface,
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HeaderTab(label: 'My Patients', selected: selected == TopNavSection.patients, color: primary, onTap: onPatientsTap),
              _HeaderTab(label: 'Listen', selected: selected == TopNavSection.listen, color: primary, onTap: onListenTap),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  const _HeaderTab({required this.label, required this.selected, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? color : inactiveColor,
        );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: selected
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: 3),
                ),
              )
            : null,
        child: Text(label, style: textStyle),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final Color blue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onOpenChat;
  final int unreadCount;
  const _PatientTile({
    required this.name,
    required this.lastMessage,
    Color? blue,
    this.onViewDetails,
    this.onOpenChat,
    this.unreadCount = 0,
  }) : blue = blue ?? const Color(0xFF2B8CEE);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(18);
    final borderColor = colorScheme.outline.withValues(alpha: 0.1);
    final blueColor = blue;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5));

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onViewDetails,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF1F4FA),
                  child: Icon(Icons.person, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 6),
                      _UnreadBadge(count: unreadCount),
                    ],
                    IconButton(
                      onPressed: onOpenChat,
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      color: blueColor.withValues(alpha: 0.8),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                      tooltip: 'Message History',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiConversationTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final int unreadCount;
  final VoidCallback? onTap;
  const _AiConversationTile({
    required this.name,
    required this.subtitle,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(16);
    final borderColor = colorScheme.outline.withOpacity(0.2);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.smart_toy_outlined, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 12),
                  _UnreadBadge(count: unreadCount),
                ],
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceCheckinTile extends StatelessWidget {
  final String name;
  final String dateLabel;
  final Duration duration;
  final VoidCallback? onOpen;
  const _VoiceCheckinTile({
    required this.name,
    required this.dateLabel,
    required this.duration,
    this.onOpen,
  });

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(16);
    final borderColor = colorScheme.outline.withOpacity(0.2);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE9EAED),
                child: Icon(Icons.mic, color: Colors.grey),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateLabel • ${_formatDuration(duration)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
                color: theme.colorScheme.primary,
                tooltip: 'Open audio',
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AiSummaryTile extends StatelessWidget {
  final String name;
  final String dateLabel;
  final String snippet;
  final VoidCallback? onTap;
  const _AiSummaryTile({
    required this.name,
    required this.dateLabel,
    required this.snippet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(16);
    final borderColor = colorScheme.outline.withOpacity(0.2);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.notes_rounded, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(dateLabel, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                      const SizedBox(height: 6),
                      Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : count.toString();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        display,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final InvitationCode invitation;
  final VoidCallback? onDelete;
  const _InviteTile({required this.invitation, VoidCallback? onDelete}) : onDelete = onDelete;

  String _remainingText(DateTime now, DateTime expiry) {
    final diff = expiry.difference(now);
    if (diff.isNegative) return 'Expired';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours >= 1) {
      return 'Expires in ${hours}h ${minutes}m';
    }
    return 'Expires in ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.4);
    final now = DateTime.now();
    final showCode = now.isBefore(invitation.expiresAt);
    final secondary = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7));

    return Material(
      color: theme.colorScheme.surface,
      shape: border,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(side: BorderSide(color: borderColor), borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.mail_outline, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  invitation.patientFirstName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(invitation.patientEmail, style: secondary),
                const SizedBox(height: 6),
                if (showCode)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Code: ${invitation.code}',
                          style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_remainingText(now, invitation.expiresAt), style: secondary),
                    ],
                  )
                else
                  Text('Invitation expired', style: secondary),
              ]),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Delete invitation',
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  final String text;
  const _CornerBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF09B58),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class _HeroTile extends StatefulWidget {
  final bool gradient;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroTile({
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeroTile> createState() => _HeroTileState();
}

class _HeroTileState extends State<_HeroTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = widget.gradient ? null : (isDark ? scheme.surfaceContainerHighest : Colors.white);
    final borderColor = widget.gradient ? Colors.transparent : scheme.outline.withValues(alpha: 0.1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 170),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: background,
            gradient: widget.gradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.85),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.09 : 0.045),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.gradient
                          ? Colors.white.withValues(alpha: 0.2)
                          : scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.gradient ? scheme.onPrimary : scheme.primary,
                      size: 22,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.gradient
                        ? scheme.onPrimary.withValues(alpha: 0.7)
                        : scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
                ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.gradient ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.gradient
                      ? scheme.onPrimary.withValues(alpha: 0.8)
                      : scheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Drawer and static content were extracted to CommonSettingsDrawer for reuse.

/// Premium Active Patients Card - styled like screenshot design
class _ActivePatientsCard extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<AppUser.User> patients;
  final bool hasMorePatients;
  final bool showAllPatients;
  final VoidCallback onShowAll;
  final VoidCallback onManage;
  final Widget Function(AppUser.User) buildPatientTile;

  const _ActivePatientsCard({
    required this.isLoading,
    this.error,
    required this.patients,
    required this.hasMorePatients,
    required this.showAllPatients,
    required this.onShowAll,
    required this.onManage,
    required this.buildPatientTile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.5),
              ),
              child: Center(
                child: Icon(
                  Icons.circle,
                  color: scheme.primary,
                  size: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active patients',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patients.isEmpty
                        ? 'No active patients yet. Share an invitation code to begin collaborating.'
                        : '${patients.length} patient${patients.length == 1 ? '' : 's'} connected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isLoading) ...[
          const SizedBox(height: 18),
          const ShimmerListTile(),
          const SizedBox(height: 12),
          const ShimmerListTile(),
        ] else if (error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: scheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ] else if (patients.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final patient in patients) ...[
            buildPatientTile(patient),
            const SizedBox(height: 12),
          ],
          if (hasMorePatients && !showAllPatients)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onShowAll,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Show all patients'),
                ),
              ),
            ),
        ] else ...[
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No patients connected yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(onPressed: onManage, child: const Text('Invite patient')),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'No patients connected yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                          TextButton(onPressed: onManage, child: const Text('Invite patient')),
                        ],
                      ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Premium Pending Invites Card - styled like Billing page containers
class _PendingInvitesCard extends StatelessWidget {
  final List<InvitationCode> invites;
  final Future<void> Function(InvitationCode) onDelete;
  final VoidCallback onGenerateInvite;

  const _PendingInvitesCard({
    required this.invites,
    required this.onDelete,
    required this.onGenerateInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending invitations',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invites.length} invitation${invites.length == 1 ? '' : 's'} waiting for response',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (invites.isEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No pending invitations right now.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: onGenerateInvite,
                            child: const Text('Create invite'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'No pending invitations right now.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onGenerateInvite,
                            child: const Text('Create invite'),
                          ),
                        ],
                      ),
              );
            },
          )
        else ...[
          for (var i = 0; i < invites.length; i++) ...[
            _PremiumInviteTile(invitation: invites[i], onDelete: () => onDelete(invites[i])),
            if (i < invites.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

/// Premium Invite Tile - refined styling
class _PremiumInviteTile extends StatelessWidget {
  final InvitationCode invitation;
  final VoidCallback? onDelete;
  const _PremiumInviteTile({required this.invitation, this.onDelete});

  String _remainingText(DateTime now, DateTime expiry) {
    final diff = expiry.difference(now);
    if (diff.isNegative) return 'Expired';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours >= 1) return '${hours}h ${minutes}m remaining';
    return '${minutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final showCode = now.isBefore(invitation.expiresAt);
    final isUrgent = invitation.expiresAt.difference(now).inHours < 6;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: isUrgent && showCode
              ? Colors.amber.withValues(alpha: 0.35)
              : scheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF1F4FA),
            child: Text(
              invitation.patientFirstName.isNotEmpty
                  ? invitation.patientFirstName[0].toUpperCase()
                  : '?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.patientFirstName.isNotEmpty
                      ? invitation.patientFirstName
                      : invitation.patientEmail,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  invitation.patientEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                if (showCode)
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 14, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              invitation.code,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? Colors.amber.withValues(alpha: 0.15)
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _remainingText(now, invitation.expiresAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isUrgent ? Colors.amber.shade800 : scheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Invitation expired',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: scheme.error.withValues(alpha: 0.7),
            tooltip: 'Delete invitation',
          ),
        ],
      ),
    );
  }
}
