import 'package:flutter/material.dart';
import 'package:therapii/models/chat_message.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/pages/patient_chat_page.dart';
import 'package:therapii/services/chat_service.dart';
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
  State<PatientProfileDetailsPage> createState() =>
      _PatientProfileDetailsPageState();
}

class _PatientProfileDetailsPageState extends State<PatientProfileDetailsPage> {
  final _chatService = ChatService();

  final _scrollController = ScrollController();
  final _recentKey = GlobalKey();

  final Set<String> _contextMessages = {};
  final Map<String, TextEditingController> _feedbackControllers = {};

  @override
  void dispose() {
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  TextEditingController _getController(String id) {
    if (!_feedbackControllers.containsKey(id)) {
      _feedbackControllers[id] = TextEditingController();
    }
    return _feedbackControllers[id]!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _jumpToTarget(widget.initialTarget));
  }

  void _jumpToTarget(SectionTarget target) {
    GlobalKey key;
    switch (target) {
      case SectionTarget.recent:
        key = _recentKey;
        break;
      case SectionTarget.summaries:
        // summaries is obsolete, default to recent
        key = _recentKey;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Overview'),
        centerTitle: true,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ContextHeader(
              title: 'Context Vault',
              subtitle:
                  'Curate conversations and signals to inform the AI model.'),
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
                  return Text('No messages yet.',
                      style: theme.textTheme.bodyMedium);
                }
                return Column(
                  children: messages.reversed.take(10).map((m) {
                    final selected = _contextMessages.contains(m.id);
                    final prefix =
                        m.senderId == widget.therapistId ? 'You' : 'Client';
                    final ts =
                        '${m.sentAt.month}/${m.sentAt.day} ${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}';
                    return _ContextTile(
                      title: '$prefix • $ts',
                      body: m.text.isEmpty ? '(Attachment)' : m.text,
                      selected: selected,
                      feedbackController: _getController(m.id),
                      onToggle: () =>
                          _toggleContext(_contextMessages, m.id, 'Message'),
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 8))
        ],
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
                Text(title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurface.withOpacity(0.65))),
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 8))
        ],
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
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(description,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.65))),
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
  final String? actionLabel;
  final VoidCallback? onAction;
  final TextEditingController? feedbackController;

  const _ContextTile({
    required this.title,
    required this.body,
    required this.selected,
    required this.onToggle,
    this.actionLabel,
    this.onAction,
    this.feedbackController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? scheme.primary.withOpacity(0.08) : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected
                ? scheme.primary.withOpacity(0.3)
                : scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(actionLabel!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                  value: selected,
                  onChanged: (_) => onToggle(),
                  activeColor: scheme.primary),
            ],
          ),
          if (selected) ...[
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: 'Add feedback or notes for the AI model...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}
