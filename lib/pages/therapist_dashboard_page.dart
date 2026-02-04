import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/services/user_service.dart';
import 'package:therapii/widgets/common_settings_drawer.dart';
import 'package:therapii/pages/my_patients_page.dart';
import 'package:therapii/pages/listen_page.dart';
import 'package:therapii/pages/therapist_details_page.dart';
import 'package:therapii/pages/therapist_practice_personalization_page.dart';
import 'package:therapii/pages/therapist_training_page.dart';
import 'package:therapii/pages/therapist_therapeutic_models_page.dart';
import 'package:therapii/pages/support_center_page.dart';
import 'package:therapii/pages/billing_page.dart';

class TherapistDashboardPage extends StatefulWidget {
  const TherapistDashboardPage({super.key});

  @override
  State<TherapistDashboardPage> createState() => _TherapistDashboardPageState();
}

class _TherapistDashboardPageState extends State<TherapistDashboardPage> {
  final _userService = UserService();
  app_user.User? _therapist;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      setState(() {
        _loading = false;
        _error = 'You must be signed in.';
      });
      return;
    }

    try {
      final u = await _userService.getUser(authUser.uid);
      if (!mounted) return;
      setState(() {
        _therapist = u;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your profile. $e';
        _loading = false;
      });
    }
  }

  String _displayName() {
    final u = _therapist;
    if (u == null) return 'Therapist';
    if (u.firstName.trim().isNotEmpty) return u.firstName.trim();
    if (u.fullName.trim().isNotEmpty) return u.fullName.trim();
    return u.email.split('@').first;
  }

  String _fullDisplayName() {
    final u = _therapist;
    if (u == null) return 'Therapist';
    if (u.fullName.trim().isNotEmpty) return u.fullName.trim();
    if (u.firstName.trim().isNotEmpty) return u.firstName.trim();
    return u.email.split('@').first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    } else {
      final name = _displayName();
      final fullName = _fullDisplayName();

      body = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting section
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()},',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fullName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'What would you like to do today?',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'T',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount;
                    if (width >= 1000) {
                      crossAxisCount = 4;
                    } else if (width >= 700) {
                      crossAxisCount = 3;
                    } else if (width >= 500) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 1;
                    }

                    final cards = _buildCards(context);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.1,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) => cards[index],
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          tooltip: 'Settings',
          onPressed: () => showSettingsPopup(context),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: body,
    );
  }

  List<Widget> _buildCards(BuildContext context) => [
        _DashboardCard(
          title: 'My Patients',
          subtitle: 'Manage conversations, invite new patients',
          icon: Icons.groups_rounded,
          isPrimary: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyPatientsPage()),
          ),
        ),
        _DashboardCard(
          title: 'Listen',
          subtitle: 'AI summaries, transcripts and voice updates',
          icon: Icons.graphic_eq_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ListenPage()),
          ),
        ),
        _DashboardCard(
          title: 'Practice Setup',
          subtitle: 'Contact & Licensure, Education, ID verification',
          icon: Icons.badge_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TherapistDetailsPage()),
          ),
        ),
        _DashboardCard(
          title: 'Personalization',
          subtitle: 'Tone, phrases, engagement & concerns',
          icon: Icons.tune_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TherapistPracticePersonalizationPage()),
          ),
        ),
        _DashboardCard(
          title: 'Training Studio',
          subtitle: 'Upload profile image and start AI training',
          icon: Icons.smart_toy_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TherapistTrainingPage()),
          ),
        ),
        _DashboardCard(
          title: 'Therapeutic Models',
          subtitle: 'Core approaches for your practice',
          icon: Icons.psychology_alt_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TherapistTherapeuticModelsPage()),
          ),
        ),
        _DashboardCard(
          title: 'Billing',
          subtitle: 'Manage subscription and invoices',
          icon: Icons.credit_card_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BillingPage()),
          ),
        ),
        _DashboardCard(
          title: 'Support Center',
          subtitle: 'FAQs and help resources',
          icon: Icons.help_outline_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupportCenterPage()),
          ),
        ),
      ];
}

/// Web-friendly dashboard card with clean, minimal design.
class _DashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = widget.isPrimary
        ? colorScheme.primary
        : colorScheme.surface;
    final borderColor = widget.isPrimary
        ? Colors.transparent
        : colorScheme.outline.withValues(alpha: 0.15);
    final iconColor = widget.isPrimary
        ? colorScheme.onPrimary
        : colorScheme.primary;
    final titleColor = widget.isPrimary
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final subtitleColor = widget.isPrimary
        ? colorScheme.onPrimary.withValues(alpha: 0.8)
        : colorScheme.onSurface.withValues(alpha: 0.55);
    final iconBgColor = widget.isPrimary
        ? colorScheme.onPrimary.withValues(alpha: 0.2)
        : colorScheme.primary.withValues(alpha: 0.1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? colorScheme.primary.withValues(alpha: 0.9) : backgroundColor)
                : (_isHovered ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : backgroundColor),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isPrimary ? 0.08 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  if (widget.isPrimary)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isHovered ? 1.0 : 0.6,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 200),
                        offset: _isHovered ? const Offset(0.1, 0) : Offset.zero,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
