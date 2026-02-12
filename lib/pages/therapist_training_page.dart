import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:therapii/foo.dart';
import 'package:therapii/services/openai_trainer.dart';
import 'package:therapii/pages/my_patients_page.dart';
import 'package:therapii/widgets/primary_button.dart';

class TherapistTrainingPage extends StatefulWidget {
  const TherapistTrainingPage({super.key});

  @override
  State<TherapistTrainingPage> createState() => _TherapistTrainingPageState();
}

// Predefined avatar options for AI personas
const List<_AvatarOption> _avatarOptions = [
  _AvatarOption(icon: Icons.psychology, color: Color(0xFF2563EB), label: 'Mindful'),
  _AvatarOption(icon: Icons.favorite, color: Color(0xFFF472B6), label: 'Caring'),
  _AvatarOption(icon: Icons.spa, color: Color(0xFF14B8A6), label: 'Calm'),
  _AvatarOption(icon: Icons.lightbulb, color: Color(0xFFF59E0B), label: 'Insightful'),
  _AvatarOption(icon: Icons.healing, color: Color(0xFF3B82F6), label: 'Healing'),
  _AvatarOption(icon: Icons.self_improvement, color: Color(0xFF8B5CF6), label: 'Balanced'),
  _AvatarOption(icon: Icons.wb_sunny, color: Color(0xFFF97316), label: 'Warm'),
  _AvatarOption(icon: Icons.nature_people, color: Color(0xFF22C55E), label: 'Grounded'),
];

class _AvatarOption {
  final IconData icon;
  final Color color;
  final String label;
  const _AvatarOption({required this.icon, required this.color, required this.label});
}

class _TherapistTrainingPageState extends State<TherapistTrainingPage> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedAvatarIndex = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('therapists').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final profile = data['ai_training_profile'];
      if (profile is Map<String, dynamic>) {
        final name = profile['name'];
        if (name is String && name.isNotEmpty) {
          _nameController.text = name;
        }

        final avatarIndex = profile['avatar_index'];
        if (avatarIndex is int && avatarIndex >= 0 && avatarIndex < _avatarOptions.length) {
          _selectedAvatarIndex = avatarIndex;
        }
      }
    } catch (_) {
      // Non-fatal: keep screen responsive even if load fails.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectAvatar(int index) {
    setState(() => _selectedAvatarIndex = index);
  }

  void _navigateAvatar(int direction) {
    final newIndex = (_selectedAvatarIndex + direction) % _avatarOptions.length;
    setState(() => _selectedAvatarIndex = newIndex < 0 ? _avatarOptions.length - 1 : newIndex);
  }

  Future<void> _handleStartTraining() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to continue.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your AI a name before starting training.')),
      );
      return;
    }

    setState(() => _saving = true);

    final docRef = FirebaseFirestore.instance.collection('therapists').doc(user.uid);

    try {
      final snapshot = await docRef.get();
      final existingData = snapshot.data() ?? <String, dynamic>{};

      final selectedAvatar = _avatarOptions[_selectedAvatarIndex];
      final aiProfilePayload = <String, dynamic>{
        'name': name,
        'avatar_index': _selectedAvatarIndex,
        'avatar_icon': selectedAvatar.icon.codePoint,
        'avatar_color': selectedAvatar.color.value,
        'avatar_label': selectedAvatar.label,
      };

      await docRef.set(
        {
          'ai_training_profile': aiProfilePayload,
          'ai_training_profile_updated_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final combinedData = Map<String, dynamic>.from(existingData)
        ..['ai_training_profile'] = {
          'name': name,
          'avatar_label': selectedAvatar.label,
        };

      final prompt = _buildTrainingPrompt(
        aiName: name,
        therapistData: combinedData,
      );

      final trainer = const OpenAITrainer();
      final trainingResult = await trainer.trainTherapistProfile(prompt: prompt);

      await docRef.set(
        {
          'ai_training_result': {
            'response_id': trainingResult.responseId,
            'model': trainingResult.model,
            'summary': trainingResult.outputText,
            if (trainingResult.usage != null) 'usage': trainingResult.usage,
            'completed_at': FieldValue.serverTimestamp(),
          },
          'ai_training_last_completed_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyPatientsPage()),
        (route) => false,
      );
    } on OpenAIConfigurationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on OpenAIRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Training failed: ${e.message}')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start training. ${e.message ?? e.code}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _buildTrainingPrompt({
    required String aiName,
    required Map<String, dynamic> therapistData,
  }) {
    final buffer = StringBuffer();

    final aiProfile = therapistData['ai_training_profile'];
    final avatarStyle = aiProfile is Map<String, dynamic> ? _normalizeString(aiProfile['avatar_label']) : null;

    final therapistName = _normalizeString(therapistData['full_name']);
    final practiceName = _normalizeString(therapistData['practice_name']);
    final city = _normalizeString(therapistData['city']);
    final state = _normalizeString(therapistData['state']);
    final zip = _normalizeString(therapistData['zip_code']);
    final email = _normalizeString(therapistData['contact_email']);
    final phone = _normalizeString(therapistData['contact_phone']);
    final profileUrl = _normalizeString(therapistData['psychology_today_url']);
    final hasPsychologyProfile = therapistData['has_psychology_today_profile'];

    final locationParts = [
      if (city != null) city,
      if (state != null) state,
      if (zip != null) zip,
    ];

    final overviewLines = <String>[
      'AI persona name: $aiName',
      if (therapistName != null) 'Therapist: $therapistName',
      if (practiceName != null) 'Practice: $practiceName',
      if (locationParts.isNotEmpty) 'Location: ${locationParts.join(', ')}',
      if (email != null) 'Contact email: $email',
      if (phone != null) 'Contact phone: $phone',
      if (avatarStyle != null) 'Avatar personality style: $avatarStyle',
    ];

    if (hasPsychologyProfile is bool) {
      if (hasPsychologyProfile) {
        overviewLines.add(
          profileUrl != null
              ? 'Psychology Today profile: $profileUrl'
              : 'Psychology Today profile on file (URL not provided).',
        );
      } else {
        overviewLines.add('No Psychology Today profile available.');
      }
    } else if (profileUrl != null) {
      overviewLines.add('Psychology Today profile: $profileUrl');
    }

    _appendBulletSection(buffer, 'Therapist Persona Overview', overviewLines);

    final licensure = _normalizeStringList(therapistData['state_licensures']);
    final education = _normalizeStringList(therapistData['educations']);
    final credentialsLines = <String>[
      if (licensure.isNotEmpty) 'Licensed in: ${licensure.join(', ')}',
      if (education.isNotEmpty) 'Education: ${education.join('; ')}',
    ];
    _appendBulletSection(buffer, 'Credentials', credentialsLines);

    final methodologies = _normalizeStringList(therapistData['methodologies']);
    final specialties = _normalizeStringList(therapistData['specialties']);
    final models = _normalizeStringList(therapistData['therapeutic_models']);
    final specialization = _normalizeString(therapistData['specialization']);
    final clinicalLines = <String>[
      if (specialization != null) 'Primary specialization: $specialization',
      if (methodologies.isNotEmpty) 'Methodologies: ${methodologies.join(', ')}',
      if (specialties.isNotEmpty) 'Specialties: ${specialties.join(', ')}',
      if (models.isNotEmpty) 'Therapeutic models: ${models.join(', ')}',
    ];
    _appendBulletSection(buffer, 'Clinical Focus', clinicalLines);

    final addressStyle = _normalizeString(therapistData['client_addressing_style']);
    final phrases = _normalizeStringList(therapistData['preferred_phrases_options']);
    final customPhrase = _normalizeString(therapistData['preferred_phrases_custom']);
    final defaultEngagement = _normalizeString(therapistData['default_ai_engagement']);
    final communicationLines = <String>[
      if (addressStyle != null) 'Addresses clients as: $addressStyle',
      if (phrases.isNotEmpty) 'Frequent prompts: ${phrases.join('; ')}',
      if (customPhrase != null) 'Personal catchphrase: $customPhrase',
      if (defaultEngagement != null) 'Default engagement style: $defaultEngagement',
    ];
    _appendBulletSection(buffer, 'Communication Preferences', communicationLines);

    final concerns = _normalizeStringList(therapistData['patient_ai_concerns']);
    final otherConcern = _normalizeString(therapistData['patient_ai_concern_other']);
    final safetyLines = <String>[
      ...concerns,
      if (otherConcern != null) 'Other concern: $otherConcern',
    ];
    _appendBulletSection(buffer, 'Safety & Risk Priorities', safetyLines);

    final inspirationLines = _buildInspirationLines(therapistData['practice_inspiration_profiles']);
    _appendBulletSection(buffer, 'Inspirations & References', inspirationLines);

    buffer.writeln('Output Expectations:');
    buffer.writeln('- Structure sections as: Voice & Tone, Therapeutic Focus, Engagement Preferences, Safety Priorities, Inspirations.');
    buffer.writeln('- Use concise bullet points with actionable guidance tailored to the therapist.');
    buffer.writeln('- Keep the brief under 250 words and avoid generic platitudes.');
    buffer.writeln('- Highlight how the AI should sound, what approaches to emphasize, and the guardrails to respect.');
    return buffer.toString().trim();
  }

  void _appendBulletSection(StringBuffer buffer, String title, Iterable<String> lines) {
    final entries = lines.where((line) => line.trim().isNotEmpty).toList();
    if (entries.isEmpty) return;
    buffer.writeln('$title:');
    for (final line in entries) {
      buffer.writeln('- $line');
    }
    buffer.writeln();
  }

  String? _normalizeString(dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  List<String> _normalizeStringList(dynamic raw) {
    if (raw is Iterable) {
      final seen = <String>{};
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final qualification = _normalizeString(map['qualification']);
          final institution = _normalizeString(map['institution'] ?? map['university']);
          final yearRaw = map['year_completed'];
          String? yearString;
          if (yearRaw is int) {
            yearString = yearRaw.toString();
          } else if (yearRaw is String) {
            yearString = yearRaw.trim().isEmpty ? null : yearRaw.trim();
          }
          final parts = <String>[];
          if (qualification != null) parts.add(qualification);
          if (institution != null && institution.toLowerCase() != (qualification ?? '').toLowerCase()) {
            parts.add(institution);
          }
          if (yearString != null) parts.add('Completed $yearString');
          if (parts.isNotEmpty) {
            seen.add(parts.join(' • '));
            continue;
          }
          final fallback = map.values.firstWhere(
            (value) => value is String && value.toString().trim().isNotEmpty,
            orElse: () => null,
          );
          if (fallback is String) {
            final normalizedFallback = _normalizeString(fallback);
            if (normalizedFallback != null) seen.add(normalizedFallback);
          }
          continue;
        }

        final value = _normalizeString(item);
        if (value != null) seen.add(value);
      }
      return seen.toList();
    }
    return [];
  }

  List<String> _buildInspirationLines(dynamic raw) {
    if (raw is! Iterable) return [];

    final lines = <String>[];
    for (final entry in raw) {
      if (entry is Map) {
        final note = _normalizeString(entry['note']);
        final linksRaw = entry['links'];
        final linkParts = <String>[];

        if (linksRaw is Map) {
          linksRaw.forEach((key, value) {
            if (key is String) {
              final normalizedLink = _normalizeString(value);
              if (normalizedLink != null) linkParts.add('$key: $normalizedLink');
            }
          });
        }

        final parts = <String>[
          if (note != null) 'Note: $note',
          if (linkParts.isNotEmpty) 'Links -> ${linkParts.join(', ')}',
        ];

        if (parts.isNotEmpty) lines.add(parts.join('; '));
      }
    }

    return lines;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          'Therapist Training',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Container(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Text(
                            'To begin customizing your experience, please name your AI and select a profile picture. This personalized profile will be used for all your patients. We will then have a conversation to help the AI understand your unique therapeutic style and approach.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Avatar carousel section
                        _buildAvatarCarousel(),
                        const SizedBox(height: 16),
                        // Navigation arrows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _navigateAvatar(-1),
                              icon: Icon(
                                Icons.chevron_left,
                                size: 32,
                                color: const Color(0xFF94A3B8),
                              ),
                              splashRadius: 24,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () => _navigateAvatar(1),
                              icon: Icon(
                                Icons.chevron_right,
                                size: 32,
                                color: const Color(0xFF94A3B8),
                              ),
                              splashRadius: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your AI\'s personality',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Name input field
                        Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Give your AI a name',
                              hintStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: const Color(0xFF2563EB),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Start training button
                        Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          width: double.infinity,
                          child: PrimaryButton(
                            label: 'Start Training',
                            uppercase: true,
                            isLoading: _saving,
                            onPressed: _saving ? null : _handleStartTraining,
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCarousel() {
    // Calculate visible avatars (previous, current, next)
    final prevIndex = (_selectedAvatarIndex - 1) < 0
        ? _avatarOptions.length - 1
        : _selectedAvatarIndex - 1;
    final nextIndex = (_selectedAvatarIndex + 1) % _avatarOptions.length;

    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left avatar (hidden on small screens)
              if (isWide)
                Opacity(
                  opacity: 0.2,
                  child: Transform.scale(
                    scale: 0.75,
                    child: _buildAvatarItem(prevIndex, isSelected: false),
                  ),
                ),
              if (isWide) const SizedBox(width: 24),
              // Center avatar (selected)
              _buildAvatarItem(_selectedAvatarIndex, isSelected: true),
              if (isWide) const SizedBox(width: 24),
              // Right avatar
              Opacity(
                opacity: 0.4,
                child: Transform.scale(
                  scale: 0.9,
                  child: GestureDetector(
                    onTap: () => _selectAvatar(nextIndex),
                    child: _buildAvatarItem(nextIndex, isSelected: false),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarItem(int index, {required bool isSelected}) {
    final avatar = _avatarOptions[index];
    final size = isSelected ? 128.0 : 96.0;
    final iconSize = isSelected ? 48.0 : 36.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _selectAvatar(index),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatar.color,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFF2563EB),
                      width: 4,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : null,
            ),
            child: Icon(
              avatar.icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          avatar.label,
          style: TextStyle(
            fontSize: isSelected ? 18 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
