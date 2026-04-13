import 'package:flutter/material.dart';
import 'package:therapii/pages/auth_welcome_page.dart';

class WhatIsTherapiiPage extends StatefulWidget {
  const WhatIsTherapiiPage({super.key});

  @override
  State<WhatIsTherapiiPage> createState() => _WhatIsTherapiiPageState();
}

class _WhatIsTherapiiPageState extends State<WhatIsTherapiiPage> {
  void _goToAuth(BuildContext context, {bool login = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthWelcomePage(initialTab: login ? AuthTab.login : AuthTab.create),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 4,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _goToAuth(context, login: true),
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text('Sign In'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.6),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/therapii_logo.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'What is Therapii?',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IntroSection(),
                      const SizedBox(height: 48),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 700) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _TherapistBenefits()),
                                const SizedBox(width: 32),
                                Expanded(child: _PatientBenefits()),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _TherapistBenefits(),
                              const SizedBox(height: 32),
                              _PatientBenefits(),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 64),
                      _BottomCTA(onPressed: () => _goToAuth(context, login: false)),
                    ],
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

class _IntroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'The Future of Connected Therapy',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            'Therapii is an AI based tool that allows a patient to continue their therapeutic program outside of their session times via a chatbot that has been trained by the patient\'s therapist to understand the patient\'s needs and therapeutic objectives.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapistBenefits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BenefitColumn(
      title: 'For Therapists',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF0EA5E9), // Light blue
      benefits: const [
        'Personalize an AI agent that is already trained on broad therapeutic modalities to reflect your individual style, language and approach to therapy. Initial training takes less than an hour, and then the agent continually learns.',
        'Extend your time with patients beyond the typical 1 hour per week, guiding your agent on things to listen for, questions to ask or topics to explore.',
        'All engagements with the patient are recorded and summarized for you daily.',
        'Earn extra income from use of the app while setting custom pricing that is appropriate to you and your patients.',
      ],
    );
  }
}

class _PatientBenefits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BenefitColumn(
      title: 'For Patients',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFF43F5E), // Rose red
      benefits: const [
        'Ask questions and get responses that mirror your therapist\'s style and objectives 24/7. Whether you are between classes, taking a break, or getting ready for bed, your companion is always available.',
        'Experience hyper-personalized care. Unlike general AI, Therapii reflects your therapist\'s plan for you and continually learns from your interactions.',
        'Get notes and summaries of your interactions with both your IRL therapist and your AI companion.',
        'Never wonder "what was that thing they said?" because your AI therapist is there taking notes for you.',
      ],
    );
  }
}

class _BenefitColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> benefits;

  const _BenefitColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, size: 14, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        b,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _BottomCTA extends StatelessWidget {
  final VoidCallback onPressed;

  const _BottomCTA({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ready to experience the future of therapy?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                'Get Started Now',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
