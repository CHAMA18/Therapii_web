import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/admin_settings_page.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/pages/landing_page.dart';
import 'package:therapii/pages/therapist_approvals_page.dart';
import 'package:therapii/theme_mode_controller.dart';
import 'package:therapii/utils/admin_access.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _humanConversationCount = 0;
  int _aiConversationCount = 0;
  int _pendingCount = 0;
  int _totalTherapists = 0;
  int _approvedTherapists = 0;
  int _totalPatients = 0;
  bool _loadingCounts = true;
  String? _countsError;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  StreamSubscription? _authSubscription;

  // Landing text content
  final _headlineController = TextEditingController();
  final _subheadlineController = TextEditingController();
  final _heroKickerController = TextEditingController();
  final _heroTitleController = TextEditingController();
  final _heroSubtitleController = TextEditingController();
  final _ctaPrimaryController = TextEditingController();
  final _ctaSecondaryController = TextEditingController();
  final _nav1Controller = TextEditingController();
  final _nav2Controller = TextEditingController();
  final _nav3Controller = TextEditingController();
  String? _landingUpdatedBy;
  DateTime? _landingUpdatedAt;
  bool _landingLoading = true;
  bool _landingSaving = false;
  final _landingSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _authSubscription = _auth.userChanges().listen((user) {
      if (!AdminAccess.isAdminEmail(user?.email)) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
      }
    });
    _loadCounts();
    _loadLandingContent();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _subheadlineController.dispose();
    _heroKickerController.dispose();
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _ctaPrimaryController.dispose();
    _ctaSecondaryController.dispose();
    _nav1Controller.dispose();
    _nav2Controller.dispose();
    _nav3Controller.dispose();
    _scrollController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loadingCounts = true;
      _countsError = null;
    });
    try {
      final humanAgg = await _firestore.collection('conversations').count().get();
      final aiAgg = await _firestore.collection('ai_conversation_summaries').count().get();
      final therapistsAgg = await _firestore.collection('therapists').count().get();
      final approvedAgg = await _firestore.collection('therapists').where('approval_status', isEqualTo: 'approved').count().get();
      final patientsAgg = await _firestore.collection('users').where('role', isEqualTo: 'patient').count().get();
      if (!mounted) return;
      setState(() {
        _humanConversationCount = humanAgg.count ?? 0;
        _aiConversationCount = aiAgg.count ?? 0;
        _totalTherapists = therapistsAgg.count ?? 0;
        _approvedTherapists = approvedAgg.count ?? 0;
        _totalPatients = patientsAgg.count ?? 0;
        _loadingCounts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _countsError = 'Unable to load conversation totals. $e';
        _loadingCounts = false;
      });
    }
  }

  Future<void> _loadLandingContent() async {
    setState(() {
      _landingLoading = true;
    });
    try {
      final doc = await _firestore.collection('admin_settings').doc('landing_content').get();
      final data = doc.data();
      final headline = (data?['headline'] as String?)?.trim();
      final subheadline = (data?['subheadline'] as String?)?.trim();
      final kicker = (data?['hero_kicker'] as String?)?.trim();
      final heroTitle = (data?['hero_title'] as String?)?.trim();
      final heroSubtitle = (data?['hero_subtitle'] as String?)?.trim();
      final ctaPrimary = (data?['cta_primary'] as String?)?.trim();
      final ctaSecondary = (data?['cta_secondary'] as String?)?.trim();
      final nav1 = (data?['nav_1'] as String?)?.trim();
      final nav2 = (data?['nav_2'] as String?)?.trim();
      final nav3 = (data?['nav_3'] as String?)?.trim();
      _landingUpdatedBy = data?['updated_by'] as String?;
      final ts = data?['updated_at'] as Timestamp?;
      _landingUpdatedAt = ts?.toDate();
      _headlineController.text = headline?.isNotEmpty == true ? headline! : 'Good afternoon,';
      _subheadlineController.text = subheadline?.isNotEmpty == true
          ? subheadline!
          : 'Manage approvals, monitor activity, and configure the platform settings for your therapy network.';
      _heroKickerController.text = kicker?.isNotEmpty == true ? kicker! : 'The Future of';
      _heroTitleController.text = heroTitle?.isNotEmpty == true ? heroTitle! : 'Emotional Care';
      _heroSubtitleController.text = heroSubtitle?.isNotEmpty == true
          ? heroSubtitle!
          : 'An immersive AI companion designed to extend the therapeutic relationship beyond the session.';
      _ctaPrimaryController.text = ctaPrimary?.isNotEmpty == true ? ctaPrimary! : 'Begin Experience';
      _ctaSecondaryController.text = ctaSecondary?.isNotEmpty == true ? ctaSecondary! : 'Sign In';
      _nav1Controller.text = nav1?.isNotEmpty == true ? nav1! : 'Journal';
      _nav2Controller.text = nav2?.isNotEmpty == true ? nav2! : 'Methodology';
      _nav3Controller.text = nav3?.isNotEmpty == true ? nav3! : 'Access';
    } catch (e) {
      _showSnack('Failed to load landing content: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _landingLoading = false);
      }
    }
  }

  Future<void> _saveLandingContent() async {
    final headline = _headlineController.text.trim();
    final sub = _subheadlineController.text.trim();
    final kicker = _heroKickerController.text.trim();
    final heroTitle = _heroTitleController.text.trim();
    final heroSubtitle = _heroSubtitleController.text.trim();
    final ctaPrimary = _ctaPrimaryController.text.trim();
    final ctaSecondary = _ctaSecondaryController.text.trim();
    final nav1 = _nav1Controller.text.trim();
    final nav2 = _nav2Controller.text.trim();
    final nav3 = _nav3Controller.text.trim();
    if (headline.isEmpty) {
      _showSnack('Headline cannot be empty.', isError: true);
      return;
    }
    setState(() => _landingSaving = true);
    try {
      final user = _auth.currentUser;
      await _firestore.collection('admin_settings').doc('landing_content').set({
        'headline': headline,
        'subheadline': sub,
        'hero_kicker': kicker,
        'hero_title': heroTitle,
        'hero_subtitle': heroSubtitle,
        'cta_primary': ctaPrimary,
        'cta_secondary': ctaSecondary,
        'nav_1': nav1,
        'nav_2': nav2,
        'nav_3': nav3,
        'updated_by': user?.email ?? user?.uid ?? 'admin',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _loadLandingContent();
      _showSnack('Landing content saved.');
    } catch (e) {
      _showSnack('Failed to save landing content: $e', isError: true);
    } finally {
      if (mounted) setState(() => _landingSaving = false);
    }
  }

  void _clearLandingContent() {
    _headlineController.clear();
    _subheadlineController.clear();
    _heroKickerController.clear();
    _heroTitleController.clear();
    _heroSubtitleController.clear();
    _ctaPrimaryController.clear();
    _ctaSecondaryController.clear();
    _nav1Controller.clear();
    _nav2Controller.clear();
    _nav3Controller.clear();
  }

  Future<void> _scrollToLandingEditor() async {
    final ctx = _landingSectionKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.05,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _textFieldDecoration(bool isDark, Color primaryColor, {required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF1f2a3d) : const Color(0xFFf8fafc),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'just now';
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _approveTherapist(String therapistId) async {
    final currentUser = FirebaseAuthManager().currentUser;
    try {
      await _firestore.collection('therapists').doc(therapistId).set({
        'approval_status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': currentUser?.uid,
        'approved_by_email': currentUser?.email,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapist approved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve therapist. $e')),
      );
    }
  }

  Future<void> _rejectTherapist(String therapistId) async {
    final currentUser = FirebaseAuthManager().currentUser;
    try {
      await _firestore.collection('therapists').doc(therapistId).set({
        'approval_status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
        'rejected_by': currentUser?.uid,
        'rejected_by_email': currentUser?.email,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapist rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject therapist. $e')),
      );
    }
  }

  void _showTherapistDetails(Map<String, dynamic> data) {
    final educations = _resolveEducationSummaries(data);
    final licensure = List<String>.from(data['state_licensures'] ?? const <String>[]);
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) {
        final padding = EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 32,
          top: 32,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['full_name'] ?? 'Therapist details',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['practice_name'] ?? 'Private Practice',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(title: 'Contact Information'),
                        const SizedBox(height: 12),
                        _DetailItem(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: _formatLocation(data),
                        ),
                        _DetailItem(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: data['contact_email'],
                        ),
                        _DetailItem(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: data['contact_phone'],
                        ),
                        const SizedBox(height: 24),
                        if (licensure.isNotEmpty) ...[
                          _SectionHeader(title: 'State Licensure'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: licensure
                                .map((item) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.primaryContainer,
                                        ),
                                      ),
                                      child: Text(
                                        item,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (educations.isNotEmpty) ...[
                          _SectionHeader(title: 'Education'),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final entry in educations)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6, right: 12),
                                        child: Icon(
                                          Icons.school_outlined,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry,
                                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _adminName() {
    final user = _auth.currentUser;
    final email = user?.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF1d78ff);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Sticky Navigation Bar
          _buildNavBar(theme, isDark, primaryColor),
          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadCounts();
                await _loadLandingContent();
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeader(theme, isDark, primaryColor),
                        // Action Cards Grid
                        _buildActionCardsGrid(theme, isDark, primaryColor),
                        const SizedBox(height: 48),
                        // Pending Approvals Table
                        _buildPendingApprovalsTable(theme, isDark, primaryColor),
                        const SizedBox(height: 48),
                        // Analytics & Activity Row
                        _buildAnalyticsActivityRow(theme, isDark, primaryColor),
                        const SizedBox(height: 48),
                        // System Status Section
                        _buildSystemStatusSection(theme, isDark, primaryColor),
                        const SizedBox(height: 48),
                        // Footer
                        _buildFooter(theme, isDark),
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

  Widget _buildNavBar(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0f172a) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
          ),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/Therapii_image.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AdminPanel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (MediaQuery.of(context).size.width > 768) ...[
                _NavLink(label: 'Home', isActive: true, primaryColor: primaryColor, isDark: isDark),
                _NavLink(
                  label: 'Approvals',
                  isActive: false,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TherapistApprovalsPage()),
                  ),
                ),
                _NavLink(
                  label: 'Settings',
                  isActive: false,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
                const SizedBox(width: 16),
              ],
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
                onPressed: () => themeModeController.toggleLightDark(),
              ),
              const SizedBox(width: 8),
              _buildUserProfile(theme, isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(ThemeData theme, bool isDark, Color primaryColor) {
    final name = _adminName();
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              const Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text('Sign out', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await FirebaseAuthManager().signOut();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWelcomePage(initialTab: AuthTab.login)),
            (route) => false,
          );
        } else if (value == 'settings') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1e3a5f) : const Color(0xFFdbeafe),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (MediaQuery.of(context).size.width > 600) ...[
              const SizedBox(width: 8),
              Text(
                '${name.substring(0, name.length > 10 ? 10 : name.length)}${name.length > 10 ? '.' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()},',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _adminName(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage approvals, monitor activity, and configure the platform settings for your therapy network.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1e293b) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildLandingEditor(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      key: _landingSectionKey,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b).withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1e293b) : const Color(0xFFdbeafe),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_note_rounded, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Landing Page Text Content',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Update the headline and supporting text shown on the landing page.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (_landingUpdatedAt != null || _landingUpdatedBy != null)
                Text(
                  'Last updated${_landingUpdatedBy != null ? " by $_landingUpdatedBy" : ""}${_landingUpdatedAt != null ? " • ${_formatDate(_landingUpdatedAt!)}" : ""}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _headlineController,
            enabled: !_landingLoading && !_landingSaving,
            decoration: InputDecoration(
              labelText: 'Headline',
              hintText: 'Good afternoon,',
              filled: true,
              fillColor: isDark ? const Color(0xFF1f2a3d) : const Color(0xFFf8fafc),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _subheadlineController,
            enabled: !_landingLoading && !_landingSaving,
            maxLines: 3,
            decoration: _textFieldDecoration(isDark, primaryColor,
                label: 'Subheadline',
                hint: 'Manage approvals, monitor activity...'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heroKickerController,
            enabled: !_landingLoading && !_landingSaving,
            decoration: _textFieldDecoration(isDark, primaryColor,
                label: 'Hero kicker', hint: 'The Future of'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _heroTitleController,
            enabled: !_landingLoading && !_landingSaving,
            decoration: _textFieldDecoration(isDark, primaryColor,
                label: 'Hero title', hint: 'Emotional Care'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _heroSubtitleController,
            enabled: !_landingLoading && !_landingSaving,
            maxLines: 3,
            decoration: _textFieldDecoration(
              isDark,
              primaryColor,
              label: 'Hero subtitle',
              hint: 'An immersive AI companion designed to extend the therapeutic relationship beyond the session.',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctaPrimaryController,
            enabled: !_landingLoading && !_landingSaving,
            decoration: _textFieldDecoration(isDark, primaryColor,
                label: 'Primary CTA', hint: 'Begin Experience'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctaSecondaryController,
            enabled: !_landingLoading && !_landingSaving,
            decoration: _textFieldDecoration(isDark, primaryColor,
                label: 'Secondary CTA', hint: 'Sign In'),
          ),
          const SizedBox(height: 14),
          Text(
            'Nav links',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nav1Controller,
                  enabled: !_landingLoading && !_landingSaving,
                  decoration: _textFieldDecoration(isDark, primaryColor,
                      label: 'Nav 1', hint: 'Journal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nav2Controller,
                  enabled: !_landingLoading && !_landingSaving,
                  decoration: _textFieldDecoration(isDark, primaryColor,
                      label: 'Nav 2', hint: 'Methodology'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nav3Controller,
                  enabled: !_landingLoading && !_landingSaving,
                  decoration: _textFieldDecoration(isDark, primaryColor,
                      label: 'Nav 3', hint: 'Access'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _landingSaving ? null : _saveLandingContent,
                icon: _landingSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_landingSaving ? 'Saving...' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _landingLoading || _landingSaving ? null : _loadLandingContent,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              TextButton.icon(
                onPressed: _landingSaving ? null : _clearLandingContent,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCardsGrid(ThemeData theme, bool isDark, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width >= 1440) {
          crossAxisCount = 5;
        } else if (width >= 1024) {
          crossAxisCount = 4;
        } else if (width >= 640) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final cards = [
          _ActionCard(
            title: 'Therapist Approvals',
            subtitle: '$_pendingCount new clinicians pending',
            icon: Icons.verified_user_outlined,
            isPrimary: true,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TherapistApprovalsPage()),
            ),
          ),
          _ActionCard(
            title: 'Admin Settings',
            subtitle: 'OpenAI, SendGrid and keys',
            icon: Icons.auto_fix_high_outlined,
            isPrimary: false,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
            ),
          ),
          _ActionCard(
            title: 'Sessions',
            subtitle: _loadingCounts ? 'Loading...' : '$_humanConversationCount active sessions today',
            icon: Icons.forum_outlined,
            isPrimary: false,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: _loadCounts,
          ),
          _ActionCard(
            title: 'AI Chats',
            subtitle: _loadingCounts ? 'Loading...' : '$_aiConversationCount assistant interactions',
            icon: Icons.smart_toy_outlined,
            isPrimary: false,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: _loadCounts,
          ),
          _ActionCard(
            title: 'Edit Text Content',
            subtitle: 'Update landing page copy',
            icon: Icons.edit_note_rounded,
            isPrimary: false,
            primaryColor: primaryColor,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LandingPage(editable: true)),
            ),
          ),
        ];

        if (crossAxisCount == 1) {
          return Column(
            children: cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: card,
            )).toList(),
          );
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: crossAxisCount >= 4 ? 1.1 : (crossAxisCount == 2 ? 1.2 : 1.1),
          children: cards,
        );
      },
    );
  }

  Widget _buildPendingApprovalsTable(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b).withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(Icons.verified, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Pending Approvals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TherapistApprovalsPage()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new, color: primaryColor, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Table Content
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('therapists').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(64),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: _errorState(theme, 'Unable to load therapist submissions. ${snapshot.error}'),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              final pending = docs.where((doc) {
                final status = (doc.data()['approval_status'] as String?)?.toLowerCase();
                return status == null || status == 'pending' || status == 'resubmitted' || status == 'needs_review';
              }).toList()
                ..sort((a, b) {
                  final aTs = a.data()['approval_requested_at'] as Timestamp? ?? a.data()['created_at'] as Timestamp?;
                  final bTs = b.data()['approval_requested_at'] as Timestamp? ?? b.data()['created_at'] as Timestamp?;
                  final aDate = aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

              // Update pending count
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pendingCount != pending.length) {
                  setState(() {
                    _pendingCount = pending.length;
                  });
                }
              });

              if (pending.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending approvals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Great job! You\'re all caught up.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final displayList = pending.take(5).toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1e293b).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 200, child: _TableHeader('Applicant', isDark)),
                            SizedBox(width: 120, child: _TableHeader('Identity / ID', isDark)),
                            SizedBox(width: 120, child: _TableHeader('Location', isDark)),
                            SizedBox(width: 120, child: _TableHeader('Applied Date', isDark)),
                            const SizedBox(width: 140),
                          ],
                        ),
                      ),
                      // Table Rows
                      ...displayList.map((doc) {
                        final data = doc.data();
                        return _buildTableRow(doc.id, data, isDark, primaryColor);
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
                ),
              ),
            ),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TherapistApprovalsPage()),
                ),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('View Full History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String docId, Map<String, dynamic> data, bool isDark, Color primaryColor) {
    final name = (data['full_name'] ?? 'New Applicant').toString();
    final id = data['license_number']?.toString() ?? docId.substring(0, 8);
    final city = (data['city'] ?? '').toString();
    final state = (data['state'] ?? '').toString();
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');
    
    final timestamp = data['approval_requested_at'] as Timestamp? ?? data['created_at'] as Timestamp?;
    final dateStr = timestamp != null ? _formatTimeAgo(timestamp.toDate()) : 'Unknown';

    return InkWell(
      onTap: () => _showTherapistDetails(data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
            ),
          ),
        ),
        child: Row(
          children: [
            // Applicant
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1e3a5f) : const Color(0xFFdbeafe),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // ID
            SizedBox(
              width: 120,
              child: Text(
                id,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Location
            SizedBox(
              width: 120,
              child: Text(
                location.isNotEmpty ? location : '—',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            SizedBox(
              width: 120,
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
              ),
            ),
            // Actions
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reject Button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFf1f5f9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                      ),
                      onPressed: () => _rejectTherapist(docId),
                      tooltip: 'Reject',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Approve Button
                  Material(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _approveTherapist(docId),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Approve',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildAnalyticsActivityRow(ThemeData theme, bool isDark, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildAnalyticsSection(theme, isDark, primaryColor)),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildRecentActivitySection(theme, isDark, primaryColor)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildAnalyticsSection(theme, isDark, primaryColor),
              const SizedBox(height: 24),
              _buildRecentActivitySection(theme, isDark, primaryColor),
            ],
          );
        }
      },
    );
  }

  Widget _buildAnalyticsSection(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b).withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Platform Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10b981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 600
                    ? (constraints.maxWidth - 48) / 3
                    : (constraints.maxWidth - 16) / 2;
                
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _AnalyticCard(
                      title: 'Total Therapists',
                      value: _loadingCounts ? '...' : '$_totalTherapists',
                      change: '+12%',
                      isPositive: true,
                      icon: Icons.psychology_outlined,
                      color: primaryColor,
                      isDark: isDark,
                      width: cardWidth,
                    ),
                    _AnalyticCard(
                      title: 'Approved',
                      value: _loadingCounts ? '...' : '$_approvedTherapists',
                      change: '+8%',
                      isPositive: true,
                      icon: Icons.verified_outlined,
                      color: const Color(0xFF10b981),
                      isDark: isDark,
                      width: cardWidth,
                    ),
                    _AnalyticCard(
                      title: 'Total Patients',
                      value: _loadingCounts ? '...' : '$_totalPatients',
                      change: '+24%',
                      isPositive: true,
                      icon: Icons.people_outline,
                      color: const Color(0xFF8b5cf6),
                      isDark: isDark,
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
          ),
          // Progress indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Approval Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                      ),
                    ),
                    Text(
                      _totalTherapists > 0
                          ? '${((_approvedTherapists / _totalTherapists) * 100).toStringAsFixed(0)}%'
                          : '0%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _totalTherapists > 0
                        ? (_approvedTherapists / _totalTherapists).clamp(0.0, 1.0)
                        : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, const Color(0xFF10b981)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  Widget _buildRecentActivitySection(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b).withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(Icons.history, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('therapists')
                .orderBy('updated_at', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: [
                  ...docs.map((doc) {
                    final data = doc.data();
                    final status = (data['approval_status'] as String?)?.toLowerCase() ?? 'pending';
                    final name = data['full_name'] ?? 'Unknown';
                    final timestamp = data['updated_at'] as Timestamp?;
                    final timeStr = timestamp != null ? _formatTimeAgo(timestamp.toDate()) : 'Unknown';
                    
                    IconData icon;
                    Color iconColor;
                    String action;
                    
                    switch (status) {
                      case 'approved':
                        icon = Icons.check_circle;
                        iconColor = const Color(0xFF10b981);
                        action = 'was approved';
                        break;
                      case 'rejected':
                        icon = Icons.cancel;
                        iconColor = const Color(0xFFef4444);
                        action = 'was rejected';
                        break;
                      case 'resubmitted':
                        icon = Icons.refresh;
                        iconColor = const Color(0xFFf59e0b);
                        action = 'resubmitted application';
                        break;
                      default:
                        icon = Icons.hourglass_empty;
                        iconColor = primaryColor;
                        action = 'submitted application';
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: iconColor, size: 18),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      TextSpan(
                                        text: ' $action',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusSection(ThemeData theme, bool isDark, Color primaryColor) {
    final statusItems = [
      _SystemStatus(
        name: 'Firebase Services',
        status: 'Operational',
        isHealthy: true,
        icon: Icons.cloud_outlined,
      ),
      _SystemStatus(
        name: 'Authentication',
        status: 'Operational',
        isHealthy: true,
        icon: Icons.lock_outlined,
      ),
      _SystemStatus(
        name: 'AI Processing',
        status: 'Operational',
        isHealthy: true,
        icon: Icons.psychology_outlined,
      ),
      _SystemStatus(
        name: 'Email Service',
        status: 'Operational',
        isHealthy: true,
        icon: Icons.email_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b).withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF10b981), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'All Systems Operational',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: crossAxisCount == 1 ? 4 : 2.2,
                  children: statusItems.map((item) => _buildStatusCard(item, isDark)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(_SystemStatus item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isHealthy
                  ? const Color(0xFF10b981).withValues(alpha: 0.1)
                  : const Color(0xFFef4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: item.isHealthy ? const Color(0xFF10b981) : const Color(0xFFef4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.isHealthy ? const Color(0xFF10b981) : const Color(0xFFef4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isHealthy ? const Color(0xFF10b981) : const Color(0xFFef4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '© 2024 Admin Therapy Platform. All rights reserved.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
          ),
        ),
      ),
    );
  }

  Widget _errorState(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.errorContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatLocation(Map<String, dynamic> data) {
    final city = (data['city'] ?? '').toString().trim();
    final state = (data['state'] ?? '').toString().trim();
    final zip = (data['zip_code'] ?? '').toString().trim();
    return [city, state, zip].where((part) => part.isNotEmpty).join(', ');
  }

  static List<String> _resolveEducationSummaries(Map<String, dynamic> data) {
    final entries = <String>{};
    final rawEntries = data['education_entries'];
    if (rawEntries is Iterable) {
      for (final item in rawEntries) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final summary = _formatEducationMap(map);
          if (summary.trim().isNotEmpty) entries.add(summary);
        }
      }
    }
    final legacy = data['educations'];
    if (legacy is Iterable) {
      for (final item in legacy) {
        if (item is String && item.trim().isNotEmpty) {
          entries.add(item.trim());
        }
      }
    }
    return entries.toList();
  }

  static String _formatEducationMap(Map<String, dynamic> map) {
    final qualification = (map['qualification'] ?? '').toString().trim();
    final institution = (map['institution'] ?? map['university'] ?? '').toString().trim();
    final year = map['year_completed']?.toString().trim();
    final parts = [
      if (qualification.isNotEmpty) qualification,
      if (institution.isNotEmpty) institution,
      if (year != null && year.isNotEmpty) 'Completed $year',
    ];
    return parts.join(' • ');
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _NavLink({
    required this.label,
    required this.isActive,
    required this.primaryColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? primaryColor
                  : (isDark ? const Color(0xFF64748b) : const Color(0xFF64748b)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.primaryColor,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: Material(
          color: widget.isPrimary
              ? widget.primaryColor
              : (widget.isDark ? const Color(0xFF1e293b).withValues(alpha: 0.5) : Colors.white),
          borderRadius: BorderRadius.circular(32),
          elevation: widget.isPrimary ? 8 : 0,
          shadowColor: widget.isPrimary ? widget.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: widget.isPrimary
                    ? null
                    : Border.all(
                        color: _isHovered
                            ? widget.primaryColor.withValues(alpha: 0.5)
                            : (widget.isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0)),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.isPrimary
                              ? Colors.white.withValues(alpha: 0.2)
                              : (widget.isDark
                                  ? const Color(0xFF1e3a5f).withValues(alpha: 0.3)
                                  : const Color(0xFFdbeafe)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isPrimary ? Colors.white : widget.primaryColor,
                          size: 24,
                        ),
                      ),
                      if (widget.isPrimary)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isPrimary
                              ? Colors.white
                              : (widget.isDark ? Colors.white : const Color(0xFF0f172a)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isPrimary
                              ? Colors.white.withValues(alpha: 0.8)
                              : (widget.isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _TableHeader(this.label, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _AnalyticCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final bool isDark;
  final double width;

  const _AnalyticCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF10b981).withValues(alpha: 0.1)
                        : const Color(0xFFef4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemStatus {
  final String name;
  final String status;
  final bool isHealthy;
  final IconData icon;

  const _SystemStatus({
    required this.name,
    required this.status,
    required this.isHealthy,
    required this.icon,
  });
}
