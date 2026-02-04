import 'package:flutter/material.dart';
import 'package:therapii/models/ai_conversation_summary.dart';
import 'package:therapii/models/chat_message.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/models/voice_checkin.dart';
import 'package:therapii/pages/ai_summary_detail_page.dart';
import 'package:therapii/pages/patient_chat_page.dart';
import 'package:therapii/services/ai_conversation_service.dart';
import 'package:therapii/services/chat_service.dart';
import 'package:therapii/services/voice_checkin_service.dart';
import 'package:therapii/widgets/primary_button.dart';
import 'patient_profile_page.dart';

class PatientProfileDetailsPage extends StatefulWidget {
  final app_user.User patient;
  final String therapistId;
  final SectionTarget initialTarget;

  const PatientProfileDetailsPage({
    super.key,
    required this.patient,
    required this.therapistId,
    required this.initialTarget,
  });

  @override
  State<PatientProfileDetailsPage> createState() => _PatientProfileDetailsPageState();
}

class _PatientProfileDetailsPageState extends State<PatientProfileDetailsPage> {
  final _chatService = ChatService();
  final _aiConversationService = AiConversationService();
  final _voiceCheckinService = VoiceCheckinService();

  final _scrollController = ScrollController();
  final _activeKey = GlobalKey();
  final _recentKey = GlobalKey();
  final _summaryKey = GlobalKey();
  final _voiceKey = GlobalKey();

  final Set<String> _contextMessages = {};
  final Set<String> _contextSummaries = {};
  final Set<String> _contextVoices = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToTarget(widget.initialTarget));
  }

  void _jumpToTarget(SectionTarget target) {
    GlobalKey key;
    switch (target) {
      case SectionTarget.active:
        key = _activeKey;
        break;
      case SectionTarget.recent:
        key = _recentKey;
        break;
      case SectionTarget.summaries:
        key = _summaryKey;
        break;
      case SectionTarget.voice:
        key = _voiceKey;
        break;
    }
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientChatPage(otherUser: widget.patient),
      ),
    );
  }

  Future<void> _showFeedbackBottomSheet(AiConversationSummary summary) async {
    final controller = TextEditingController(text: summary.therapistFeedback ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.rate_review_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.therapistFeedback != null ? 'Edit Model Feedback' : 'Provide Model Feedback',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Help improve AI responses',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., "Use more empathetic language when discussing anxiety..."',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Feedback'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        await _aiConversationService.saveTherapistFeedback(
          summaryId: summary.id,
          feedback: result,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback saved successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Overview'),
        centerTitle: true,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ContextHeader(title: 'Context Vault', subtitle: 'Curate conversations and signals to inform the AI model.'),
          const SizedBox(height: 12),
          _ContextSection(
            key: _recentKey,
            title: 'Chat Messages',
            description: 'Select key exchanges to feed as AI context.',
            icon: Icons.forum_outlined,
            color: scheme.primary,
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(
                therapistId: widget.therapistId,
                patientId: patient.id,
                limit: 80,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingInfo(text: 'Loading messages…');
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Text('No messages yet.', style: theme.textTheme.bodyMedium);
                }
                return Column(
                  children: messages.reversed.take(10).map((m) {
                    final selected = _contextMessages.contains(m.id);
                    final prefix = m.senderId == widget.therapistId ? 'You' : 'Patient';
                    final ts = '${m.sentAt.month}/${m.sentAt.day} ${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}';
                    return _ContextTile(
                      title: '$prefix • $ts',
                      body: m.text.isEmpty ? '(Attachment)' : m.text,
                      selected: selected,
                      onToggle: () => _toggleContext(_contextMessages, m.id, 'Message'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _ContextSection(
            key: _summaryKey,
            title: 'AI Summaries',
            description: 'Pin summaries to guide the next AI session.',
            icon: Icons.summarize_rounded,
            color: scheme.tertiary,
            child: StreamBuilder<List<AiConversationSummary>>(
              stream: _aiConversationService.streamPatientSummaries(patientId: patient.id, limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingInfo(text: 'Loading summaries…');
                }
                final summaries = snapshot.data ?? [];
                if (summaries.isEmpty) {
                  return Text('No AI summaries yet.', style: theme.textTheme.bodyMedium);
                }
                return Column(
                  children: summaries.map((s) {
                    final selected = _contextSummaries.contains(s.id);
                    final ts = '${s.createdAt.month}/${s.createdAt.day}';
                    return _ContextTile(
                      title: 'Summary • $ts',
                      body: s.summary,
                      selected: selected,
                      onToggle: () => _toggleContext(_contextSummaries, s.id, 'Summary'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _ContextSection(
            key: _voiceKey,
            title: 'Voice Check-ins',
            description: 'Include voice check-ins as contextual signals.',
            icon: Icons.mic_rounded,
            color: scheme.error,
            child: StreamBuilder<List<VoiceCheckin>>(
              stream: _voiceCheckinService.streamPatientCheckins(
                therapistId: widget.therapistId,
                patientId: patient.id,
                limit: 10,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingInfo(text: 'Loading voice check-ins…');
                }
                final checkins = snapshot.data ?? [];
                if (checkins.isEmpty) {
                  return Text('No voice check-ins yet.', style: theme.textTheme.bodyMedium);
                }
                return Column(
                  children: checkins.map((c) {
                    final selected = _contextVoices.contains(c.id);
                    final ts = '${c.createdAt.month}/${c.createdAt.day} • ${c.durationSeconds}s';
                    return _ContextTile(
                      title: 'Voice Check-in • $ts',
                      body: 'Audio recording (${c.durationSeconds}s)',
                      selected: selected,
                      onToggle: () => _toggleContext(_contextVoices, c.id, 'Voice check-in'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleContext(Set<String> bucket, String id, String label) {
    setState(() {
      if (bucket.contains(id)) {
        bucket.remove(id);
      } else {
        bucket.add(id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(bucket.contains(id)
            ? '$label added to AI context'
            : '$label removed from AI context'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ContextHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ContextHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ContextSection({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(description, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.65))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ContextTile extends StatelessWidget {
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onToggle;

  const _ContextTile({
    required this.title,
    required this.body,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? scheme.primary.withOpacity(0.08) : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? scheme.primary.withOpacity(0.3) : scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: selected, onChanged: (_) => onToggle(), activeColor: scheme.primary),
        ],
      ),
    );
  }
}
