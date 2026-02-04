import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/models/chat_conversation.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/models/voice_checkin.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/pages/my_patients_page.dart';
import 'package:therapii/pages/patient_chat_page.dart';
import 'package:therapii/pages/therapist_voice_conversation_page.dart';
import 'package:therapii/services/chat_service.dart';
import 'package:therapii/services/invitation_service.dart';
import 'package:therapii/services/user_service.dart';
import 'package:therapii/services/voice_checkin_service.dart';
import 'package:therapii/widgets/shimmer_widgets.dart';
import 'package:therapii/pages/voice_checkin_detail_page.dart';
import 'package:therapii/widgets/common_settings_drawer.dart';

class ListenPage extends StatefulWidget {
  const ListenPage({super.key});

  @override
  State<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends State<ListenPage> {
  final _invitationService = InvitationService();
  final _userService = UserService();
  final _chatService = ChatService();
  final _voiceService = VoiceCheckinService();

  bool _loading = true;
  String? _error;
  List<app_user.User> _activePatients = [];
  String? _therapistId;
  app_user.User? _therapistUser;

  @override
  void initState() {
    super.initState();
    _loadActivePatients();
  }

  Future<void> _loadActivePatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
      final acceptedInvitations = await _invitationService.getAcceptedInvitationsForTherapist(therapistId);
      final patientIds = acceptedInvitations.map((inv) => inv.patientId).whereType<String>().toSet().toList();
      final users = await _userService.getUsersByIds(patientIds);
      final therapistUser = await _userService.getUser(therapistId);

      final lookup = {for (final user in users) user.id: user};
      final orderedUsers = acceptedInvitations
          .map((inv) => lookup[inv.patientId])
          .whereType<app_user.User>()
          .toList();

      if (!mounted) return;
      setState(() {
        _therapistId = therapistId;
        _therapistUser = therapistUser;
        _activePatients = orderedUsers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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

  Widget _buildPatientTile(app_user.User user) {
    final displayName = user.fullName.isNotEmpty ? user.fullName : user.email;
    final therapistId = _therapistId;

    if (therapistId == null) {
      return _WebPatientTile(
        name: displayName,
        lastMessage: 'Last Message —',
        onTap: null,
      );
    }

    return StreamBuilder<ChatConversation?>(
      stream: _chatService.streamConversation(therapistId: therapistId, patientId: user.id),
      builder: (context, snapshot) {
        final subtitle = _subtitleForConversation(snapshot.data);
        return _WebPatientTile(
          name: displayName,
          lastMessage: subtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatientChatPage(otherUser: user),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startTherapistRecordingFlow() async {
    if (_activePatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active patients to record for.')));
      return;
    }

    final selected = await showModalBottomSheet<app_user.User>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecordPatientSelectionSheet(patients: _activePatients),
    );

    if (selected != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TherapistVoiceConversationPage(patient: selected)),
      );
    }
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.error.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: scheme.error.withValues(alpha: 0.2), blurRadius: 28, offset: const Offset(0, 18), spreadRadius: -6),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.warning_rounded, color: scheme.error),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'We hit a snag syncing your workspace.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something unexpected happened.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onErrorContainer.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => _loadActivePatients(),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Try again'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyPatientsPage()),
                ),
                child: const Text('Open patient hub'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePatientsSection(BuildContext context, bool isWideLayout) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientCount = _activePatients.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active patients',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your currently enrolled patients',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Column(
              children: [
                ShimmerListTile(),
                SizedBox(height: 12),
                ShimmerListTile(),
              ],
            )
          else if (patientCount == 0)
            _buildEmptyPatientsPlaceholder(context, isDark)
          else
            Column(
              children: [
                for (var i = 0; i < _activePatients.length; i++) ...[
                  _buildPatientTile(_activePatients[i]),
                  if (i != _activePatients.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatientsPlaceholder(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          'Add more patients to see them here',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceCheckinsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final therapistId = _therapistId;
    final patientLookup = {for (final p in _activePatients) p.id: p};

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4C1D1D) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.mic,
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Voice check-ins',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // New Record button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _activePatients.isEmpty ? null : _startTherapistRecordingFlow,
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: Text(
                'New Record',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Review recorded reflections and open them to listen or download.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (therapistId == null)
            Text(
              'Link a patient to begin receiving voice reflections.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            )
          else
            StreamBuilder<List<VoiceCheckin>>(
              stream: _voiceService.streamTherapistCheckins(therapistId: therapistId, limit: 20),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      ShimmerListTile(),
                      SizedBox(height: 12),
                      ShimmerListTile(),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Failed to load voice check-ins.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Text(
                    'No voice check-ins yet. Encourage patients to send quick reflections.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  );
                }

                final children = <Widget>[];
                for (var i = 0; i < items.length; i++) {
                  final c = items[i];
                  final patient = patientLookup[c.patientId];
                  final name = patient == null
                      ? 'Unknown patient'
                      : (patient.fullName.isNotEmpty ? patient.fullName : patient.email);
                  children.add(_WebVoiceCheckinTile(
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
                  if (i != items.length - 1) {
                    children.add(const SizedBox(height: 12));
                  }
                }
                return Column(children: children);
              },
            ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                // View all check-ins - navigate to detailed list
              },
              child: Text(
                'View all check-ins',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideLayout = screenWidth >= 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Sticky Header
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                            ),
                            tooltip: 'Back',
                          ),
                        ),
                      ),
                      Text(
                        'Your Therapii Space',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => showSettingsPopup(context),
                            icon: Icon(
                              Icons.settings_outlined,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            tooltip: 'Settings',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadActivePatients,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWideLayout ? 24 : 20,
                  vertical: isWideLayout ? 40 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Overview',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                fontSize: isWideLayout ? 30 : 24,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MyPatientsPage()),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.groups_outlined, size: 20),
                              label: const Text('My patients'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (_error != null)
                          _buildErrorCard(context)
                        else if (isWideLayout)
                          // Wide layout: Two columns
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column - Active patients (larger)
                              Expanded(
                                flex: 7,
                                child: _buildActivePatientsSection(context, true),
                              ),
                              const SizedBox(width: 28),
                              // Right column - Voice check-ins
                              Expanded(
                                flex: 5,
                                child: _buildVoiceCheckinsSection(context),
                              ),
                            ],
                          )
                        else
                          // Narrow layout: Stacked
                          Column(
                            children: [
                              _buildActivePatientsSection(context, false),
                              const SizedBox(height: 20),
                              _buildVoiceCheckinsSection(context),
                            ],
                          ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebPatientTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final VoidCallback? onTap;
  const _WebPatientTile({required this.name, required this.lastMessage, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        hoverColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.transparent),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                      size: 28,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          lastMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebVoiceCheckinTile extends StatelessWidget {
  final String name;
  final String dateLabel;
  final Duration duration;
  final VoidCallback? onOpen;
  const _WebVoiceCheckinTile({required this.name, required this.dateLabel, required this.duration, this.onOpen});

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              Icons.keyboard_voice_outlined,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel • ${_formatDuration(duration)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: Icon(
              Icons.open_in_new,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            tooltip: 'Open audio',
          ),
        ],
      ),
    );
  }
}

class _RecordPatientSelectionSheet extends StatefulWidget {
  final List<app_user.User> patients;
  const _RecordPatientSelectionSheet({required this.patients});

  @override
  State<_RecordPatientSelectionSheet> createState() => _RecordPatientSelectionSheetState();
}

class _RecordPatientSelectionSheetState extends State<_RecordPatientSelectionSheet> {
  app_user.User? _selectedPatient;

  @override
  void initState() {
    super.initState();
    if (widget.patients.isNotEmpty) {
      _selectedPatient = widget.patients.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary.withValues(alpha: 0.1), scheme.primary.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mic_rounded, size: 36, color: scheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Record Voice Check-in',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a patient to create a personalized voice note',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _FeatureMiniCard(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Quick Notes',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _FeatureMiniCard(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Auto-Save',
                  color: Colors.teal,
                ),
                const SizedBox(width: 12),
                _FeatureMiniCard(
                  icon: Icons.share_outlined,
                  label: 'Easy Share',
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: widget.patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final patient = widget.patients[index];
                final isSelected = _selectedPatient?.id == patient.id;
                final name = patient.fullName.isNotEmpty ? patient.fullName : patient.email;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedPatient = patient),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primaryContainer : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? scheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isSelected ? scheme.primary : Colors.grey.shade300,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isSelected ? scheme.onPrimary : Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? scheme.onPrimaryContainer : null,
                              ),
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomPadding),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedPatient == null
                    ? null
                    : () => Navigator.of(context).pop(_selectedPatient),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Start Recording'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureMiniCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
