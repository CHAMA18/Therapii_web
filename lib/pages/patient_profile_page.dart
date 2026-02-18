import 'package:flutter/material.dart';
import 'package:therapii/models/ai_conversation_summary.dart';
import 'package:therapii/models/chat_message.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/models/voice_checkin.dart';
import 'package:therapii/pages/patient_chat_page.dart';
import 'package:therapii/pages/patient_profile_details_page.dart';
import 'package:therapii/services/ai_conversation_service.dart';
import 'package:therapii/services/chat_service.dart';
import 'package:therapii/services/voice_checkin_service.dart';

class PatientProfilePage extends StatefulWidget {
  final app_user.User patient;
  final String therapistId;
  const PatientProfilePage({super.key, required this.patient, required this.therapistId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _chatService = ChatService();
  final _aiConversationService = AiConversationService();
  final _voiceCheckinService = VoiceCheckinService();
  final _scrollController = ScrollController();
  final _activeConversationsKey = GlobalKey();
  final _recentConversationsKey = GlobalKey();
  final _summariesKey = GlobalKey();
  final _voiceCheckinsKey = GlobalKey();

  Future<void> _openChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientChatPage(otherUser: widget.patient),
      ),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
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
              Text(
                'Your feedback helps personalize the AI model\'s responses for this patient. Share what worked well or areas for improvement.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., "The AI should use more empathetic language when discussing anxiety..."',
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = widget.patient;
    final displayName = patient.fullName.trim().isNotEmpty ? patient.fullName : patient.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          color: scheme.onSurface,
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.primary.withOpacity(0.08),
                            padding: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.primary.withOpacity(0.15)),
                          ),
                          child: Text(
                            'Patient Profile',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: scheme.primary.withOpacity(0.12),
                          backgroundImage: (patient.avatarUrl ?? '').isNotEmpty ? NetworkImage(patient.avatarUrl!) : null,
                          child: (patient.avatarUrl ?? '').isNotEmpty
                              ? null
                              : Icon(Icons.person, size: 42, color: scheme.primary),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patient.email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.7),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if ((patient.phoneNumber ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  patient.phoneNumber!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoCols = constraints.maxWidth > 900;
                        final cards = [
                          _quickLink('Active AI Conversations', Icons.chat_bubble_rounded, _openDetails, SectionTarget.active),
                          _quickLink('Recent AI Conversations', Icons.forum_outlined, _openDetails, SectionTarget.recent),
                          _quickLink('AI Summaries', Icons.summarize_rounded, _openDetails, SectionTarget.summaries),
                          _quickLink('Voice Check-ins', Icons.mic_rounded, _openDetails, SectionTarget.voice),
                        ];
                        if (twoCols) {
                          return GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 3.8,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: cards,
                          );
                        }
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: cards,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickLink(String label, IconData icon, void Function(SectionTarget) onNavigate, SectionTarget target) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: () => onNavigate(target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(SectionTarget target) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientProfileDetailsPage(
          patient: widget.patient,
          therapistId: widget.therapistId,
          initialTarget: target,
        ),
      ),
    );
  }
}

enum SectionTarget { active, recent, summaries, voice }

class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Color color;

  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.blur_on_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class LoadingInfo extends StatelessWidget {
  final String text;
  const LoadingInfo({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLinkButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        foregroundColor: scheme.onSurface,
        backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class MessagePreview extends StatelessWidget {
  final ChatMessage message;
  final String therapistId;
  const MessagePreview({super.key, required this.message, required this.therapistId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTherapist = message.senderId == therapistId;
    final prefix = isTherapist ? 'You' : 'Patient';
    final date = message.sentAt;
    final formatted = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final text = message.text.trim().isEmpty ? '(Attachment)' : message.text.trim();
    final truncated = text.length > 90 ? '${text.substring(0, 87)}…' : text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTherapist ? scheme.primary.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(isTherapist ? 0.0 : 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isTherapist ? Icons.account_circle : Icons.person_outline, size: 18, color: scheme.onSurface.withOpacity(0.75)),
              const SizedBox(width: 6),
              Text(
                '$prefix • $formatted',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            truncated,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationCard extends StatelessWidget {
  final AiConversationSummary summary;
  final VoidCallback onTap;
  final void Function(AiConversationSummary)? onFeedback;
  const ConversationCard({super.key, required this.summary, required this.onTap, this.onFeedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = summary.createdAt;
    final formatted = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final preview = summary.summary.length > 120 ? '${summary.summary.substring(0, 117)}…' : summary.summary;
    final hasFeedback = summary.therapistFeedback?.isNotEmpty == true;

    return InkWell(
      onTap: onTap,
      onLongPress: onFeedback != null ? () => onFeedback!(summary) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasFeedback ? scheme.primary.withOpacity(0.3) : scheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatted,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasFeedback)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review_rounded, size: 12, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Feedback',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onFeedback != null)
                  IconButton(
                    onPressed: () => onFeedback!(summary),
                    icon: Icon(
                      hasFeedback ? Icons.edit_note_rounded : Icons.rate_review_outlined,
                      color: scheme.primary,
                      size: 22,
                    ),
                    tooltip: hasFeedback ? 'Edit feedback' : 'Add feedback',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              preview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.4,
              ),
            ),
            if (onFeedback != null && !hasFeedback) ...[
              const SizedBox(height: 8),
              Text(
                'Long press or tap the icon to add feedback',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VoiceCheckinCard extends StatelessWidget {
  final VoiceCheckin checkin;
  const VoiceCheckinCard({super.key, required this.checkin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = checkin.createdAt;
    final formatted = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final durationMinutes = checkin.durationSeconds ~/ 60;
    final durationSeconds = checkin.durationSeconds % 60;
    final durationStr = '$durationMinutes:${durationSeconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: scheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.mic_rounded, color: scheme.error, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Check-in',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formatted • $durationStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.65),
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
