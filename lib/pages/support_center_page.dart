import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A concierge-style support hub with rich visuals and direct contact actions.
/// Web-friendly responsive design.
class SupportCenterPage extends StatelessWidget {
  const SupportCenterPage({super.key});

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('We couldn\'t open that link. Please try again in a browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final quickActions = [
      _SupportAction(
        icon: Icons.mail_outline_rounded,
        title: 'Email our care team',
        description: 'Reach a licensed specialist in under 2 hours.',
        onTap: () => _launchUri(context, Uri.parse('mailto:support@trytherapii.com?subject=Therapii%20Support%20Request')),
      ),
    ];

    final faqs = const [
      _FaqItem(
        question: 'How do therapist codes work?',
        answer:
            'Each invitation code is generated uniquely for you by a therapist. Entering or tapping a code connects your profile, unlocking secure messaging, AI summaries, and voice sessions. Codes expire automatically for safety.',
      ),
      _FaqItem(
        question: 'How soon will support respond?',
        answer:
            'The concierge team responds within two business hours. Urgent clinical matters should always be routed to emergency services rather than the in-app support desk.',
      ),
      _FaqItem(
        question: 'Can I export my session history?',
        answer:
            'Yes. Visit Settings → Privacy → Export data. You can request a secure archive of chats, voice transcriptions, and AI summaries, delivered via encrypted email within 24 hours.',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Sticky Header
          Container(
            color: scheme.primary,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Support',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Banner with gradient border
                        _HeroBanner(isDark: isDark, scheme: scheme, theme: theme),
                        const SizedBox(height: 48),
                        // Quick Actions Grid
                        _QuickActionsGrid(actions: quickActions, isDark: isDark, scheme: scheme, theme: theme),
                        const SizedBox(height: 48),
                        // FAQ Section
                        _FaqSection(faqs: faqs, isDark: isDark, scheme: scheme, theme: theme),
                        const SizedBox(height: 48),
                        // Footer
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '© 2024 Therapy Platform Support Center. All rights reserved.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
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

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  final ColorScheme scheme;
  final ThemeData theme;

  const _HeroBanner({required this.isDark, required this.scheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22.5),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.headset_mic_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Concierge Support',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "We're here, every step of the way",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get instant guidance on onboarding, billing, therapist codes, or AI voice sessions. Our support specialists know the platform inside and out.',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportAction {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SupportAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_SupportAction> actions;
  final bool isDark;
  final ColorScheme scheme;
  final ThemeData theme;

  const _QuickActionsGrid({
    required this.actions,
    required this.isDark,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 24),
                Expanded(child: _ActionCard(action: actions[i], isDark: isDark, scheme: scheme, theme: theme)),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _ActionCard(action: actions[i], isDark: isDark, scheme: scheme, theme: theme),
            ],
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatefulWidget {
  final _SupportAction action;
  final bool isDark;
  final ColorScheme scheme;
  final ThemeData theme;

  const _ActionCard({
    required this.action,
    required this.isDark,
    required this.scheme,
    required this.theme,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final surfaceColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.action.icon,
                  color: widget.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.action.title,
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.action.description,
                style: widget.theme.textTheme.bodySmall?.copyWith(
                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqSection extends StatelessWidget {
  final List<_FaqItem> faqs;
  final bool isDark;
  final ColorScheme scheme;
  final ThemeData theme;

  const _FaqSection({
    required this.faqs,
    required this.isDark,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < faqs.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _FaqCard(item: faqs[i], initiallyExpanded: i == 0, isDark: isDark, scheme: scheme, theme: theme),
        ],
      ],
    );
  }
}

class _FaqCard extends StatefulWidget {
  final _FaqItem item;
  final bool initiallyExpanded;
  final bool isDark;
  final ColorScheme scheme;
  final ThemeData theme;

  const _FaqCard({
    required this.item,
    required this.initiallyExpanded,
    required this.isDark,
    required this.scheme,
    required this.theme,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(_controller);
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final surfaceColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Summary / Header
          InkWell(
            onTap: _toggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: widget.theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.expand_more,
                      color: widget.scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Align(
                heightFactor: _heightFactor.value,
                child: child,
              ),
              child: Column(
                children: [
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Text(
                      widget.item.answer,
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        height: 1.6,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
