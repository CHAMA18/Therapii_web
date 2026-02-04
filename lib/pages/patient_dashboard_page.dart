import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/models/invitation_code.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/pages/ai_therapist_chat_page.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/pages/billing_page.dart';
import 'package:therapii/pages/patient_chat_page.dart';
import 'package:therapii/pages/patient_voice_conversation_page.dart';
import 'package:therapii/pages/support_center_page.dart';
import 'package:therapii/services/chat_service.dart';
import 'package:therapii/services/invitation_service.dart';
import 'package:therapii/services/user_service.dart';
import 'package:therapii/widgets/common_settings_drawer.dart';

class PatientDashboardPage extends StatefulWidget {
  final String? therapistId;

  const PatientDashboardPage({super.key, this.therapistId});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

/// Holds therapist info including their user data and AI model name.
class TherapistProfile {
  final app_user.User user;
  final String? aiName;
  TherapistProfile({required this.user, this.aiName});
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final FirebaseAuthManager _authManager = FirebaseAuthManager();
  final UserService _userService = UserService();
  final InvitationService _invitationService = InvitationService();
  final ChatService _chatService = ChatService();

  app_user.User? _patient;
  List<TherapistProfile> _therapistProfiles = [];
  int _selectedTherapistIndex = 0;
  bool _loading = true;
  bool _processingCode = false;
  String? _error;
  bool _showDailyThought = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      setState(() {
        _error = 'You need to be signed in to continue.';
        _loading = false;
      });
      return;
    }

    try {
      final patient = await _userService.getUser(firebaseUser.uid);
      if (!mounted) return;

      if (patient == null) {
        setState(() {
          _error = 'We were unable to load your profile.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _patient = patient;
      });

      await _loadAllTherapists(patient.id);
      if (!mounted) return;

      // If a specific therapistId was provided, select that therapist
      if (widget.therapistId?.trim().isNotEmpty ?? false) {
        final idx = _therapistProfiles.indexWhere((p) => p.user.id == widget.therapistId!.trim());
        if (idx >= 0) {
          setState(() => _selectedTherapistIndex = idx);
        }
      }

      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong while loading your dashboard. Please try again.';
        _loading = false;
      });
    }
  }

  /// Loads all therapists connected to this patient via accepted invitations.
  Future<void> _loadAllTherapists(String patientId) async {
    if (!mounted) return;

    debugPrint('[PatientDashboard] Loading all therapists for patient: $patientId');

    try {
      final invitations = await _invitationService.getAcceptedInvitationsForPatient(patientId);
      debugPrint('[PatientDashboard] Found ${invitations.length} accepted invitations');

      final profiles = <TherapistProfile>[];
      for (final inv in invitations) {
        final therapistId = inv.therapistId;
        if (therapistId.isEmpty) continue;

        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(therapistId).get();
          if (!userDoc.exists) continue;
          final therapistUser = app_user.User.fromJson(userDoc.data()!);

          // Load AI name from therapist's training profile
          String? aiName;
          try {
            final therapistDoc = await FirebaseFirestore.instance.collection('therapists').doc(therapistId).get();
            if (therapistDoc.exists) {
              final aiProfile = therapistDoc.data()?['ai_training_profile'];
              if (aiProfile is Map<String, dynamic>) {
                final name = aiProfile['name'];
                if (name is String && name.isNotEmpty) {
                  aiName = name;
                }
              }
            }
          } catch (e) {
            debugPrint('[PatientDashboard] Failed to load AI name for $therapistId: $e');
          }

          profiles.add(TherapistProfile(user: therapistUser, aiName: aiName));
        } catch (e) {
          debugPrint('[PatientDashboard] Error loading therapist $therapistId: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _therapistProfiles = profiles;
        _selectedTherapistIndex = 0;
      });
      debugPrint('[PatientDashboard] Loaded ${profiles.length} therapist profiles');
    } catch (e) {
      debugPrint('[PatientDashboard] Error loading therapists: $e');
      if (!mounted) return;
      setState(() {
        _therapistProfiles = [];
        _selectedTherapistIndex = 0;
      });
    }
  }

  TherapistProfile? get _currentTherapistProfile {
    if (_therapistProfiles.isEmpty) return null;
    if (_selectedTherapistIndex < 0 || _selectedTherapistIndex >= _therapistProfiles.length) return null;
    return _therapistProfiles[_selectedTherapistIndex];
  }

  app_user.User? get _therapistUser => _currentTherapistProfile?.user;
  String? get _therapistAiName => _currentTherapistProfile?.aiName;

  void _showDeleteDailyThoughtDialog(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hide Daily Thought?',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This will hide the Daily Thought card from your dashboard.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _showDailyThought = false);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hide'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _promptForInvitationCode() async {
    if (_processingCode) return;
    final patient = _patient;
    if (patient == null) return;

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Enter Invitation Code',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 5,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                counterText: '',
                hintText: '5-digit code',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Enter the code shared by your therapist';
                }
                if (!RegExp(r'^\d{5}$').hasMatch(text)) {
                  return 'Code must be 5 digits';
                }
                return null;
              },
              onChanged: (value) {
                final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digitsOnly != value) {
                  controller.value = TextEditingValue(
                    text: digitsOnly,
                    selection: TextSelection.collapsed(offset: digitsOnly.length),
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      controller.dispose();
      return;
    }

    setState(() => _processingCode = true);

    try {
      final InvitationCode? invitation = await _invitationService.validateAndUseCode(
        code: result,
        patientId: patient.id,
      );

      if (invitation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or expired code. Please double-check with your therapist.')),
          );
        }
        return;
      }

      await _userService.linkPatientToTherapist(
        userId: patient.id,
        therapistId: invitation.therapistId,
      );

      await _chatService.ensureConversation(
        therapistId: invitation.therapistId,
        patientId: patient.id,
      );

      // Reload all therapists to include the new one
      await _loadAllTherapists(patient.id);
      if (!mounted) return;

      // Select the newly added therapist
      final newIdx = _therapistProfiles.indexWhere((p) => p.user.id == invitation.therapistId);
      if (newIdx >= 0) {
        setState(() => _selectedTherapistIndex = newIdx);
      }

      final therapistUser = _therapistUser;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are now connected to ${therapistUser?.fullName ?? 'your therapist'}!'),
        ),
      );

      if (therapistUser != null) {
        _openChat(therapistUser);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify your code: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingCode = false);
      }
    }

    controller.dispose();
  }

  void _openChat(app_user.User otherUser) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientChatPage(otherUser: otherUser)),
    );
  }

  void _openAiTherapist() {
    final therapist = _currentTherapistProfile;
    if (therapist == null) {
      _showTherapistRequiredSnack();
      return;
    }
    final aiName = therapist.aiName ?? 'AI Companion';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiTherapistChatPage(
          therapistId: therapist.user.id,
          aiName: aiName,
        ),
      ),
    );
  }

  void _openVoiceRecording(app_user.User therapist) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientVoiceConversationPage(therapist: therapist)),
    );
  }

  Future<void> _handleMessageTap(app_user.User therapist) async {
    final patient = _patient;
    if (patient == null) return;

    try {
      await _chatService.ensureConversation(
        therapistId: therapist.id,
        patientId: patient.id,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open therapist messages: $error')),
      );
      return;
    }

    if (!mounted) return;
    _openChat(therapist);
  }

  void _showTherapistRequiredSnack() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Add your therapist to access this feature.'),
        action: SnackBarAction(
          label: 'Enter code',
          onPressed: () {
            messenger.hideCurrentSnackBar();
            _promptForInvitationCode();
          },
        ),
      ),
    );
  }

  String _resolvePatientDisplayName() {
    final patient = _patient;
    if (patient == null) {
      return 'there';
    }
    if (patient.firstName.trim().isNotEmpty) {
      return patient.firstName.trim();
    }
    final emailPrefix = patient.email.split('@').first;
    return emailPrefix.trim().isEmpty ? 'there' : emailPrefix;
  }

  String _resolveAiHandle() {
    // Return custom AI name if available, otherwise show a prompt to connect
    if (_therapistAiName == null || _therapistAiName!.isEmpty) {
      return 'AI Companion';
    }
    return _therapistAiName!;
  }

  Widget _buildErrorState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.error, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initialize,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    final displayName = _resolvePatientDisplayName();
    final aiHandle = _resolveAiHandle();
    final theme = Theme.of(context);
    final hasMultipleTherapists = _therapistProfiles.length > 1;

    // Greeting logic
    final hour = DateTime.now().hour;
    String greeting = 'Hello';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PatientTopBar(
                      displayName: displayName,
                      avatarUrl: _patient?.avatarUrl,
                      onSettings: () => showSettingsPopup(context),
                    ),
                    const SizedBox(height: 24),
                    _PatientGreeting(
                      greeting: greeting,
                      displayName: displayName,
                    ),
                    const SizedBox(height: 28),
                    // Top grid: AI chat + message therapist
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: _ChatWithAiCard(
                              aiHandle: aiHandle,
                              therapistName: _therapistUser?.firstName,
                              hasMultipleTherapists: hasMultipleTherapists,
                              therapistProfiles: _therapistProfiles,
                              selectedIndex: _selectedTherapistIndex,
                              onTherapistChanged: (index) => setState(() => _selectedTherapistIndex = index),
                              onTap: _openAiTherapist,
                              isDisabled: _therapistUser == null,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _PatientSecondaryCard(
                              title: 'Message Therapist',
                              subtitle: _therapistUser != null
                                  ? 'Connected with ${_therapistUser!.firstName}'
                                  : 'Connect with your therapist',
                              icon: Icons.chat_bubble_outline_rounded,
                              onTap: _therapistUser == null
                                  ? _showTherapistRequiredSnack
                                  : () => _handleMessageTap(_therapistUser!),
                              isDisabled: _therapistUser == null,
                              actionLabel: _therapistUser == null ? 'Connect' : null,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _ChatWithAiCard(
                        aiHandle: aiHandle,
                        therapistName: _therapistUser?.firstName,
                        hasMultipleTherapists: hasMultipleTherapists,
                        therapistProfiles: _therapistProfiles,
                        selectedIndex: _selectedTherapistIndex,
                        onTherapistChanged: (index) => setState(() => _selectedTherapistIndex = index),
                        onTap: _openAiTherapist,
                        isDisabled: _therapistUser == null,
                      ),
                      const SizedBox(height: 16),
                      _PatientSecondaryCard(
                        title: 'Message Therapist',
                        subtitle: _therapistUser != null
                            ? 'Connected with ${_therapistUser!.firstName}'
                            : 'Connect with your therapist',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: _therapistUser == null
                            ? _showTherapistRequiredSnack
                            : () => _handleMessageTap(_therapistUser!),
                        isDisabled: _therapistUser == null,
                        actionLabel: _therapistUser == null ? 'Connect' : null,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _PatientVoiceCard(
                      title: 'Voice Session',
                      subtitle: 'Record and share your thoughts in a safe space',
                      onTap: _therapistUser == null
                          ? _showTherapistRequiredSnack
                          : () => _openVoiceRecording(_therapistUser!),
                      isDisabled: _therapistUser == null,
                      actionLabel: _therapistUser == null ? 'Connect' : null,
                    ),
                    const SizedBox(height: 18),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: _PatientMiniCard(
                              title: 'Billing',
                              subtitle: 'Manage subscription',
                              icon: Icons.credit_card_rounded,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BillingPage())),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PatientMiniCard(
                              title: 'Support Center',
                              subtitle: 'FAQs and resources',
                              icon: Icons.help_outline_rounded,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportCenterPage())),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _PatientMiniCard(
                        title: 'Billing',
                        subtitle: 'Manage subscription',
                        icon: Icons.credit_card_rounded,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BillingPage())),
                      ),
                      const SizedBox(height: 12),
                      _PatientMiniCard(
                        title: 'Support Center',
                        subtitle: 'FAQs and resources',
                        icon: Icons.help_outline_rounded,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportCenterPage())),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_showDailyThought)
                      GestureDetector(
                        onLongPress: () => _showDeleteDailyThoughtDialog(context),
                        child: _PatientThoughtCard(
                          label: 'Daily Thought',
                          quote: '"The only way out is through."',
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildContent(context),
    );
  }
}

class _PatientTopBar extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final VoidCallback onSettings;

  const _PatientTopBar({
    required this.displayName,
    required this.avatarUrl,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? colorScheme.outline.withValues(alpha: 0.25) : const Color(0xFFF3F4F6),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;

          final avatar = avatarUrl != null
              ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl!),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.primary.withValues(alpha: 0.15) : const Color(0xFFDCEBFF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? colorScheme.primary.withValues(alpha: 0.2) : const Color(0xFFEFF6FF),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );

          final titleRow = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.primary.withValues(alpha: 0.12) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.spa_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'THERAPY PLATFORM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          );

          final actionsRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onSettings,
                icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              avatar,
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleRow,
                const SizedBox(height: 8),
                actionsRow,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleRow),
              const SizedBox(width: 12),
              actionsRow,
            ],
          );
        },
      ),
    );
  }
}

class _PatientGreeting extends StatelessWidget {
  final String greeting;
  final String displayName;

  const _PatientGreeting({
    required this.greeting,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          displayName,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How are you feeling today?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _PatientSecondaryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;
  final String? actionLabel;

  const _PatientSecondaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
    this.actionLabel,
  });

  @override
  State<_PatientSecondaryCard> createState() => _PatientSecondaryCardState();
}

class _PatientSecondaryCardState extends State<_PatientSecondaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    final accentBg = isDark ? colorScheme.primary.withValues(alpha: 0.14) : const Color(0xFFEBF2FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: colorScheme.primary, size: 24),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _hovered
                        ? colorScheme.onSurface.withValues(alpha: 0.6)
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.isDisabled && widget.actionLabel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientVoiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDisabled;
  final String? actionLabel;

  const _PatientVoiceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDisabled = false,
    this.actionLabel,
  });

  @override
  State<_PatientVoiceCard> createState() => _PatientVoiceCardState();
}

class _PatientVoiceCardState extends State<_PatientVoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    final iconBg = isDark ? colorScheme.primary.withValues(alpha: 0.18) : const Color(0xFFEFF6FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic_rounded, color: colorScheme.primary, size: 34),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isDisabled)
                Icon(Icons.play_circle_outline_rounded, color: colorScheme.primary.withValues(alpha: 0.5), size: 32),
              if (widget.isDisabled && widget.actionLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientMiniCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PatientMiniCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PatientMiniCard> createState() => _PatientMiniCardState();
}

class _PatientMiniCardState extends State<_PatientMiniCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    final accentBg = isDark ? colorScheme.primary.withValues(alpha: 0.14) : const Color(0xFFEBF2FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
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
}

class _PatientThoughtCard extends StatelessWidget {
  final String label;
  final String quote;

  const _PatientThoughtCard({
    required this.label,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.format_quote_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quote,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
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

/// Custom chat card with therapist switcher when multiple therapists exist.
class _ChatWithAiCard extends StatelessWidget {
  final String aiHandle;
  final String? therapistName;
  final bool hasMultipleTherapists;
  final List<TherapistProfile> therapistProfiles;
  final int selectedIndex;
  final ValueChanged<int> onTherapistChanged;
  final VoidCallback onTap;
  final bool isDisabled;

  const _ChatWithAiCard({
    required this.aiHandle,
    this.therapistName,
    required this.hasMultipleTherapists,
    required this.therapistProfiles,
    required this.selectedIndex,
    required this.onTherapistChanged,
    required this.onTap,
    this.isDisabled = false,
  });

  void _showTherapistSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Switch AI companion',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select which therapist\'s AI model you want to chat with:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(therapistProfiles.length, (i) {
              final profile = therapistProfiles[i];
              final isSelected = i == selectedIndex;
              final displayAiName = profile.aiName ?? 'KAI';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayAiName.isNotEmpty ? displayAiName[0].toUpperCase() : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  displayAiName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                subtitle: Text(
                  'Created by ${profile.user.firstName} ${profile.user.lastName}'.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  onTherapistChanged(i);
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = isDisabled
        ? 'Connect with a therapist to unlock'
        : (therapistName != null && therapistName!.isNotEmpty)
            ? 'Trained by $therapistName'
            : 'Your 24/7 AI companion';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: isDisabled ? colorScheme.surfaceContainerHighest : colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: isDisabled ? null : Colors.white.withValues(alpha: 0.12),
          highlightColor: isDisabled ? null : Colors.white.withValues(alpha: 0.06),
          child: Padding(
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
                        color: isDisabled
                            ? colorScheme.onSurface.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: isDisabled
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isDisabled
                          ? colorScheme.onSurface.withValues(alpha: 0.2)
                          : colorScheme.onPrimary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Chat with $aiHandle',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDisabled
                        ? colorScheme.onSurface.withValues(alpha: 0.5)
                        : colorScheme.onPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDisabled
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : colorScheme.onPrimary.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isDisabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Connect',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else if (hasMultipleTherapists) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showTherapistSwitcher(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Switch therapist',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
