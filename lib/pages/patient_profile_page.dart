import 'package:flutter/material.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/pages/patient_profile_details_page.dart';

class PatientProfilePage extends StatefulWidget {
  final app_user.User patient;
  final String therapistId;
  const PatientProfilePage(
      {super.key, required this.patient, required this.therapistId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = widget.patient;
    final displayName =
        patient.fullName.trim().isNotEmpty ? patient.fullName : patient.email;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Elegant Background Effect
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.secondary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: scheme.onSurface),
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Client Profile',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Avatar Section
                        Hero(
                          tag: 'avatar_${patient.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: scheme.primaryContainer,
                              backgroundImage: (patient.avatarUrl ?? '').isNotEmpty
                                  ? NetworkImage(patient.avatarUrl!)
                                  : null,
                              child: (patient.avatarUrl ?? '').isNotEmpty
                                  ? null
                                  : Text(
                                      displayName.substring(0, 1).toUpperCase(),
                                      style: theme.textTheme.displayMedium?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Name
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.normal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Contact info wrapped
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ContactBadge(
                              icon: Icons.alternate_email_rounded,
                              text: patient.email,
                            ),
                            if ((patient.phoneNumber ?? '').isNotEmpty)
                              _ContactBadge(
                                icon: Icons.phone_rounded,
                                text: patient.phoneNumber!,
                              ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        // Action Cards Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Management & Context',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionCard(
                          title: 'Conversation Context',
                          subtitle: 'Review the complete history of interactions and AI summary insights.',
                          icon: Icons.forum_rounded,
                          color: scheme.primary,
                          onTap: () => _openDetails(SectionTarget.recent),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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

class _ContactBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: scheme.onSurfaceVariant,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SectionTarget { recent, summaries }

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
