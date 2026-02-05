import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';

/// Landing colors for the dark cinematic theme
class LandingColors {
  static const dark = Color(0xFF050505);
  static const darkSurface = Color(0xFF0F0F11);
  static const glass = Color(0x0DFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
  static const accent = Color(0xFFD4D4D8);
  static const highlight = Color(0xFF3B82F6);
  static const textPrimary = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFFFFFFFF);
}

class LandingPage extends StatefulWidget {
  final bool editable;
  const LandingPage({super.key, this.editable = false});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  final _firestore = FirebaseFirestore.instance;

  // Editable text controllers
  final _kickerController = TextEditingController(text: 'The Future of');
  final _titleController = TextEditingController(text: 'Emotional Care');
  final _subtitleController = TextEditingController(
    text: 'An immersive AI companion designed to extend the therapeutic relationship beyond the session.',
  );
  final _ctaPrimaryController = TextEditingController(text: 'Begin Experience');
  final _ctaSecondaryController = TextEditingController(text: 'Sign In');
  final _nav1Controller = TextEditingController(text: 'Journal');
  final _nav2Controller = TextEditingController(text: 'Methodology');
  final _nav3Controller = TextEditingController(text: 'Access');
  final _supportQuoteController = TextEditingController(
    text: '"How are you feeling about the new job today?"',
  );
  final _supportStatusController = TextEditingController(text: 'AI ACTIVE NOW');
  final _supportDescriptionController = TextEditingController(
    text: 'Your personalized AI support system, floating in the space between sessions. Available on iOS and Android.',
  );
  final _supportTitlePrefixController = TextEditingController(text: 'Support in\nthe ');
  final _supportTitleHighlightController = TextEditingController(text: 'Void.');
  final _downloadIosController = TextEditingController(text: 'Download iOS');
  final _downloadAndroidController = TextEditingController(text: 'Android');
  final _adaptiveLabelController = TextEditingController(text: 'INTELLIGENCE LEVELS');
  final _adaptiveTitleController = TextEditingController(text: 'Adaptive Consciousness');
  final _feature1TitleController = TextEditingController(text: 'Foundational Care');
  final _feature1DescController = TextEditingController(
    text: 'Immediate support trained on global therapeutic modalities. Always present, always aware.',
  );
  final _feature2TitleController = TextEditingController(text: 'Therapist Mirroring');
  final _feature2DescController = TextEditingController(
    text: 'The AI studies your therapist\'s voice, engagement style, and specialization to create a seamless extension of care.',
  );
  final _feature3TitleController = TextEditingController(text: 'Deep Resonance');
  final _feature3DescController = TextEditingController(
    text: 'Hyper-personalized engagement based on long-term patient history, evolving needs, and subtle emotional cues.',
  );
  final _premiumBadgeController = TextEditingController(text: 'EXCLUSIVE BETA');
  final _premiumTitleController = TextEditingController(text: 'Therapii Premium');
  final _premiumSubtitleController = TextEditingController(
    text: 'Unrestricted access to the world\'s most advanced emotional intelligence engine.',
  );
  final _premiumPriceController = TextEditingController(text: '\$29');
  final _premiumPeriodController = TextEditingController(text: '/ month');
  final _premiumFeature1Controller = TextEditingController(text: '24/7 Deep Learning Analysis');
  final _premiumFeature2Controller = TextEditingController(text: 'Therapist Dashboard Integration');
  final _premiumFeature3Controller = TextEditingController(text: 'Unlimited Voice & Text Interaction');
  final _premiumCtaController = TextEditingController(text: 'Request Access');
  final _footerBrandController = TextEditingController(text: 'Therapii');
  final _footerLocationsController = TextEditingController(
    text: '© 2025 Therapii Inc. London • New York • Tokyo',
  );
  final _footerLink1Controller = TextEditingController(text: 'Instagram');
  final _footerLink2Controller = TextEditingController(text: 'Twitter');
  final _footerCopyrightController = TextEditingController(text: '© 2025 Therapii Inc.');
  final _message1Controller = TextEditingController(
    text: 'Sarah, take a deep breath. Based on your heart rate, you seem elevated.',
  );
  final _message2Controller = TextEditingController(text: 'I\'m anxious about the presentation.');
  final _message3Controller =
      TextEditingController(text: 'Let\'s visualize the outcome together. What is the best case scenario?');
  final _messagePlaceholderController = TextEditingController(text: 'Type a message...');

  bool _loadingCopy = true;
  bool _savingCopy = false;
  String? _updatedBy;
  DateTime? _updatedAt;
  bool _editMode = false;
  int _brandTapCount = 0;
  DateTime? _lastBrandTap;
  final Duration _tapWindow = const Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    if (widget.editable) {
      for (final c in [
        _kickerController,
        _titleController,
        _subtitleController,
        _ctaPrimaryController,
        _ctaSecondaryController,
        _nav1Controller,
        _nav2Controller,
        _nav3Controller,
        _supportQuoteController,
        _supportStatusController,
        _supportDescriptionController,
        _supportTitlePrefixController,
        _supportTitleHighlightController,
        _downloadIosController,
        _downloadAndroidController,
        _adaptiveLabelController,
        _adaptiveTitleController,
        _feature1TitleController,
        _feature1DescController,
        _feature2TitleController,
        _feature2DescController,
        _feature3TitleController,
        _feature3DescController,
        _premiumBadgeController,
        _premiumTitleController,
        _premiumSubtitleController,
        _premiumPriceController,
        _premiumPeriodController,
        _premiumFeature1Controller,
        _premiumFeature2Controller,
        _premiumFeature3Controller,
        _premiumCtaController,
        _footerBrandController,
        _footerLocationsController,
        _footerLink1Controller,
        _footerLink2Controller,
        _footerCopyrightController,
        _message1Controller,
        _message2Controller,
        _message3Controller,
        _messagePlaceholderController,
      ]) {
        c.addListener(() => setState(() {}));
      }
    }
    _loadLandingCopy();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _kickerController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _ctaPrimaryController.dispose();
    _ctaSecondaryController.dispose();
    _nav1Controller.dispose();
    _nav2Controller.dispose();
    _nav3Controller.dispose();
    _supportQuoteController.dispose();
    _supportStatusController.dispose();
    _supportDescriptionController.dispose();
    _supportTitlePrefixController.dispose();
    _supportTitleHighlightController.dispose();
    _downloadIosController.dispose();
    _downloadAndroidController.dispose();
    _adaptiveLabelController.dispose();
    _adaptiveTitleController.dispose();
    _feature1TitleController.dispose();
    _feature1DescController.dispose();
    _feature2TitleController.dispose();
    _feature2DescController.dispose();
    _feature3TitleController.dispose();
    _feature3DescController.dispose();
    _premiumBadgeController.dispose();
    _premiumTitleController.dispose();
    _premiumSubtitleController.dispose();
    _premiumPriceController.dispose();
    _premiumPeriodController.dispose();
    _premiumFeature1Controller.dispose();
    _premiumFeature2Controller.dispose();
    _premiumFeature3Controller.dispose();
    _premiumCtaController.dispose();
    _footerBrandController.dispose();
    _footerLocationsController.dispose();
    _footerLink1Controller.dispose();
    _footerLink2Controller.dispose();
    _footerCopyrightController.dispose();
    _message1Controller.dispose();
    _message2Controller.dispose();
    _message3Controller.dispose();
    _messagePlaceholderController.dispose();
    super.dispose();
  }

  Future<void> _loadLandingCopy() async {
    setState(() => _loadingCopy = true);
    try {
      final doc = await _firestore.collection('admin_settings').doc('landing_content').get();
      final data = doc.data();
      if (data != null) {
        _kickerController.text = (data['hero_kicker'] as String?)?.trim().isNotEmpty == true
            ? data['hero_kicker']
            : _kickerController.text;
        _titleController.text = (data['hero_title'] as String?)?.trim().isNotEmpty == true
            ? data['hero_title']
            : _titleController.text;
        _subtitleController.text = (data['hero_subtitle'] as String?)?.trim().isNotEmpty == true
            ? data['hero_subtitle']
            : _subtitleController.text;
        _ctaPrimaryController.text = (data['cta_primary'] as String?)?.trim().isNotEmpty == true
            ? data['cta_primary']
            : _ctaPrimaryController.text;
        _ctaSecondaryController.text = (data['cta_secondary'] as String?)?.trim().isNotEmpty == true
            ? data['cta_secondary']
            : _ctaSecondaryController.text;
        _nav1Controller.text = (data['nav_1'] as String?)?.trim().isNotEmpty == true
            ? data['nav_1']
            : _nav1Controller.text;
        _nav2Controller.text = (data['nav_2'] as String?)?.trim().isNotEmpty == true
            ? data['nav_2']
            : _nav2Controller.text;
        _nav3Controller.text = (data['nav_3'] as String?)?.trim().isNotEmpty == true
            ? data['nav_3']
            : _nav3Controller.text;
        _supportQuoteController.text = (data['support_quote'] as String?)?.trim().isNotEmpty == true
            ? data['support_quote']
            : _supportQuoteController.text;
        _supportStatusController.text = (data['support_status'] as String?)?.trim().isNotEmpty == true
            ? data['support_status']
            : _supportStatusController.text;
        _supportDescriptionController.text = (data['support_description'] as String?)?.trim().isNotEmpty == true
            ? data['support_description']
            : _supportDescriptionController.text;
        _supportTitlePrefixController.text = (data['support_title_prefix'] as String?)?.trim().isNotEmpty == true
            ? data['support_title_prefix']
            : _supportTitlePrefixController.text;
        _supportTitleHighlightController.text = (data['support_title_highlight'] as String?)?.trim().isNotEmpty == true
            ? data['support_title_highlight']
            : _supportTitleHighlightController.text;
        _downloadIosController.text = (data['download_ios'] as String?)?.trim().isNotEmpty == true
            ? data['download_ios']
            : _downloadIosController.text;
        _downloadAndroidController.text = (data['download_android'] as String?)?.trim().isNotEmpty == true
            ? data['download_android']
            : _downloadAndroidController.text;
        _adaptiveLabelController.text = (data['adaptive_label'] as String?)?.trim().isNotEmpty == true
            ? data['adaptive_label']
            : _adaptiveLabelController.text;
        _adaptiveTitleController.text = (data['adaptive_title'] as String?)?.trim().isNotEmpty == true
            ? data['adaptive_title']
            : _adaptiveTitleController.text;
        _feature1TitleController.text = (data['feature1_title'] as String?)?.trim().isNotEmpty == true
            ? data['feature1_title']
            : _feature1TitleController.text;
        _feature1DescController.text = (data['feature1_desc'] as String?)?.trim().isNotEmpty == true
            ? data['feature1_desc']
            : _feature1DescController.text;
        _feature2TitleController.text = (data['feature2_title'] as String?)?.trim().isNotEmpty == true
            ? data['feature2_title']
            : _feature2TitleController.text;
        _feature2DescController.text = (data['feature2_desc'] as String?)?.trim().isNotEmpty == true
            ? data['feature2_desc']
            : _feature2DescController.text;
        _feature3TitleController.text = (data['feature3_title'] as String?)?.trim().isNotEmpty == true
            ? data['feature3_title']
            : _feature3TitleController.text;
        _feature3DescController.text = (data['feature3_desc'] as String?)?.trim().isNotEmpty == true
            ? data['feature3_desc']
            : _feature3DescController.text;
        _premiumBadgeController.text = (data['premium_badge'] as String?)?.trim().isNotEmpty == true
            ? data['premium_badge']
            : _premiumBadgeController.text;
        _premiumTitleController.text = (data['premium_title'] as String?)?.trim().isNotEmpty == true
            ? data['premium_title']
            : _premiumTitleController.text;
        _premiumSubtitleController.text = (data['premium_subtitle'] as String?)?.trim().isNotEmpty == true
            ? data['premium_subtitle']
            : _premiumSubtitleController.text;
        _premiumPriceController.text = (data['premium_price'] as String?)?.trim().isNotEmpty == true
            ? data['premium_price']
            : _premiumPriceController.text;
        _premiumPeriodController.text = (data['premium_period'] as String?)?.trim().isNotEmpty == true
            ? data['premium_period']
            : _premiumPeriodController.text;
        _premiumFeature1Controller.text = (data['premium_feature1'] as String?)?.trim().isNotEmpty == true
            ? data['premium_feature1']
            : _premiumFeature1Controller.text;
        _premiumFeature2Controller.text = (data['premium_feature2'] as String?)?.trim().isNotEmpty == true
            ? data['premium_feature2']
            : _premiumFeature2Controller.text;
        _premiumFeature3Controller.text = (data['premium_feature3'] as String?)?.trim().isNotEmpty == true
            ? data['premium_feature3']
            : _premiumFeature3Controller.text;
        _premiumCtaController.text = (data['premium_cta'] as String?)?.trim().isNotEmpty == true
            ? data['premium_cta']
            : _premiumCtaController.text;
        _footerBrandController.text = (data['footer_brand'] as String?)?.trim().isNotEmpty == true
            ? data['footer_brand']
            : _footerBrandController.text;
        _footerLocationsController.text = (data['footer_locations'] as String?)?.trim().isNotEmpty == true
            ? data['footer_locations']
            : _footerLocationsController.text;
        _footerLink1Controller.text = (data['footer_link1'] as String?)?.trim().isNotEmpty == true
            ? data['footer_link1']
            : _footerLink1Controller.text;
        _footerLink2Controller.text = (data['footer_link2'] as String?)?.trim().isNotEmpty == true
            ? data['footer_link2']
            : _footerLink2Controller.text;
        _footerCopyrightController.text = (data['footer_copyright'] as String?)?.trim().isNotEmpty == true
            ? data['footer_copyright']
            : _footerCopyrightController.text;
        _message1Controller.text = (data['message1'] as String?)?.trim().isNotEmpty == true
            ? data['message1']
            : _message1Controller.text;
        _message2Controller.text = (data['message2'] as String?)?.trim().isNotEmpty == true
            ? data['message2']
            : _message2Controller.text;
        _message3Controller.text = (data['message3'] as String?)?.trim().isNotEmpty == true
            ? data['message3']
            : _message3Controller.text;
        _messagePlaceholderController.text = (data['message_placeholder'] as String?)?.trim().isNotEmpty == true
            ? data['message_placeholder']
            : _messagePlaceholderController.text;
        _updatedBy = data['updated_by'] as String?;
        final ts = data['updated_at'] as Timestamp?;
        _updatedAt = ts?.toDate();
      }
    } catch (_) {
      // keep defaults on failure
    } finally {
      if (mounted) setState(() => _loadingCopy = false);
    }
  }

  Future<void> _saveLandingCopy() async {
    setState(() => _savingCopy = true);
    try {
      final user = FirebaseAuthManager().currentUser;
      await _firestore.collection('admin_settings').doc('landing_content').set({
        'hero_kicker': _kickerController.text.trim(),
        'hero_title': _titleController.text.trim(),
        'hero_subtitle': _subtitleController.text.trim(),
        'cta_primary': _ctaPrimaryController.text.trim(),
        'cta_secondary': _ctaSecondaryController.text.trim(),
        'nav_1': _nav1Controller.text.trim(),
        'nav_2': _nav2Controller.text.trim(),
        'nav_3': _nav3Controller.text.trim(),
        'support_quote': _supportQuoteController.text.trim(),
        'support_status': _supportStatusController.text.trim(),
        'support_description': _supportDescriptionController.text.trim(),
        'support_title_prefix': _supportTitlePrefixController.text.trim(),
        'support_title_highlight': _supportTitleHighlightController.text.trim(),
        'download_ios': _downloadIosController.text.trim(),
        'download_android': _downloadAndroidController.text.trim(),
        'adaptive_label': _adaptiveLabelController.text.trim(),
        'adaptive_title': _adaptiveTitleController.text.trim(),
        'feature1_title': _feature1TitleController.text.trim(),
        'feature1_desc': _feature1DescController.text.trim(),
        'feature2_title': _feature2TitleController.text.trim(),
        'feature2_desc': _feature2DescController.text.trim(),
        'feature3_title': _feature3TitleController.text.trim(),
        'feature3_desc': _feature3DescController.text.trim(),
        'premium_badge': _premiumBadgeController.text.trim(),
        'premium_title': _premiumTitleController.text.trim(),
        'premium_subtitle': _premiumSubtitleController.text.trim(),
        'premium_price': _premiumPriceController.text.trim(),
        'premium_period': _premiumPeriodController.text.trim(),
        'premium_feature1': _premiumFeature1Controller.text.trim(),
        'premium_feature2': _premiumFeature2Controller.text.trim(),
        'premium_feature3': _premiumFeature3Controller.text.trim(),
        'premium_cta': _premiumCtaController.text.trim(),
        'footer_brand': _footerBrandController.text.trim(),
        'footer_locations': _footerLocationsController.text.trim(),
        'footer_link1': _footerLink1Controller.text.trim(),
        'footer_link2': _footerLink2Controller.text.trim(),
        'footer_copyright': _footerCopyrightController.text.trim(),
        'message1': _message1Controller.text.trim(),
        'message2': _message2Controller.text.trim(),
        'message3': _message3Controller.text.trim(),
        'message_placeholder': _messagePlaceholderController.text.trim(),
        'updated_by': user?.email ?? user?.uid ?? 'admin',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _loadLandingCopy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Landing text updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingCopy = false);
    }
  }

  void _handleBrandTap() {
    if (_editMode) return;
    final now = DateTime.now();
    if (_lastBrandTap == null || now.difference(_lastBrandTap!) > _tapWindow) {
      _brandTapCount = 0;
    }
    _brandTapCount += 1;
    _lastBrandTap = now;
    if (_brandTapCount >= 10) {
      _brandTapCount = 0;
      _showPinDialog();
    }
  }

  Future<void> _showPinDialog() async {
    final pinController = TextEditingController();
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '4-digit code',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pinController.text == '1000') {
                      setState(() => error = null);
                      Navigator.of(context).pop();
                      _enterEditMode();
                    } else {
                      setState(() => error = 'Incorrect code');
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _enterEditMode() {
    setState(() => _editMode = true);
  }

  Future<void> _openEditDialog(String label, TextEditingController controller, {bool multiline = false}) async {
    final temp = TextEditingController(text: controller.text);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: temp,
            maxLines: multiline ? 4 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.text = '';
                Navigator.of(context).pop();
                _saveLandingCopy();
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                controller.text = temp.text;
                Navigator.of(context).pop();
                _saveLandingCopy();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AuthWelcomePage(initialTab: AuthTab.login)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kicker = _kickerController.text;
    final title = _titleController.text;
    final subtitle = _subtitleController.text;
    final ctaPrimary = _ctaPrimaryController.text;
    final ctaSecondary = _ctaSecondaryController.text;
    final nav1 = _nav1Controller.text;
    final nav2 = _nav2Controller.text;
    final nav3 = _nav3Controller.text;

    return Scaffold(
      backgroundColor: LandingColors.dark,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _HeroSection(
                  shimmerController: _shimmerController,
                  floatController: _floatController,
                  onSignIn: _navigateToAuth,
                  onBeginExperience: _navigateToAuth,
                  kicker: kicker,
                  title: title,
                  subtitle: subtitle,
                  ctaPrimary: ctaPrimary,
                  ctaSecondary: ctaSecondary,
                  editMode: _editMode,
                  onEditKicker: () => _openEditDialog('Kicker', _kickerController),
                  onEditTitle: () => _openEditDialog('Title', _titleController),
                  onEditSubtitle: () => _openEditDialog('Subtitle', _subtitleController, multiline: true),
                  onEditPrimaryCta: () => _openEditDialog('Primary CTA', _ctaPrimaryController),
                  onEditSecondaryCta: () => _openEditDialog('Secondary CTA', _ctaSecondaryController),
                  floatingQuote: _supportQuoteController.text,
                  floatingStatus: _supportStatusController.text,
                  onEditFloatingQuote: () => _openEditDialog('Floating Quote', _supportQuoteController, multiline: true),
                  onEditFloatingStatus: () => _openEditDialog('Floating Status', _supportStatusController),
                ),
                _AdaptiveConsciousnessSection(
                  label: _adaptiveLabelController.text,
                  title: _adaptiveTitleController.text,
                  feature1Title: _feature1TitleController.text,
                  feature1Desc: _feature1DescController.text,
                  feature2Title: _feature2TitleController.text,
                  feature2Desc: _feature2DescController.text,
                  feature3Title: _feature3TitleController.text,
                  feature3Desc: _feature3DescController.text,
                  editMode: _editMode,
                  onEditLabel: () => _openEditDialog('Adaptive Label', _adaptiveLabelController),
                  onEditTitle: () => _openEditDialog('Adaptive Title', _adaptiveTitleController),
                  onEditFeature1Title: () => _openEditDialog('Feature I Title', _feature1TitleController),
                  onEditFeature1Desc: () => _openEditDialog('Feature I Description', _feature1DescController, multiline: true),
                  onEditFeature2Title: () => _openEditDialog('Feature II Title', _feature2TitleController),
                  onEditFeature2Desc: () => _openEditDialog('Feature II Description', _feature2DescController, multiline: true),
                  onEditFeature3Title: () => _openEditDialog('Feature III Title', _feature3TitleController),
                  onEditFeature3Desc: () => _openEditDialog('Feature III Description', _feature3DescController, multiline: true),
                ),
                _SupportInTheVoidSection(
                  floatController: _floatController,
                  glowController: _glowController,
                  titlePrefix: _supportTitlePrefixController.text,
                  titleHighlight: _supportTitleHighlightController.text,
                  quote: _supportQuoteController.text,
                  status: _supportStatusController.text,
                  description: _supportDescriptionController.text,
                  editMode: _editMode,
                  onEditQuote: () => _openEditDialog('Support Quote', _supportQuoteController, multiline: true),
                  onEditStatus: () => _openEditDialog('Support Status', _supportStatusController),
                  onEditDescription: () =>
                      _openEditDialog('Support Description', _supportDescriptionController, multiline: true),
                  onEditTitlePrefix: () =>
                      _openEditDialog('Support Title Prefix', _supportTitlePrefixController, multiline: true),
                  onEditTitleHighlight: () =>
                      _openEditDialog('Support Title Highlight', _supportTitleHighlightController),
                  onEditDownloadIos: () => _openEditDialog('Download iOS', _downloadIosController),
                  onEditDownloadAndroid: () => _openEditDialog('Download Android', _downloadAndroidController),
                  downloadIos: _downloadIosController.text,
                  downloadAndroid: _downloadAndroidController.text,
                  message1: _message1Controller.text,
                  message2: _message2Controller.text,
                  message3: _message3Controller.text,
                  messagePlaceholder: _messagePlaceholderController.text,
                  onEditMessage1: () => _openEditDialog('Message 1', _message1Controller, multiline: true),
                  onEditMessage2: () => _openEditDialog('Message 2', _message2Controller, multiline: true),
                  onEditMessage3: () => _openEditDialog('Message 3', _message3Controller, multiline: true),
                  onEditMessagePlaceholder: () =>
                      _openEditDialog('Message Placeholder', _messagePlaceholderController),
                ),
                _PremiumSection(
                  onRequestAccess: _navigateToAuth,
                  badge: _premiumBadgeController.text,
                  title: _premiumTitleController.text,
                  subtitle: _premiumSubtitleController.text,
                  price: _premiumPriceController.text,
                  period: _premiumPeriodController.text,
                  features: [
                    _premiumFeature1Controller.text,
                    _premiumFeature2Controller.text,
                    _premiumFeature3Controller.text,
                  ],
                  cta: _premiumCtaController.text,
                  editMode: _editMode,
                  onEditBadge: () => _openEditDialog('Premium Badge', _premiumBadgeController),
                  onEditTitle: () => _openEditDialog('Premium Title', _premiumTitleController),
                  onEditSubtitle: () => _openEditDialog('Premium Subtitle', _premiumSubtitleController, multiline: true),
                  onEditPrice: () => _openEditDialog('Premium Price', _premiumPriceController),
                  onEditPeriod: () => _openEditDialog('Premium Period', _premiumPeriodController),
                  onEditFeature1: () => _openEditDialog('Premium Feature 1', _premiumFeature1Controller),
                  onEditFeature2: () => _openEditDialog('Premium Feature 2', _premiumFeature2Controller),
                  onEditFeature3: () => _openEditDialog('Premium Feature 3', _premiumFeature3Controller),
                  onEditCta: () => _openEditDialog('Premium CTA', _premiumCtaController),
                ),
                _FooterSection(
                  brand: _footerBrandController.text,
                  locations: _footerLocationsController.text,
                  link1: _footerLink1Controller.text,
                  link2: _footerLink2Controller.text,
                  copyright: _footerCopyrightController.text,
                  editMode: _editMode,
                  onEditBrand: () => _openEditDialog('Footer Brand', _footerBrandController),
                  onEditLocations: () => _openEditDialog('Footer Locations', _footerLocationsController, multiline: true),
                  onEditLink1: () => _openEditDialog('Footer Link 1', _footerLink1Controller),
                  onEditLink2: () => _openEditDialog('Footer Link 2', _footerLink2Controller),
                  onEditCopyright: () =>
                      _openEditDialog('Footer Copyright', _footerCopyrightController),
                ),
              ],
            ),
          ),
          _NavBar(
            onSignIn: _navigateToAuth,
            onBrandTap: _handleBrandTap,
            brandText: _footerBrandController.text,
            nav1: nav1,
            nav2: nav2,
            nav3: nav3,
            signInLabel: ctaSecondary,
            editMode: _editMode,
            onEditNav1: () => _openEditDialog('Nav 1', _nav1Controller),
            onEditNav2: () => _openEditDialog('Nav 2', _nav2Controller),
            onEditNav3: () => _openEditDialog('Nav 3', _nav3Controller),
          ),
          if (_editMode)
            _EditChip(
              onDone: () => setState(() => _editMode = false),
              onReset: _loadLandingCopy,
            ),
          if (_editMode || widget.editable)
            _EditOverlay(
              loading: _loadingCopy,
              saving: _savingCopy,
              kickerController: _kickerController,
              titleController: _titleController,
              subtitleController: _subtitleController,
              ctaPrimaryController: _ctaPrimaryController,
              ctaSecondaryController: _ctaSecondaryController,
              nav1Controller: _nav1Controller,
              nav2Controller: _nav2Controller,
              nav3Controller: _nav3Controller,
              supportQuoteController: _supportQuoteController,
              supportStatusController: _supportStatusController,
              supportDescriptionController: _supportDescriptionController,
              supportTitlePrefixController: _supportTitlePrefixController,
              supportTitleHighlightController: _supportTitleHighlightController,
              downloadIosController: _downloadIosController,
              downloadAndroidController: _downloadAndroidController,
              adaptiveLabelController: _adaptiveLabelController,
              adaptiveTitleController: _adaptiveTitleController,
              feature1TitleController: _feature1TitleController,
              feature1DescController: _feature1DescController,
              feature2TitleController: _feature2TitleController,
              feature2DescController: _feature2DescController,
              feature3TitleController: _feature3TitleController,
              feature3DescController: _feature3DescController,
              premiumBadgeController: _premiumBadgeController,
              premiumTitleController: _premiumTitleController,
              premiumSubtitleController: _premiumSubtitleController,
              premiumPriceController: _premiumPriceController,
              premiumPeriodController: _premiumPeriodController,
              premiumFeature1Controller: _premiumFeature1Controller,
              premiumFeature2Controller: _premiumFeature2Controller,
              premiumFeature3Controller: _premiumFeature3Controller,
              premiumCtaController: _premiumCtaController,
              footerBrandController: _footerBrandController,
              footerLocationsController: _footerLocationsController,
              footerLink1Controller: _footerLink1Controller,
              footerLink2Controller: _footerLink2Controller,
              footerCopyrightController: _footerCopyrightController,
              message1Controller: _message1Controller,
              message2Controller: _message2Controller,
              message3Controller: _message3Controller,
              messagePlaceholderController: _messagePlaceholderController,
              onSave: _saveLandingCopy,
              onReset: _loadLandingCopy,
              onClose: () => setState(() => _editMode = false),
              updatedBy: _updatedBy,
              updatedAt: _updatedAt,
              showReset: true,
            ),
        ],
      ),
    );
  }
}

class _EditChip extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onReset;
  const _EditChip({required this.onDone, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text('Edit Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: onDone,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _NavBar extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onBrandTap;
  final String brandText;
  final String nav1;
  final String nav2;
  final String nav3;
  final String signInLabel;
  final bool editMode;
  final VoidCallback onEditNav1;
  final VoidCallback onEditNav2;
  final VoidCallback onEditNav3;
  const _NavBar({
    required this.onSignIn,
    required this.onBrandTap,
    required this.brandText,
    required this.nav1,
    required this.nav2,
    required this.nav3,
    required this.signInLabel,
    required this.editMode,
    required this.onEditNav1,
    required this.onEditNav2,
    required this.onEditNav3,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 48 : 16,
          vertical: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            GestureDetector(
              onTap: onBrandTap,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Therapii_image.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    brandText,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Nav links (only on wide screens)
            if (isWide)
              Row(
                children: [
                  _NavLink(label: nav1, editMode: editMode, onEdit: onEditNav1),
                  const SizedBox(width: 40),
                  _NavLink(label: nav2, editMode: editMode, onEdit: onEditNav2),
                  const SizedBox(width: 40),
                  _NavLink(label: nav3, editMode: editMode, onEdit: onEditNav3),
                ],
              ),
            // Sign In button
            if (signInLabel.trim().isNotEmpty)
              ElevatedButton(
                onPressed: onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  signInLabel,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool editMode;
  final VoidCallback? onEdit;
  const _NavLink({required this.label, required this.editMode, this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final content = Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.6),
        letterSpacing: 2,
      ),
    );
    if (!editMode) {
      return MouseRegion(cursor: SystemMouseCursors.click, child: content);
    }
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: content,
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AnimationController shimmerController;
  final AnimationController floatController;
  final VoidCallback onSignIn;
  final VoidCallback onBeginExperience;
  final String kicker;
  final String title;
  final String subtitle;
  final String ctaPrimary;
  final String ctaSecondary;
  final bool editMode;
  final VoidCallback onEditKicker;
  final VoidCallback onEditTitle;
  final VoidCallback onEditSubtitle;
  final VoidCallback onEditPrimaryCta;
  final VoidCallback onEditSecondaryCta;
  final String floatingQuote;
  final String floatingStatus;
  final VoidCallback onEditFloatingQuote;
  final VoidCallback onEditFloatingStatus;

  const _HeroSection({
    required this.shimmerController,
    required this.floatController,
    required this.onSignIn,
    required this.onBeginExperience,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.ctaPrimary,
    required this.ctaSecondary,
    required this.editMode,
    required this.onEditKicker,
    required this.onEditTitle,
    required this.onEditSubtitle,
    required this.onEditPrimaryCta,
    required this.onEditSecondaryCta,
    required this.floatingQuote,
    required this.floatingStatus,
    required this.onEditFloatingQuote,
    required this.onEditFloatingStatus,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    return SizedBox(
      height: screenHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.darken,
              ),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuD_AyA4AzHap25bGQWLucbmtBG3ukuCBXN7qPIrzM31wNFblW6bVY9bw8vxQA9y3iAnNT4G0cf9EmsesYT9KTEEnJVzDA4o7m-j1KHumoaLAu3dD6ylx0hgMc5PbXjGygq6crdfNw0IffAq9PakzyCP38AW-UF4RA4cXdO7eN5I0eP98QaXxhq7C_83XbQh4HTTlX_1nAgBPaJ-zK46x2qNmooFUG6w5TpuFMqP7BA0NS1LH-Fsc-fIPFbMIeZ3GZStay9hb8b_Q9w',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: LandingColors.dark),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shimmer text
                  _ShimmerText(
                    controller: shimmerController,
                    isWide: isWide,
                    kicker: kicker,
                    title: title,
                    editMode: editMode,
                    onEditKicker: onEditKicker,
                    onEditTitle: onEditTitle,
                  ),
                  SizedBox(height: isWide ? 32 : 24),
                  // Subtitle
                  GestureDetector(
                    onTap: editMode ? onEditSubtitle : null,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: isWide ? 20 : 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: isWide ? 48 : 32),
                  // CTA buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      if (ctaPrimary.trim().isNotEmpty)
                        GestureDetector(
                          onTap: editMode ? onEditPrimaryCta : onBeginExperience,
                          child: _GlassButton(label: ctaPrimary, onTap: onBeginExperience),
                        ),
                      const SizedBox(width: 8),
                      if (ctaSecondary.trim().isNotEmpty)
                        OutlinedButton(
                          onPressed: editMode ? onEditSecondaryCta : onSignIn,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            ctaSecondary,
                            style: GoogleFonts.dmSans(fontSize: isWide ? 14 : 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      // User avatars
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _UserAvatar(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAPYqBHJkYvOHxTg6ABVBrKxu3L3otYwP_EQhzI548wFCbgkZVnhr-AexW46rJ4zVnx79c2kcM616Zdb8QthXFvovSBPcdLM55IwOf-PboLXiXaJ-LJOd138V0VFaxA4U_N_pThpLHjHvoY8VdKXhu8JJAO3Kl8PDvIn_aXsEk6LXkllGz48p1OGMC3hjGnNGp9QxuCoH-2n3M8TnV9IOEY-mP3cMmPMYFHpVGO1DxzSD64H6QNU50EDrfmbIDFno88pRZuwP7BTIs',
                          ),
                          Transform.translate(
                            offset: const Offset(-16, 0),
                            child: _UserAvatar(
                              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCLhbTy2TcFiVmdAHSR3DRjtG6cgiBA2ec-lsWZWtBmbMkoyE4YcedJNB0XRSbqe0wm39TRUWYyJl7XtW7iM-cDijU1I59Ew0c26zTQZgZikovP1qYOZMt0Ds4ARiVxZUrMOiPfIMG7QqY30C4mbA23stXwxakcSN6INFTtxc2HIxZMU6XwLgJDxYzccUDZZkRbVifyVdc2LvXoE0_o062hN-TT9iQj_kZC7oaKQ7ryYcRtES4_zfdFBloFgBNs2yIpi9dUK5oW7QA',
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-32, 0),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Center(
                                child: Text(
                                  '+2k',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Floating AI message card (only on wide screens)
          if (isWide)
            Positioned(
              bottom: 80,
              left: 80,
              child: AnimatedBuilder(
                animation: floatController,
                builder: (context, child) {
                  final offset = Tween<double>(begin: 0, end: -20)
                      .animate(CurvedAnimation(parent: floatController, curve: Curves.easeInOut))
                      .value;
                  return Transform.translate(offset: Offset(0, offset), child: child);
                },
                child: _FloatingMessageCard(
                  quote: floatingQuote,
                  status: floatingStatus,
                  editMode: editMode,
                  onEditQuote: onEditFloatingQuote,
                  onEditStatus: onEditFloatingStatus,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShimmerText extends StatelessWidget {
  final AnimationController controller;
  final bool isWide;
  final String kicker;
  final String title;
  final bool editMode;
  final VoidCallback onEditKicker;
  final VoidCallback onEditTitle;

  const _ShimmerText({
    required this.controller,
    required this.isWide,
    required this.kicker,
    required this.title,
    required this.editMode,
    required this.onEditKicker,
    required this.onEditTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFF94A3B8),
                Colors.white,
                Color(0xFF94A3B8),
              ],
              stops: [
                controller.value - 0.3,
                controller.value,
                controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: Column(
            children: [
              GestureDetector(
                onTap: editMode ? onEditKicker : null,
                child: Text(
                  kicker,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isWide ? 80 : 40,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: editMode ? onEditTitle : null,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isWide ? 80 : 40,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditOverlay extends StatelessWidget {
  final bool loading;
  final bool saving;
  final TextEditingController kickerController;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController ctaPrimaryController;
  final TextEditingController ctaSecondaryController;
  final TextEditingController nav1Controller;
  final TextEditingController nav2Controller;
  final TextEditingController nav3Controller;
  final TextEditingController supportQuoteController;
  final TextEditingController supportStatusController;
  final TextEditingController supportDescriptionController;
  final TextEditingController supportTitlePrefixController;
  final TextEditingController supportTitleHighlightController;
  final TextEditingController downloadIosController;
  final TextEditingController downloadAndroidController;
  final TextEditingController adaptiveLabelController;
  final TextEditingController adaptiveTitleController;
  final TextEditingController feature1TitleController;
  final TextEditingController feature1DescController;
  final TextEditingController feature2TitleController;
  final TextEditingController feature2DescController;
  final TextEditingController feature3TitleController;
  final TextEditingController feature3DescController;
  final TextEditingController premiumBadgeController;
  final TextEditingController premiumTitleController;
  final TextEditingController premiumSubtitleController;
  final TextEditingController premiumPriceController;
  final TextEditingController premiumPeriodController;
  final TextEditingController premiumFeature1Controller;
  final TextEditingController premiumFeature2Controller;
  final TextEditingController premiumFeature3Controller;
  final TextEditingController premiumCtaController;
  final TextEditingController footerBrandController;
  final TextEditingController footerLocationsController;
  final TextEditingController footerLink1Controller;
  final TextEditingController footerLink2Controller;
  final TextEditingController footerCopyrightController;
  final TextEditingController message1Controller;
  final TextEditingController message2Controller;
  final TextEditingController message3Controller;
  final TextEditingController messagePlaceholderController;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final String? updatedBy;
  final DateTime? updatedAt;
  final bool showReset;

  const _EditOverlay({
    required this.loading,
    required this.saving,
    required this.kickerController,
    required this.titleController,
    required this.subtitleController,
    required this.ctaPrimaryController,
    required this.ctaSecondaryController,
    required this.nav1Controller,
    required this.nav2Controller,
    required this.nav3Controller,
    required this.supportQuoteController,
    required this.supportStatusController,
    required this.supportDescriptionController,
    required this.supportTitlePrefixController,
    required this.supportTitleHighlightController,
    required this.downloadIosController,
    required this.downloadAndroidController,
    required this.adaptiveLabelController,
    required this.adaptiveTitleController,
    required this.feature1TitleController,
    required this.feature1DescController,
    required this.feature2TitleController,
    required this.feature2DescController,
    required this.feature3TitleController,
    required this.feature3DescController,
    required this.premiumBadgeController,
    required this.premiumTitleController,
    required this.premiumSubtitleController,
    required this.premiumPriceController,
    required this.premiumPeriodController,
    required this.premiumFeature1Controller,
    required this.premiumFeature2Controller,
    required this.premiumFeature3Controller,
    required this.premiumCtaController,
    required this.footerBrandController,
    required this.footerLocationsController,
    required this.footerLink1Controller,
    required this.footerLink2Controller,
    required this.footerCopyrightController,
    required this.message1Controller,
    required this.message2Controller,
    required this.message3Controller,
    required this.messagePlaceholderController,
    required this.onSave,
    required this.onReset,
    required this.onClose,
    required this.showReset,
    this.updatedBy,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 24,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: Colors.black87),
                const SizedBox(width: 8),
                const Text('Edit Landing Text', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (updatedAt != null || updatedBy != null)
              Text(
                'Last updated${updatedBy != null ? " by $updatedBy" : ""}${updatedAt != null ? " • ${_friendlyDate(updatedAt!)}" : ""}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const SizedBox(height: 12),
            _field('Kicker', kickerController),
            _field('Title', titleController),
            _field('Subtitle', subtitleController, maxLines: 3),
            _field('Primary CTA', ctaPrimaryController),
            _field('Secondary CTA', ctaSecondaryController),
            _field('Support Quote', supportQuoteController, maxLines: 2),
            _field('Support Status', supportStatusController),
            _field('Support Description', supportDescriptionController, maxLines: 3),
            _field('Support Title Prefix', supportTitlePrefixController, maxLines: 2),
            _field('Support Title Highlight', supportTitleHighlightController),
            _field('Download iOS Label', downloadIosController),
            _field('Download Android Label', downloadAndroidController),
            _field('Adaptive Label', adaptiveLabelController),
            _field('Adaptive Title', adaptiveTitleController),
            _field('Feature I Title', feature1TitleController),
            _field('Feature I Description', feature1DescController, maxLines: 3),
            _field('Feature II Title', feature2TitleController),
            _field('Feature II Description', feature2DescController, maxLines: 3),
            _field('Feature III Title', feature3TitleController),
            _field('Feature III Description', feature3DescController, maxLines: 3),
            _field('Premium Badge', premiumBadgeController),
            _field('Premium Title', premiumTitleController),
            _field('Premium Subtitle', premiumSubtitleController, maxLines: 3),
            _field('Premium Price', premiumPriceController),
            _field('Premium Period', premiumPeriodController),
            _field('Premium Feature 1', premiumFeature1Controller),
            _field('Premium Feature 2', premiumFeature2Controller),
            _field('Premium Feature 3', premiumFeature3Controller),
            _field('Premium CTA', premiumCtaController),
            _field('Footer Brand', footerBrandController),
            _field('Footer Locations', footerLocationsController, maxLines: 2),
            _field('Footer Link 1', footerLink1Controller),
            _field('Footer Link 2', footerLink2Controller),
            _field('Footer Copyright', footerCopyrightController),
            _field('Message 1', message1Controller, maxLines: 3),
            _field('Message 2', message2Controller, maxLines: 2),
            _field('Message 3', message3Controller, maxLines: 3),
            _field('Message Placeholder', messagePlaceholderController),
            Row(
              children: [
                Expanded(child: _field('Nav 1', nav1Controller, dense: true)),
                const SizedBox(width: 8),
                Expanded(child: _field('Nav 2', nav2Controller, dense: true)),
                const SizedBox(width: 8),
                Expanded(child: _field('Nav 3', nav3Controller, dense: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(saving ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1d78ff),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                if (showReset)
                if (showReset)
                  OutlinedButton.icon(
                    onPressed: loading || saving ? null : onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, bool dense = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 8 : 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: dense,
        ),
      ),
    );
  }

  String _friendlyDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _UserAvatar extends StatelessWidget {
  final String imageUrl;

  const _UserAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipOval(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(
            opacity: 0.6,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _FloatingMessageCard extends StatelessWidget {
  final String quote;
  final String status;
  final bool editMode;
  final VoidCallback onEditQuote;
  final VoidCallback onEditStatus;

  const _FloatingMessageCard({
    required this.quote,
    required this.status,
    required this.editMode,
    required this.onEditQuote,
    required this.onEditStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 4)),
            ),
            child: GestureDetector(
              onTap: editMode ? onEditQuote : null,
              child: Text(
                quote,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: editMode ? onEditStatus : null,
                child: Text(
                  status,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdaptiveConsciousnessSection extends StatelessWidget {
  final String label;
  final String title;
  final String feature1Title;
  final String feature1Desc;
  final String feature2Title;
  final String feature2Desc;
  final String feature3Title;
  final String feature3Desc;
  final bool editMode;
  final VoidCallback onEditLabel;
  final VoidCallback onEditTitle;
  final VoidCallback onEditFeature1Title;
  final VoidCallback onEditFeature1Desc;
  final VoidCallback onEditFeature2Title;
  final VoidCallback onEditFeature2Desc;
  final VoidCallback onEditFeature3Title;
  final VoidCallback onEditFeature3Desc;

  const _AdaptiveConsciousnessSection({
    required this.label,
    required this.title,
    required this.feature1Title,
    required this.feature1Desc,
    required this.feature2Title,
    required this.feature2Desc,
    required this.feature3Title,
    required this.feature3Desc,
    required this.editMode,
    required this.onEditLabel,
    required this.onEditTitle,
    required this.onEditFeature1Title,
    required this.onEditFeature1Desc,
    required this.onEditFeature2Title,
    required this.onEditFeature2Desc,
    required this.onEditFeature3Title,
    required this.onEditFeature3Desc,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1024;
    final isMedium = screenWidth > 768;

    final features = [
      _FeatureData(
        number: 'I',
        title: feature1Title,
        description: feature1Desc,
        icon: Icons.psychology,
      ),
      _FeatureData(
        number: 'II',
        title: feature2Title,
        description: feature2Desc,
        icon: Icons.manage_accounts,
        isHighlighted: true,
      ),
      _FeatureData(
        number: 'III',
        title: feature3Title,
        description: feature3Desc,
        icon: Icons.diversity_1,
      ),
    ];

    return Container(
      color: LandingColors.dark,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: editMode ? onEditLabel : null,
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: editMode ? onEditTitle : null,
                  child: Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isMedium ? 48 : 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          // Feature cards
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final f = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _FeatureCard(
                          data: f,
                          editMode: editMode,
                          onEditTitle: () {
                            if (index == 0) onEditFeature1Title();
                            if (index == 1) onEditFeature2Title();
                            if (index == 2) onEditFeature3Title();
                          },
                          onEditDescription: () {
                            if (index == 0) onEditFeature1Desc();
                            if (index == 1) onEditFeature2Desc();
                            if (index == 2) onEditFeature3Desc();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Column(
                  children: features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final f = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _FeatureCard(
                        data: f,
                        editMode: editMode,
                        onEditTitle: () {
                          if (index == 0) onEditFeature1Title();
                          if (index == 1) onEditFeature2Title();
                          if (index == 2) onEditFeature3Title();
                        },
                        onEditDescription: () {
                          if (index == 0) onEditFeature1Desc();
                          if (index == 1) onEditFeature2Desc();
                          if (index == 2) onEditFeature3Desc();
                        },
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final bool isHighlighted;

  const _FeatureData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.isHighlighted = false,
  });
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData data;
  final bool editMode;
  final VoidCallback onEditTitle;
  final VoidCallback onEditDescription;

  const _FeatureCard({
    required this.data,
    required this.editMode,
    required this.onEditTitle,
    required this.onEditDescription,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: widget.data.isHighlighted
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: widget.data.isHighlighted
              ? [BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 50)]
              : null,
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),
            // Icon
            Positioned(
              top: 40,
              right: 40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                transform: Matrix4.identity()..scale(_isHovered ? 1.1 : 1.0),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.01),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: -5)],
                ),
                child: Icon(
                  widget.data.icon,
                  size: 40,
                  color: widget.data.isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 40,
              right: 40,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.number,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.editMode ? widget.onEditTitle : null,
                    child: Text(
                      widget.data.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: widget.editMode ? widget.onEditDescription : null,
                    child: Text(
                      widget.data.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportInTheVoidSection extends StatelessWidget {
  final AnimationController floatController;
  final AnimationController glowController;
  final String titlePrefix;
  final String titleHighlight;
  final String quote;
  final String status;
  final String description;
  final bool editMode;
  final VoidCallback onEditQuote;
  final VoidCallback onEditStatus;
  final VoidCallback onEditDescription;
  final VoidCallback onEditTitlePrefix;
  final VoidCallback onEditTitleHighlight;
  final VoidCallback onEditDownloadIos;
  final VoidCallback onEditDownloadAndroid;
  final String downloadIos;
  final String downloadAndroid;
  final String message1;
  final String message2;
  final String message3;
  final String messagePlaceholder;
  final VoidCallback onEditMessage1;
  final VoidCallback onEditMessage2;
  final VoidCallback onEditMessage3;
  final VoidCallback onEditMessagePlaceholder;

  const _SupportInTheVoidSection({
    required this.floatController,
    required this.glowController,
    required this.titlePrefix,
    required this.titleHighlight,
    required this.quote,
    required this.status,
    required this.description,
    required this.editMode,
    required this.onEditQuote,
    required this.onEditStatus,
    required this.onEditDescription,
    required this.onEditTitlePrefix,
    required this.onEditTitleHighlight,
    required this.onEditDownloadIos,
    required this.onEditDownloadAndroid,
    required this.downloadIos,
    required this.downloadAndroid,
    required this.message1,
    required this.message2,
    required this.message3,
    required this.messagePlaceholder,
    required this.onEditMessage1,
    required this.onEditMessage2,
    required this.onEditMessage3,
    required this.onEditMessagePlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 160,
      ),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF1E293B), Colors.black],
        ),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _VoidTextContent(
                    titlePrefix: titlePrefix,
                    titleHighlight: titleHighlight,
                    quote: quote,
                    status: status,
                    description: description,
                    editMode: editMode,
                    onEditQuote: onEditQuote,
                    onEditStatus: onEditStatus,
                    onEditDescription: onEditDescription,
                    onEditTitlePrefix: onEditTitlePrefix,
                    onEditTitleHighlight: onEditTitleHighlight,
                    onEditDownloadIos: onEditDownloadIos,
                    onEditDownloadAndroid: onEditDownloadAndroid,
                    downloadIos: downloadIos,
                    downloadAndroid: downloadAndroid,
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: _PhoneMockup(
                    floatController: floatController,
                    glowController: glowController,
                    message1: message1,
                    message2: message2,
                    message3: message3,
                    placeholder: messagePlaceholder,
                    editMode: editMode,
                    onEditMessage1: onEditMessage1,
                    onEditMessage2: onEditMessage2,
                    onEditMessage3: onEditMessage3,
                    onEditPlaceholder: onEditMessagePlaceholder,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _VoidTextContent(
                  titlePrefix: titlePrefix,
                  titleHighlight: titleHighlight,
                  quote: quote,
                  status: status,
                  description: description,
                  editMode: editMode,
                  onEditQuote: onEditQuote,
                  onEditStatus: onEditStatus,
                  onEditDescription: onEditDescription,
                  onEditTitlePrefix: onEditTitlePrefix,
                  onEditTitleHighlight: onEditTitleHighlight,
                  onEditDownloadIos: onEditDownloadIos,
                  onEditDownloadAndroid: onEditDownloadAndroid,
                  downloadIos: downloadIos,
                  downloadAndroid: downloadAndroid,
                ),
                const SizedBox(height: 64),
                _PhoneMockup(
                  floatController: floatController,
                  glowController: glowController,
                  message1: message1,
                  message2: message2,
                  message3: message3,
                  placeholder: messagePlaceholder,
                  editMode: editMode,
                  onEditMessage1: onEditMessage1,
                  onEditMessage2: onEditMessage2,
                  onEditMessage3: onEditMessage3,
                  onEditPlaceholder: onEditMessagePlaceholder,
                ),
              ],
            ),
    );
  }
}

class _VoidTextContent extends StatelessWidget {
  final String titlePrefix;
  final String titleHighlight;
  final String quote;
  final String status;
  final String description;
  final bool editMode;
  final VoidCallback onEditQuote;
  final VoidCallback onEditStatus;
  final VoidCallback onEditDescription;
  final VoidCallback onEditTitlePrefix;
  final VoidCallback onEditTitleHighlight;
  final VoidCallback onEditDownloadIos;
  final VoidCallback onEditDownloadAndroid;
  final String downloadIos;
  final String downloadAndroid;

  const _VoidTextContent({
    required this.titlePrefix,
    required this.titleHighlight,
    required this.quote,
    required this.status,
    required this.description,
    required this.editMode,
    required this.onEditQuote,
    required this.onEditStatus,
    required this.onEditDescription,
    required this.onEditTitlePrefix,
    required this.onEditTitleHighlight,
    required this.onEditDownloadIos,
    required this.onEditDownloadAndroid,
    required this.downloadIos,
    required this.downloadAndroid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 56,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.2,
            ),
            children: [
              WidgetSpan(
                child: GestureDetector(
                  onTap: editMode ? onEditTitlePrefix : null,
                  child: Text(titlePrefix, style: GoogleFonts.playfairDisplay(fontSize: 56, color: Colors.white)),
                ),
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: editMode ? onEditTitleHighlight : null,
                  child: Text(
                    titleHighlight,
                    style: TextStyle(
                      fontSize: 56,
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: editMode ? onEditDescription : null,
          child: Text(
            description,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (downloadIos.trim().isNotEmpty)
              ElevatedButton(
                onPressed: editMode ? onEditDownloadIos : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(downloadIos, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
              ),
            if (downloadAndroid.trim().isNotEmpty)
              OutlinedButton(
                onPressed: editMode ? onEditDownloadAndroid : () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(downloadAndroid, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0EA5E9),
              child: Icon(Icons.bolt, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: editMode ? onEditQuote : null,
                  child: Text(
                    quote,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: editMode ? onEditStatus : null,
                      child: Text(
                        status,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final AnimationController floatController;
  final AnimationController glowController;
  final String message1;
  final String message2;
  final String message3;
  final String placeholder;
  final bool editMode;
  final VoidCallback onEditMessage1;
  final VoidCallback onEditMessage2;
  final VoidCallback onEditMessage3;
  final VoidCallback onEditPlaceholder;

  const _PhoneMockup({
    required this.floatController,
    required this.glowController,
    required this.message1,
    required this.message2,
    required this.message3,
    required this.placeholder,
    required this.editMode,
    required this.onEditMessage1,
    required this.onEditMessage2,
    required this.onEditMessage3,
    required this.onEditPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          AnimatedBuilder(
            animation: glowController,
            builder: (context, child) {
              final opacity = Tween<double>(begin: 0.4, end: 0.8)
                  .animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut))
                  .value;
              return Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withValues(alpha: opacity * 0.2),
                ),
              );
            },
          ),
          // Phone
          AnimatedBuilder(
            animation: floatController,
            builder: (context, child) {
              final offset = Tween<double>(begin: 0, end: -20)
                  .animate(CurvedAnimation(parent: floatController, curve: Curves.easeInOut))
                  .value;
              return Transform.translate(offset: Offset(0, offset), child: child);
            },
            child: Container(
              width: 280,
              height: 560,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: const Color(0xFF374151), width: 8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  color: LandingColors.darkSurface,
                  child: Column(
                    children: [
                      // Status bar
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.transparent],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(Icons.menu, color: Colors.white.withValues(alpha: 0.5), size: 20),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAPYqBHJkYvOHxTg6ABVBrKxu3L3otYwP_EQhzI548wFCbgkZVnhr-AexW46rJ4zVnx79c2kcM616Zdb8QthXFvovSBPcdLM55IwOf-PboLXiXaJ-LJOd138V0VFaxA4U_N_pThpLHjHvoY8VdKXhu8JJAO3Kl8PDvIn_aXsEk6LXkllGz48p1OGMC3hjGnNGp9QxuCoH-2n3M8TnV9IOEY-mP3cMmPMYFHpVGO1DxzSD64H6QNU50EDrfmbIDFno88pRZuwP7BTIs',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chat messages
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: editMode ? onEditMessage1 : null,
                                child: _ChatBubble(isAi: true, message: message1),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: editMode ? onEditMessage2 : null,
                                child: _ChatBubble(isAi: false, message: message2),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: editMode ? onEditMessage3 : null,
                                child: _ChatBubble(isAi: true, message: message3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Input field
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: editMode ? onEditPlaceholder : null,
                                child: Text(
                                  placeholder,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              Icon(Icons.mic, color: Colors.white.withValues(alpha: 0.5), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating icons
          Positioned(
            top: 150,
            left: 20,
            child: AnimatedBuilder(
              animation: floatController,
              builder: (context, child) {
                final animValue = floatController.value;
                final delayedValue = ((animValue + 0.5) % 1.0);
                final offset = Tween<double>(begin: 0, end: -20)
                    .animate(CurvedAnimation(
                      parent: AlwaysStoppedAnimation(delayedValue),
                      curve: Curves.easeInOut,
                    ))
                    .value;
                return Transform.translate(offset: Offset(0, offset), child: child);
              },
              child: _FloatingIcon(icon: Icons.favorite, color: const Color(0xFF60A5FA)),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 20,
            child: AnimatedBuilder(
              animation: floatController,
              builder: (context, child) {
                final offset = Tween<double>(begin: 0, end: -20)
                    .animate(CurvedAnimation(parent: floatController, curve: Curves.easeInOut))
                    .value;
                return Transform.translate(offset: Offset(0, offset), child: child);
              },
              child: _FloatingIcon(icon: Icons.graphic_eq, color: const Color(0xFFA78BFA), isBlurred: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isAi;
  final String message;

  const _ChatBubble({required this.isAi, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAi) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.smart_toy, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAi
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFF2563EB).withValues(alpha: 0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isAi ? 0 : 16),
                topRight: Radius.circular(isAi ? 16 : 0),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              border: Border.all(
                color: isAi
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.3),
              ),
              boxShadow: isAi
                  ? null
                  : [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.2), blurRadius: 15)],
            ),
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: isAi ? Colors.white.withValues(alpha: 0.8) : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isBlurred;

  const _FloatingIcon({
    required this.icon,
    required this.color,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isBlurred ? 64 : 80,
      height: isBlurred ? 64 : 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
      ),
      child: Icon(icon, color: color, size: isBlurred ? 24 : 32),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final VoidCallback onRequestAccess;
  final String badge;
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final List<String> features;
  final String cta;
  final bool editMode;
  final VoidCallback onEditBadge;
  final VoidCallback onEditTitle;
  final VoidCallback onEditSubtitle;
  final VoidCallback onEditPrice;
  final VoidCallback onEditPeriod;
  final VoidCallback onEditFeature1;
  final VoidCallback onEditFeature2;
  final VoidCallback onEditFeature3;
  final VoidCallback onEditCta;

  const _PremiumSection({
    required this.onRequestAccess,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.features,
    required this.cta,
    required this.editMode,
    required this.onEditBadge,
    required this.onEditTitle,
    required this.onEditSubtitle,
    required this.onEditPrice,
    required this.onEditPeriod,
    required this.onEditFeature1,
    required this.onEditFeature2,
    required this.onEditFeature3,
    required this.onEditCta,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    return Container(
      color: LandingColors.dark,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 120,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 40)],
          ),
          child: Stack(
            children: [
              // Top glow
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1E3A5F).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    // Badge
                    GestureDetector(
                      onTap: editMode ? onEditBadge : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: editMode ? onEditTitle : null,
                      child: Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: editMode ? onEditSubtitle : null,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        GestureDetector(
                          onTap: editMode ? onEditPrice : null,
                          child: Text(
                            price,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 36,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: editMode ? onEditPeriod : null,
                          child: Text(
                            period,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Features
                    ...features.asMap().entries.map((entry) {
                      final index = entry.key;
                      final f = entry.value;
                      return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, color: Colors.white, size: 16),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: editMode
                                        ? () {
                                            if (index == 0) onEditFeature1();
                                            if (index == 1) onEditFeature2();
                                            if (index == 2) onEditFeature3();
                                          }
                                        : null,
                                    child: Text(
                                      f,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                    }),
                    const SizedBox(height: 24),
                    // CTA
                    if (cta.trim().isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: editMode ? onEditCta : onRequestAccess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            cta,
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                          ),
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

class _FooterSection extends StatelessWidget {
  final String brand;
  final String locations;
  final String link1;
  final String link2;
  final String copyright;
  final bool editMode;
  final VoidCallback onEditBrand;
  final VoidCallback onEditLocations;
  final VoidCallback onEditLink1;
  final VoidCallback onEditLink2;
  final VoidCallback onEditCopyright;

  const _FooterSection({
    required this.brand,
    required this.locations,
    required this.link1,
    required this.link2,
    required this.copyright,
    required this.editMode,
    required this.onEditBrand,
    required this.onEditLocations,
    required this.onEditLink1,
    required this.onEditLink2,
    required this.onEditCopyright,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 48,
      ),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Row(
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/images/Therapii_image.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: editMode ? onEditBrand : null,
                      child: Text(
                        brand,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                // Copyright
                GestureDetector(
                  onTap: editMode ? onEditLocations : null,
                  child: Text(
                    locations,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                // Social links
                Row(
                  children: [
                    _FooterLink(label: link1, editMode: editMode, onEdit: onEditLink1),
                    const SizedBox(width: 24),
                    _FooterLink(label: link2, editMode: editMode, onEdit: onEditLink2),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/images/Therapii_image.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: editMode ? onEditBrand : null,
                      child: Text(
                        brand,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterLink(label: link1, editMode: editMode, onEdit: onEditLink1),
                    const SizedBox(width: 24),
                    _FooterLink(label: link2, editMode: editMode, onEdit: onEditLink2),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: editMode ? onEditCopyright : null,
                  child: Text(
                    copyright,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final bool editMode;
  final VoidCallback? onEdit;

  const _FooterLink({required this.label, required this.editMode, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
    if (!editMode) {
      return MouseRegion(cursor: SystemMouseCursors.click, child: text);
    }
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: text,
      ),
    );
  }
}
