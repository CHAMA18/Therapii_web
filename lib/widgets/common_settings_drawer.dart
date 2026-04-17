import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/admin_dashboard_page.dart';
import 'package:therapii/pages/admin_settings_page.dart';
import 'package:therapii/pages/billing_page.dart';
import 'package:therapii/pages/edit_profile_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_portal_page.dart';
import 'package:therapii/pages/landing_page.dart';
import 'package:therapii/pages/therapist_practice_page.dart';
import 'package:therapii/pages/therapist_practice_personalization_page.dart';
import 'package:therapii/pages/therapist_therapeutic_models_page.dart';
import 'package:therapii/pages/therapist_training_page.dart';
import 'package:therapii/theme.dart';
import 'package:therapii/theme_mode_controller.dart';
import 'package:therapii/utils/admin_access.dart';

/// Opens the full-page settings screen.
/// Kept named `showSettingsPopup` for backward compatibility.
Future<void> showSettingsPopup(BuildContext context, {bool hideBilling = false}) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CommonSettingsPage(hideBilling: hideBilling),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

class CommonSettingsPage extends StatefulWidget {
  final bool hideBilling;

  const CommonSettingsPage({super.key, this.hideBilling = false});

  @override
  State<CommonSettingsPage> createState() => _CommonSettingsPageState();
}

class _CommonSettingsPageState extends State<CommonSettingsPage> {
  bool _isLoadingSubscription = true;
  bool _isPaidUser = false;
  String _planName = 'Trial Period';
  bool _isSwitchingJournal = false;
  bool _isTherapist = false;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    if (!widget.hideBilling) {
      _fetchSubscriptionStatus();
    }
  }

  Future<void> _fetchUser() async {
    try {
      final uid = FirebaseAuthManager().currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (mounted) {
          setState(() {
            _isTherapist = doc.data()?['is_therapist'] == true;
            _isLoadingUser = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _fetchSubscriptionStatus() async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getStripeBillingDetails');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _isPaidUser = data['isPaidUser'] == true;
          _planName = data['planName'] as String? ?? 'Trial Period';
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching subscription status: $e');
      if (mounted) {
        setState(() => _isLoadingSubscription = false);
      }
    }
  }

  bool _isDarkMode(BuildContext context) {
    final mode = themeModeController.mode;
    if (mode == ThemeMode.system) {
      final platformBrightness = MediaQuery.platformBrightnessOf(context);
      return platformBrightness == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  bool _isAdmin() {
    final user = FirebaseAuthManager().currentUser;
    return AdminAccess.isAdminEmail(user?.email);
  }

  Future<void> _openJournalWorkspace() async {
    if (_isSwitchingJournal) return;

    setState(() => _isSwitchingJournal = true);
    final destination =
        _isAdmin() ? const JournalAdminStudioPage() : const JournalPortalPage();

    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  String _displayName() {
    final user = FirebaseAuthManager().currentUser;
    final email = user?.email ?? '';
    final local = email.contains('@') ? email.split('@').first : email;
    return local.isNotEmpty ? local : 'Guest';
  }

  String _email() {
    final user = FirebaseAuthManager().currentUser;
    return user?.email ?? '';
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '👤';
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin();
    final name = _displayName();
    final email = _email();
    final initials = _initials(name);

    return AnimatedBuilder(
      animation: themeModeController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isDark = _isDarkMode(context);
        return Scaffold(
          backgroundColor: scheme.surfaceContainerHighest,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 64),
                children: [
                  // Breathtaking User Profile Header
                  Hero(
                    tag: 'settings_profile_header',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryFor(theme.brightness),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.onPrimary.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: scheme.onPrimary.withValues(alpha: 0.3),
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    email,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: scheme.onPrimary.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Account Section
                  _SettingsSection(
                    title: 'Account',
                    children: [
                      _SettingsRow(
                        icon: Icons.manage_accounts_rounded,
                        iconColor: scheme.primary,
                        title: 'Edit Profile',
                        subtitle: 'Change email or password',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const EditProfilePage()),
                          );
                        },
                      ),
                      if (!widget.hideBilling)
                        _SettingsRow(
                          icon: _isPaidUser
                              ? Icons.workspace_premium_rounded
                              : Icons.star_border_rounded,
                          iconColor: _isPaidUser
                              ? scheme.primary
                              : const Color(0xFF38BDF8),
                          title: _isLoadingSubscription ? 'Loading...' : _planName,
                          subtitle: _isLoadingSubscription
                              ? 'Checking subscription'
                              : (_isPaidUser
                                  ? 'Premium member'
                                  : 'Tap to upgrade'),
                          isLoading: _isLoadingSubscription,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const BillingPage()),
                            );
                          },
                        ),
                    ],
                  ),

                  // Therapist Section
                  if (_isTherapist && !_isLoadingUser)
                    _SettingsSection(
                      title: 'Practice Settings',
                      children: [
                        _SettingsRow(
                          icon: Icons.psychology_outlined,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Practice Setup',
                          subtitle: 'Core approaches for your practice',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TherapistTherapeuticModelsPage()),
                            );
                          },
                        ),
                        _SettingsRow(
                          icon: Icons.badge_outlined,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Profile & Licensure',
                          subtitle: 'Contact & Licensure, Education, ID v...',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TherapistPracticePage()),
                            );
                          },
                        ),
                        _SettingsRow(
                          icon: Icons.face_retouching_natural_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Personalization',
                          subtitle: 'Choose your AI avatar and name',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TherapistPracticePersonalizationPage()),
                            );
                          },
                        ),
                        _SettingsRow(
                          icon: Icons.smart_toy_outlined,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Training Studio',
                          subtitle: 'Tone, phrases, engagement & concer...',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TherapistTrainingPage()),
                            );
                          },
                        ),
                      ],
                    ),

                  // Admin Section
                  if (isAdmin)
                    _SettingsSection(
                      title: 'Administration',
                      children: [
                        _SettingsRow(
                          icon: Icons.space_dashboard_outlined,
                          iconColor: scheme.secondary,
                          title: 'Admin Dashboard',
                          subtitle: 'Approve therapists & view platform health',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AdminDashboardPage()),
                            );
                          },
                        ),
                        _SettingsRow(
                          icon: Icons.admin_panel_settings,
                          iconColor: scheme.secondary,
                          title: 'System Settings',
                          subtitle: 'Configure OpenAI & SendGrid',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AdminSettingsPage()),
                            );
                          },
                        ),
                      ],
                    ),

                  // Workspaces Section
                  _SettingsSection(
                    title: 'Workspaces',
                    children: [
                      _SettingsRow(
                        icon: isAdmin
                            ? Icons.auto_stories_rounded
                            : Icons.menu_book_rounded,
                        iconColor: const Color(0xFF8B5CF6), // Purple accent
                        title: isAdmin
                            ? 'Switch to Journal Studio'
                            : 'Switch to Journal',
                        subtitle: isAdmin
                            ? 'Open the publishing studio & analytics'
                            : 'Open your journal workspace for reflections',
                        isLoading: _isSwitchingJournal,
                        onTap: _openJournalWorkspace,
                      ),
                    ],
                  ),

                  // Appearance Section
                  _SettingsSection(
                    title: 'Appearance',
                    children: [
                      _SettingsRow(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: isDark ? scheme.primary : Colors.amber.shade700,
                        title: 'Dark Mode',
                        subtitle: isDark ? 'Enabled' : 'Disabled',
                        trailing: CupertinoSwitch(
                          value: isDark,
                          activeColor: scheme.primary,
                          onChanged: (value) {
                            themeModeController.setMode(
                                value ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Legal Section
                  _SettingsSection(
                    title: 'Legal',
                    children: [
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: scheme.tertiary,
                        title: 'Privacy Policy',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const _StaticContentPage(
                                title: 'Privacy Policy',
                                paragraphs: _privacyPolicyParagraphs,
                              ),
                            ),
                          );
                        },
                      ),
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        iconColor: scheme.tertiary,
                        title: 'Terms of Service',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const _StaticContentPage(
                                title: 'Terms and Conditions',
                                paragraphs: _termsAndConditionsParagraphs,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Danger Zone
                  _SettingsSection(
                    title: 'Account Actions',
                    children: [
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        iconColor: scheme.error,
                        title: 'Sign Out',
                        titleColor: scheme.error,
                        onTap: () async {
                          await FirebaseAuthManager().signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const LandingPage()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: _buildSeparatedChildren(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeparatedChildren(ThemeData theme) {
    List<Widget> separated = [];
    for (int i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 64, // Aligns with text start
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        );
      }
    }
    return separated;
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: scheme.onSurface.withValues(alpha: 0.05),
        splashColor: scheme.onSurface.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.3),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legacy class kept for backward compatibility - now calls showSettingsPopup
@Deprecated('Use showSettingsPopup(context) instead')
class CommonSettingsDrawer extends StatelessWidget {
  const CommonSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(child: SizedBox.shrink());
  }
}

class _StaticContentPage extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  const _StaticContentPage({required this.title, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: paragraphs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return Text(
            paragraphs[index],
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          );
        },
      ),
    );
  }
}

const List<String> _privacyPolicyParagraphs = <String>[
  'At Therapii, privacy is our top priority. We recognize the sensitivity of sharing mental health information, and we take that responsibility seriously. Your data is stored securely encrypted on our servers, and we operate in accordance with HIPAA and maintain strict policies protecting your data privacy.',
  'Whether you are a therapists or a patient, your data may be captured and stored as text and or voice. We analyze that data exclusively to improve the Therapii services and user experience of our users.',
  'We anticipate that these terms will evolve over time to keep pace with technology, but ensuring data privacy will remain our top priority. We will notify users of any significant changes to the Privacy Policy, and the most recent copy of these terms will remain on this webpage.',
  'Our official privacy policy, effective as of June 11th, 2025, can be found below.',
  'Therapii Privacy Policy',
  'Therapii ("Company" or "We") provides our therapists and patients ("User" or "You") with access to AI tools or services via websites or applications ("Products"). This Privacy Policy explains the types of information we may collect from our users, how we use and disclose such information and our purposes for doing so. It also describes how we protect Personal Information and your choices with regard to your Personal Information. To the extent you use the Company Products or services, this Privacy Policy will apply to you, so please review it carefully. If you do not agree to any term of this Privacy Policy, please do not access or use the Company Products.',
  '1. Information We Collect',
  'As described in further detail below, we may collect both Personal Information (i.e., information that identifies you or other individuals) and Non-Personal Information (i.e., information that does not identify you or any other individual, directly or indirectly). This information may be collected from Users using the Products as a therapist ("Therapist") and Users using the Products as a client of a Therapist ("Client").',
  'We may collect the following types of Personal Information:',
  '''• Names. We may collect full names of Users when they provide it to us in the course of using the Platform. For example, we may collect a User’s full name when that User establishes an account with any of our Products or when the User provides it to us in connection with sending us an inquiry or other communication.''',
  '''• Contact Information. We may collect Users’ contact information, including without limitation, email addresses, postal addresses and phone numbers, when they establish an account with any of our Products or when they provide such information to us in connection with sending us an inquiry or other communication.''',
  '''• Internet Media. We may collect information about Therapists from websites or social media accounts that help to inform our Products about the Therapists skills, specialties, and approach toward providing therapeutic services to their Clients.''',
  '''• Online Identifiers. We may collect Users’ online identifiers, such as their Internet Protocol (IP) addresses, automatically as they use any of our Products.''',
  '''• Conversation Data. We may collect information included within a conversation in which the User engages using our online tools or services (“Conversation Data”). We may collect such Conversation Data (including all Personal Information contained therein) pursuant to the User’s consent. Conversation Data may be collected as text, image, or audio files.''',
  'We may collect the following types of Non-Personal Information:',
  '''• Platform Usage Data. We may collect data regarding the ways in which our Users use the Products, including pages and functionality that are used, time spent on pages or functions, actions a User takes, frequency, volume, time stamps and location of Product usage. We collect these types of Non-Personal Information automatically as our Users use our Products.''',
  '''• Device Type. We may collect information about the type(s) of device(s) that are used to access the Products. We collect this type of Non-Personal Information automatically as our Users use the Platform.''',
  '2. How We Use and Disclose Information',
  'We may use and disclose Personal Information as described below:',
  '''- We may use our Users’ names and contact information to operate and provide our Platform, including without limitation, to provide specific Platform services, to enable our Users to establish and maintain accounts on the Platform and to communicate with Users. We may also use our Users’ names and contact information to send direct marketing communications, as described further in the “Direct Marketing” section below.''',
  '''- We may disclose Users’ names and contact information to our service providers and affiliates that assist us or otherwise work with us to support our business functions, including the provision of our Platform and direct marketing functions.''',
  '''- We may use Users’ online identifiers to remember their preferences on the Platform and to otherwise operate and provide the Platform.''',
  '''- We may disclose online identifiers to our service providers and affiliates that assist us or otherwise work with us to support our business functions, including the operation and provision of our Platform.''',
  '''- We may use Conversation Data to improve the Platform (e.g., for model training to optimize the tools and/or features included within our Platform). We may disclose Conversation Data to our service providers and affiliates that assist us or otherwise work with us to improve our Platform.''',
  '''- We may use any of the Personal Information described in this Privacy Policy as needed to comply with applicable law, regulation, legal process, subpoena or governmental request. We may disclose such Personal Information to persons and entities authorized to receive the Personal Information for such purposes (e.g., law enforcement, courts or authorized government agencies).''',
  'We may use and disclose Non-Personal Information as described below:',
  '''- We may use Platform usage data, geolocation data and device type data as needed to identify, address and resolve technical issues regarding the operation of the Platform and to facilitate the operation of our Platform. We may disclose such data to our service providers and affiliates that assist us or otherwise work with us to support the operation of the Platform.''',
  '''- We may use Platform usage data, geolocation data and device type data to remember User preferences and customize the Platform for Users. We may disclose such data to our service providers and affiliates that assist us or otherwise work with us to support such functions.''',
  '''- We may use Platform usage data, geolocation data and device type data for analytics purposes, such as analyzing trends relating to our Users’ use of the Platform, and to improve the Platform. We may disclose such data to our service providers and affiliates that assist us or otherwise work with us to support such functions.''',
  '''- We may use Platform usage data, geolocation data and device type data as needed to comply with applicable law, regulation, legal process, subpoena or governmental request. We may disclose such data to persons and entities authorized to receive it for such purposes (e.g., law enforcement, courts or authorized government agencies).''',
  'Data Security',
  'We implement information security measures designed to maintain the security and integrity of the information (Personal Information and Non-Personal Information) that we collect and maintain. Examples of security measures that we use include, but are not limited to, the following:',
  '• data encryption;\n• use of multi-factor authentication by our employees;\n• password protection and management;\n• role-based access control for our employees who access Personal Information.',
  'Additionally, with regard to the Personal Information we maintain about our Users, to help protect our Users’ privacy we remove information directly identifying Users (such as names) and assign a code (i.e., a unique identification number) which is associated with that User’s information. We securely maintain the key which links the codes to identifiable Users and we allow only to our authorized personnel to access the key.',
  'We regularly assess the effectiveness of our data security measures and may modify such measures, as appropriate, to adequately protect information that we collect and maintain. Despite the security measures we implement, there are inherent risks in transmission of information over the Internet and therefore we cannot guarantee that unauthorized access to or use of information will never occur.',
  '4. Links to Third-Party Sites',
  'Our Platform may include links to third-party websites. We do not endorse or recommend such third-party websites or the content therein and are not responsible for the privacy practices of the operators of those websites. We encourage you to read the privacy policies which may apply to your use of third-party websites.',
  '5. Children Under 13',
  'Our Platform is not intended for use by children under the age of 13 and we do not knowingly collect Personal Information from children under the age of 13. If you become aware that we have collected Personal Information from a child under the age 13, please contact us at support@trytherapii.com so that we may seek to delete such Personal Information.',
  '6. Direct Marketing',
  '''If you opt to receive direct marketing communications from us, we may use your name and contact information to send such communications to you. Direct marketing communications may include, without limitation, updates about our products and services and other promotional material that may be of interest to you. When we send direct marketing communications to you via email, we will include an unsubscribe link in the email which allows you to opt out of receiving further direct marketing emails from us. You may also choose to receive direct marketing communications through push notifications within our application. You may, at any time, discontinue these notifications by changing the application settings to disable such notifications.''',
  '7. Our Service Providers',
  '''We work with third-party service providers and disclose Personal Information and Non-Personal Information to those providers so that they may assist us with certain activities, as described above in this Privacy Policy. We do not control such third-party service providers, but we carefully evaluate the information privacy and security practices of those providers prior to engaging them and select only those providers that we reasonably determine are able to adequately protect Personal Information and Non-Personal Information.''',
  '8. International Data Transfers',
  '''In connection with providing our Platform, we may transfer information (Personal Information and Non-Personal Information) internationally from the country in which you access the Platform to other countries around the globe, as permitted by applicable laws. We may transfer such information to a country that does not have the same privacy or data protection laws as the country in which such information was collected. Accordingly, such information may be subject to different legal protections depending on the laws and regulations of the country to which the information is transferred.''',
  '9. Tracking Tools',
  '''We use certain tools and programs to track Platform usage (“Tracking Tools”) in accordance with applicable laws. We use Tracking Tools to understand, among other things, how Users use our Platform, including how often Users use the Platform and how they interact with certain components of our Platform. The use of Tracking Tools involves collection of information about your Platform activity and the device you use to access the Platform. The information we obtain from the use of Tracking Tools enables us to improve the Platform and make it more user-friendly and convenient. You may disable Tracking Tools by modifying your browser settings, but if you do so, some features on our Platform may not function as intended.''',
  '10. Retention of Personal Information',
  '''We may retain information (Personal Information and Non-Personal Information) until the purposes of using and disclosing such information described in this Privacy Policy have been fulfilled, in each case as permitted under applicable laws and regulations. However, you may, at any time, request that we delete your Personal Information as specified in the section below titled “Your Choices Regarding Personal Information”.''',
  '11. Your Choices Regarding Personal Information',
  '''If you would like us to delete or modify Personal Information that we maintain about you, you may send a request to us at support@trytherapii.com. With regard to Conversation Data that we maintain about you, you also have the option of requesting deletion of this data by clicking the “delete my data” button within the user interface on our Platform and then confirming this selection. If you maintain an account with us and you would like us to delete your name and contact information, you must (a) delete your account; and (b) send an email to us at support@trytherapii.com requesting deletion of your name and contact information. We will make reasonable efforts to delete or modify your Personal Information in accordance with your request and in any case, as required by any applicable laws or regulations.''',
  '12. Privacy Policy Changes',
  '''We may change this Privacy Policy from time to time as we deem appropriate without prior notice to you. We will post any updated version of this Privacy Policy on our Platform. Please check the Platform frequently to ensure you have reviewed the most recent version of the Privacy Policy.''',
  'Questions',
  '''If you have any questions about this Privacy Policy, please feel free to contact us at support@trytherapii.com.''',
];

const List<String> _termsAndConditionsParagraphs = <String>[
  'Welcome to Therapii. By accessing and using our platform, you agree to the following terms and conditions.',
  'Use of Therapii must comply with applicable laws and professional guidelines. You are responsible for the information you provide and for maintaining the confidentiality of your account.',
  'Therapii provides tooling and AI assistance but is not a substitute for licensed professional care. You acknowledge that summaries and generated content may contain errors and should always be reviewed.',
  'We reserve the right to update these terms to reflect changes in our services or legal requirements. Continued use of the platform constitutes acceptance of any updates.',
];
