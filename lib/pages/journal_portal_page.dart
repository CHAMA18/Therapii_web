import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/models/ai_conversation_summary.dart';
import 'package:therapii/pages/admin_dashboard_page.dart';
import 'package:therapii/pages/landing_page.dart';
import 'package:therapii/pages/journal_article_page.dart';
import 'package:therapii/pages/landing_page.dart';
import 'package:therapii/pages/my_patients_page.dart';
import 'package:therapii/pages/patient_dashboard_page.dart';
import 'package:therapii/pages/patient_onboarding_flow_page.dart';
import 'package:therapii/services/ai_conversation_service.dart';
import 'package:therapii/services/app_page_state_service.dart';
import 'package:therapii/services/therapist_service.dart';
import 'package:therapii/services/user_service.dart';
import 'package:therapii/theme_mode_controller.dart';
import 'package:therapii/utils/admin_access.dart';

enum _PortalSidebarItem { home, journal, favorites }

const _portalDestinationKey = 'journal_portal_destination';
const _portalDestinationHome = 'home';
const _portalDestinationJournal = 'journal';
const _portalDestinationFavorites = 'favorites';
const _portalSidebarWidthKey = 'journal_portal_sidebar_width';
const _defaultPortalSidebarWidth = 276.0;
const _minPortalSidebarWidth = 248.0;
const _maxPortalSidebarWidth = 360.0;

double _clampPortalSidebarWidth(double width) {
  final clamped = width.clamp(_minPortalSidebarWidth, _maxPortalSidebarWidth);
  return (clamped as num).toDouble();
}

Future<double> _loadPortalSidebarWidth() async {
  final prefs = await SharedPreferences.getInstance();
  final storedWidth =
      prefs.getDouble(_portalSidebarWidthKey) ?? _defaultPortalSidebarWidth;
  return _clampPortalSidebarWidth(storedWidth);
}

Future<void> _persistPortalSidebarWidth(double width) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(
      _portalSidebarWidthKey, _clampPortalSidebarWidth(width));
}

Route<void> _buildPortalSwitchRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<void> _switchToTherapiiSession(BuildContext context) async {
  final user = FirebaseAuthManager().currentUser;
  if (user == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please sign in again to switch into your Therapii session.')),
      );
    }
    return;
  }

  try {
    Widget destination;
    final email = user.email ?? '';

    if (AdminAccess.isAdminEmail(email)) {
      destination = const AdminDashboardPage();
    } else {
      final profile = await UserService().getUser(user.uid);
      final therapistProfile =
          await TherapistService().getTherapistByUserId(user.uid);
      final isTherapist =
          profile?.isTherapist == true || therapistProfile != null;

      destination = isTherapist
          ? const MyPatientsPage()
          : ((profile?.patientOnboardingCompleted ?? false)
              ? const PatientDashboardPage()
              : const PatientOnboardingFlowPage());
    }

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(_buildPortalSwitchRoute(destination));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Unable to switch to your Therapii session right now.')),
    );
  }
}

class _PortalPalette {
  final bool isDark;
  final Color scaffold;
  final Color panel;
  final Color panelStrong;
  final Color panelSoft;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color railTop;
  final Color railBottom;
  final Color railBorder;
  final Color navActiveBackground;
  final Color navActiveText;
  final Color navInactiveIcon;
  final Color navInactiveText;
  final Color controlBackground;
  final Color controlForeground;
  final Color controlBorder;
  final Color shadow;
  final Color handle;
  final Color ambientPrimary;
  final Color ambientSecondary;
  final Color subtleTint;
  final Color analysisIconBackground;
  final Color loadMoreBackground;

  const _PortalPalette({
    required this.isDark,
    required this.scaffold,
    required this.panel,
    required this.panelStrong,
    required this.panelSoft,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.railTop,
    required this.railBottom,
    required this.railBorder,
    required this.navActiveBackground,
    required this.navActiveText,
    required this.navInactiveIcon,
    required this.navInactiveText,
    required this.controlBackground,
    required this.controlForeground,
    required this.controlBorder,
    required this.shadow,
    required this.handle,
    required this.ambientPrimary,
    required this.ambientSecondary,
    required this.subtleTint,
    required this.analysisIconBackground,
    required this.loadMoreBackground,
  });

  factory _PortalPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return _PortalPalette(
        isDark: true,
        scaffold: const Color(0xFF0B1220),
        panel: const Color(0xFF111A2B),
        panelStrong: const Color(0xFF0F172A),
        panelSoft: const Color(0xFF162134),
        border: const Color(0xFF243146),
        divider: const Color(0xFF223047),
        textPrimary: scheme.onSurface,
        textSecondary: const Color(0xFFC4CEE0),
        textMuted: const Color(0xFF90A0B8),
        railTop: const Color(0xFF0D1523),
        railBottom: const Color(0xFF0A1320),
        railBorder: const Color(0xFF233148),
        navActiveBackground: scheme.primary.withValues(alpha: 0.22),
        navActiveText: const Color(0xFF83B4FF),
        navInactiveIcon: const Color(0xFF96A3B9),
        navInactiveText: const Color(0xFFC0CADB),
        controlBackground: const Color(0xFF141F31),
        controlForeground: scheme.onSurface,
        controlBorder: const Color(0xFF2A3952),
        shadow: Colors.black.withValues(alpha: 0.3),
        handle: const Color(0xFF2E405E),
        ambientPrimary: const Color(0x441754CF),
        ambientSecondary: const Color(0x221856B5),
        subtleTint: const Color(0x221754CF),
        analysisIconBackground: const Color(0xFF1A2942),
        loadMoreBackground: const Color(0xFF131D2E),
      );
    }

    return const _PortalPalette(
      isDark: false,
      scaffold: Color(0xFFF4F6FB),
      panel: Color(0xFFFDFDFF),
      panelStrong: Colors.white,
      panelSoft: Color(0xFFF7F9FF),
      border: Color(0xFFDDE3EF),
      divider: Color(0xFFE1E7F5),
      textPrimary: Color(0xFF111726),
      textSecondary: Color(0xFF6E7482),
      textMuted: Color(0xFF94A3B8),
      railTop: Color(0xFFF7F9FF),
      railBottom: Color(0xFFF0F4FF),
      railBorder: Color(0xFFE1E7F5),
      navActiveBackground: Color(0xFFDCE8FF),
      navActiveText: Color(0xFF1754CF),
      navInactiveIcon: Color(0xFF697386),
      navInactiveText: Color(0xFF283245),
      controlBackground: Colors.white,
      controlForeground: Color(0xFF0F172A),
      controlBorder: Color(0xFFE1E7F5),
      shadow: Color(0x140B1324),
      handle: Color(0xFFD7E1F2),
      ambientPrimary: Color(0x331754CF),
      ambientSecondary: Color(0x191856B5),
      subtleTint: Color(0xFFE9F1FF),
      analysisIconBackground: Color(0xFFE9F1FF),
      loadMoreBackground: Colors.white,
    );
  }
}

class JournalPortalPage extends StatefulWidget {
  const JournalPortalPage({super.key});

  @override
  State<JournalPortalPage> createState() => _JournalPortalPageState();
}

class _JournalPortalPageState extends State<JournalPortalPage> {
  static const int _initialVisibleCardCount = 5;
  static const int _loadMoreBatchSize = 4;

  final List<String> _topics = const [
    'For You',
    'Resilience',
    'Mindfulness',
    'Anxiety',
    'Sleep',
    'Relationships',
    'Growth',
  ];

  final List<_FeedCardData> _cards = const [
    _FeedCardData(
      category: 'Cognitive Therapy',
      title: 'Understanding Attachment Styles',
      subtitle: 'How early bonds shape relationship patterns today.',
      readTime: '5 min read',
      accent: Color(0xFF1E56D9),
      imageUrl:
          'https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 220,
      personalized: true,
      estimatedHeight: 410,
    ),
    _FeedCardData(
      category: 'Mindfulness',
      title: '5 Breathing Techniques for Instant Calm',
      subtitle: 'Simple methods to regulate your nervous system.',
      readTime: '3 min read',
      accent: Color(0xFF0F8A85),
      imageUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 250,
      estimatedHeight: 430,
    ),
    _FeedCardData.quote(
      title:
          '"The curious paradox is that when I accept myself just as I am, then I can change."',
      subtitle: 'Carl Rogers',
      readTime: 'Daily Wisdom',
      estimatedHeight: 360,
    ),
    _FeedCardData(
      category: 'Self-Care',
      title: 'Why Journaling Works',
      subtitle: 'Expressive writing lowers stress and sharpens clarity.',
      readTime: '7 min read',
      accent: Color(0xFF8D46D8),
      imageUrl:
          'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 190,
      personalized: true,
      estimatedHeight: 390,
    ),
    _FeedCardData(
      category: 'Sleep Hygiene',
      title: 'Sleep Hygiene Basics',
      subtitle: 'Small environmental tweaks that improve sleep quality.',
      readTime: '4 min read',
      accent: Color(0xFF3D5DCC),
      imageUrl:
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 210,
      estimatedHeight: 398,
    ),
    _FeedCardData(
      category: 'Boundaries',
      title: 'How to Say No Without Guilt',
      subtitle:
          'Scripts and mindset shifts for protecting your energy with compassion.',
      readTime: '6 min read',
      accent: Color(0xFF1F7A73),
      imageUrl:
          'https://images.unsplash.com/photo-1516589091380-5d8e87df6999?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 230,
      estimatedHeight: 414,
    ),
    _FeedCardData(
      category: 'Resilience',
      title: 'Rebuilding Confidence After Setbacks',
      subtitle:
          'A steadier way to regain momentum when life interrupts your plans.',
      readTime: '5 min read',
      accent: Color(0xFF3157D5),
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 208,
      estimatedHeight: 396,
    ),
    _FeedCardData.quote(
      title:
          '"Healing is not becoming someone new. It is returning to who you were beneath survival."',
      subtitle: 'Therapii Wisdom',
      readTime: "Editor's Note",
      estimatedHeight: 334,
    ),
    _FeedCardData(
      category: 'Relationships',
      title: 'Rupture and Repair in Close Relationships',
      subtitle:
          'Conflict does not have to mean disconnection when repair is intentional.',
      readTime: '8 min read',
      accent: Color(0xFF8452D6),
      imageUrl:
          'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 214,
      personalized: true,
      estimatedHeight: 404,
    ),
    _FeedCardData(
      category: 'Anxiety',
      title: 'What to Do When Your Mind Won’t Slow Down',
      subtitle:
          'Grounding patterns for nights when overthinking keeps your body awake.',
      readTime: '4 min read',
      accent: Color(0xFFCC6A24),
      imageUrl:
          'https://images.unsplash.com/photo-1493836512294-502baa1986e2?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 224,
      estimatedHeight: 404,
    ),
  ];

  int _selectedTopicIndex = 0;
  int _visibleCardCount = _initialVisibleCardCount;
  bool _isRestoringDestination = true;
  double _leftRailWidth = _defaultPortalSidebarWidth;

  @override
  void initState() {
    super.initState();
    _restoreDestination();
  }

  Future<void> _restoreDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final destination =
        prefs.getString(_portalDestinationKey) ?? _portalDestinationHome;
    final sidebarWidth = _clampPortalSidebarWidth(
        prefs.getDouble(_portalSidebarWidthKey) ?? _defaultPortalSidebarWidth);

    if (!mounted) return;

    if (destination == _portalDestinationJournal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _JournalReflectionPage()),
        );
      });
      return;
    }

    if (destination == _portalDestinationFavorites) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _FavoritesPage()),
        );
      });
      return;
    }

    await prefs.setString(_portalDestinationKey, _portalDestinationHome);
    if (!mounted) return;
    setState(() {
      _leftRailWidth = sidebarWidth;
      _isRestoringDestination = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringDestination) {
      return const RememberAppPage(
        pageId: AppPageId.journalPortal,
        child: Scaffold(
          backgroundColor: Color(0xFFF4F6FB),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final showLeftRail = width >= 1100;
    final showRightRail = width >= 1480;
    final isAdmin =
        AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);

    final palette = _PortalPalette.of(context);

    return RememberAppPage(
      pageId: AppPageId.journalPortal,
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          child: Stack(
            children: [
              const _AmbientBackground(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLeftRail)
                    _LeftRail(
                      isAdmin: isAdmin,
                      width: _leftRailWidth,
                      activeItem: _PortalSidebarItem.home,
                      onHomeTap: () {},
                      onJournalTap: () {
                        _openJournal();
                      },
                      onFavoritesTap: () {
                        _openFavorites();
                      },
                      onSwitchSessionTap: () =>
                          _switchToTherapiiSession(context),
                      onResizeBy: _resizeSidebarBy,
                      onResizeEnd: _saveSidebarWidth,
                    ),
                  Expanded(
                    child: _FeedPane(
                      showCompactHeader: !showLeftRail,
                      topics: _topics,
                      selectedTopicIndex: _selectedTopicIndex,
                      onTopicSelected: (index) {
                        setState(() => _selectedTopicIndex = index);
                      },
                      cards: _visibleCards,
                      hasMoreArticles: _visibleCardCount < _cards.length,
                      onLoadMore: _loadMoreArticles,
                    ),
                  ),
                  if (showRightRail) const _RightRail(),
                ],
              ),
              if (!showLeftRail) ...[
                Positioned(
                  top: 12,
                  left: 12,
                  child: SafeArea(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Image.asset(
                          'assets/images/Therapii_image.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: SafeArea(
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          await FirebaseAuthManager().signOut();
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LandingPage()),
                            (route) => false,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.panelStrong,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out'),
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

  Future<void> _openJournal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationJournal);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _JournalReflectionPage()),
    );
  }

  Future<void> _openFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationFavorites);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _FavoritesPage()),
    );
  }

  List<_FeedCardData> get _visibleCards {
    final upperBound = _visibleCardCount.clamp(0, _cards.length) as int;
    return _cards.take(upperBound).toList(growable: false);
  }

  void _loadMoreArticles() {
    if (_visibleCardCount >= _cards.length) return;
    setState(() {
      _visibleCardCount = (_visibleCardCount + _loadMoreBatchSize)
          .clamp(0, _cards.length) as int;
    });
  }

  void _resizeSidebarBy(double delta) {
    setState(() {
      _leftRailWidth = _clampPortalSidebarWidth(_leftRailWidth + delta);
    });
  }

  void _saveSidebarWidth() {
    _persistPortalSidebarWidth(_leftRailWidth);
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: -130,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.ambientPrimary,
              ),
            ),
          ),
          Positioned(
            right: 120,
            top: 36,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.ambientSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftRail extends StatelessWidget {
  final bool isAdmin;
  final double width;
  final _PortalSidebarItem activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onJournalTap;
  final VoidCallback onFavoritesTap;
  final Future<void> Function() onSwitchSessionTap;
  final ValueChanged<double> onResizeBy;
  final VoidCallback onResizeEnd;
  const _LeftRail({
    required this.isAdmin,
    required this.width,
    required this.activeItem,
    required this.onHomeTap,
    required this.onJournalTap,
    required this.onFavoritesTap,
    required this.onSwitchSessionTap,
    required this.onResizeBy,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.railTop,
              border: Border(right: BorderSide(color: palette.railBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandCard(isAdmin: isAdmin),
                const SizedBox(height: 24),
                _NavTile(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  active: activeItem == _PortalSidebarItem.home,
                  onTap: onHomeTap,
                ),
                _NavTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Journal',
                  active: activeItem == _PortalSidebarItem.journal,
                  onTap: onJournalTap,
                ),
                _NavTile(
                  icon: Icons.bookmark_outline_rounded,
                  label: 'Favorites',
                  active: activeItem == _PortalSidebarItem.favorites,
                  onTap: onFavoritesTap,
                ),
                const Spacer(),
                _SessionSwitchCard(onTap: onSwitchSessionTap),
                const SizedBox(height: 14),
                const _ThemeModeButton(),
                const SizedBox(height: 10),
                const _LogoutButton(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  onResizeBy(details.delta.dx);
                },
                onHorizontalDragEnd: (_) {
                  onResizeEnd();
                },
                child: SizedBox(
                  width: 18,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 4,
                      height: 72,
                      decoration: BoxDecoration(
                        color: palette.handle,
                        borderRadius: BorderRadius.circular(999),
                      ),
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

class _BrandCard extends StatelessWidget {
  final bool isAdmin;
  const _BrandCard({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: Image.asset(
                'assets/images/Therapii_image.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Therapii Portal',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      isAdmin ? 'Admin Account' : 'Free Member',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1754CF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: const Color(0xFF1754CF).withOpacity(0.28)),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1754CF),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _PortalPalette.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: themeModeController.toggleLightDark,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.controlBorder),
          foregroundColor: palette.controlForeground,
          backgroundColor: palette.controlBackground
              .withValues(alpha: palette.isDark ? 1 : 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 18,
        ),
        label: Text(isDark ? 'Light Mode' : 'Dark Mode'),
      ),
    );
  }
}

class _SessionSwitchCard extends StatefulWidget {
  final Future<void> Function() onTap;

  const _SessionSwitchCard({required this.onTap});

  @override
  State<_SessionSwitchCard> createState() => _SessionSwitchCardState();
}

class _SessionSwitchCardState extends State<_SessionSwitchCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);
    final isElevated = _hovered || _pressed || _loading;
    final cardColor =
        palette.isDark ? const Color(0xFF13213A) : const Color(0xFFF0F5FF);
    final borderColor =
        palette.isDark ? const Color(0xFF2A4269) : const Color(0xFFCFE0FF);
    final iconBackground =
        palette.isDark ? const Color(0xFF1E3A6B) : const Color(0xFFDCE8FF);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.15),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(
                  alpha: isElevated
                      ? (palette.isDark ? 0.42 : 0.14)
                      : (palette.isDark ? 0.28 : 0.08),
                ),
                blurRadius: isElevated ? 24 : 14,
                offset: Offset(0, isElevated ? 14 : 8),
                spreadRadius: isElevated ? 0 : -2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(22),
              splashColor: const Color(0x221754CF),
              highlightColor: Colors.transparent,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.panelStrong
                            .withValues(alpha: palette.isDark ? 0.2 : 0.7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: palette.border
                                .withValues(alpha: palette.isDark ? 0.8 : 1)),
                      ),
                      child: Text(
                        'THERAPII SESSION',
                        style: TextStyle(
                          color: palette.navActiveText,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFF1754CF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Switch to Therapii',
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Return to your live support space, messages, and guided session tools.',
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.42,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: palette.panelStrong
                            .withValues(alpha: palette.isDark ? 0.22 : 0.76),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: palette.border
                                .withValues(alpha: palette.isDark ? 0.85 : 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _loading
                                  ? 'Opening workspace...'
                                  : 'Open session workspace',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _loading
                                ? SizedBox(
                                    key: const ValueKey('loading'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          palette.navActiveText),
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_forward_rounded,
                                    key: const ValueKey('arrow'),
                                    color: palette.navActiveText,
                                    size: 18,
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
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            await FirebaseAuthManager().signOut();
          } catch (_) {}
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LandingPage()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.controlBorder),
          foregroundColor: palette.controlForeground,
          backgroundColor: palette.controlBackground,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Log Out'),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: active ? palette.navActiveBackground : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          color: active ? palette.navActiveText : palette.navInactiveIcon,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            color: active ? palette.navActiveText : palette.navInactiveText,
          ),
        ),
      ),
    );
  }
}

class _JournalReflectionPage extends StatefulWidget {
  const _JournalReflectionPage();

  @override
  State<_JournalReflectionPage> createState() => _JournalReflectionPageState();
}

class _JournalReflectionPageState extends State<_JournalReflectionPage> {
  final TextEditingController _reflectionController = TextEditingController();
  final AiConversationService _aiService = AiConversationService();
  bool _isArchiving = false;
  double _leftRailWidth = _defaultPortalSidebarWidth;

  @override
  void initState() {
    super.initState();
    _persistDestination();
    _restoreSidebarWidth();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _persistDestination() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationJournal);
  }

  Future<void> _restoreSidebarWidth() async {
    final width = await _loadPortalSidebarWidth();
    if (!mounted) return;
    setState(() {
      _leftRailWidth = width;
    });
  }

  String _firstName() {
    final user = FirebaseAuthManager().currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }

    final email = user?.email?.trim() ?? '';
    if (email.contains('@')) {
      final localPart = email.split('@').first;
      if (localPart.isNotEmpty) {
        return localPart[0].toUpperCase() + localPart.substring(1);
      }
    }

    return 'Sarah';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationHome);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const JournalPortalPage()),
    );
  }

  Future<void> _openFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationFavorites);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _FavoritesPage()),
    );
  }

  Future<void> _archiveReflection() async {
    final reflection = _reflectionController.text.trim();
    if (reflection.isEmpty || _isArchiving) return;

    final currentUser = FirebaseAuthManager().currentUser;
    final patientId = currentUser?.uid;
    if (patientId == null || patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to archive this reflection right now. Please sign in again.'),
        ),
      );
      return;
    }

    setState(() => _isArchiving = true);
    try {
      await _aiService.saveJournalReflection(
        patientId: patientId,
        summary: reflection,
      );
      if (!mounted) return;
      _reflectionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection archived to your wisdom feed.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to archive reflection right now. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showLeftRail = width >= 1200;
    final isAdmin =
        AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);

    final palette = _PortalPalette.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLeftRail)
              _LeftRail(
                isAdmin: isAdmin,
                width: _leftRailWidth,
                activeItem: _PortalSidebarItem.journal,
                onHomeTap: () {
                  _openHome();
                },
                onJournalTap: () {},
                onFavoritesTap: () {
                  _openFavorites();
                },
                onSwitchSessionTap: () => _switchToTherapiiSession(context),
                onResizeBy: _resizeSidebarBy,
                onResizeEnd: _saveSidebarWidth,
              ),
            Expanded(
              child: _JournalReflectionPane(
                showCompactHeader: !showLeftRail,
                greeting: '${_greeting()}, ${_firstName()}.',
                controller: _reflectionController,
                isArchiving: _isArchiving,
                onArchive: () {
                  _archiveReflection();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resizeSidebarBy(double delta) {
    setState(() {
      _leftRailWidth = _clampPortalSidebarWidth(_leftRailWidth + delta);
    });
  }

  void _saveSidebarWidth() {
    _persistPortalSidebarWidth(_leftRailWidth);
  }
}

class _FavoritesPage extends StatefulWidget {
  const _FavoritesPage();

  @override
  State<_FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<_FavoritesPage> {
  double _leftRailWidth = _defaultPortalSidebarWidth;

  @override
  void initState() {
    super.initState();
    _persistDestination();
    _restoreSidebarWidth();
  }

  Future<void> _persistDestination() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationFavorites);
  }

  Future<void> _restoreSidebarWidth() async {
    final width = await _loadPortalSidebarWidth();
    if (!mounted) return;
    setState(() {
      _leftRailWidth = width;
    });
  }

  Future<void> _openHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationHome);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const JournalPortalPage()),
    );
  }

  Future<void> _openJournal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portalDestinationKey, _portalDestinationJournal);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _JournalReflectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showLeftRail = width >= 1100;
    final isAdmin =
        AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);

    return Scaffold(
      backgroundColor: _PortalPalette.of(context).scaffold,
      body: SafeArea(
        child: Stack(
          children: [
            const _AmbientBackground(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLeftRail)
                  _LeftRail(
                    isAdmin: isAdmin,
                    width: _leftRailWidth,
                    activeItem: _PortalSidebarItem.favorites,
                    onHomeTap: () {
                      _openHome();
                    },
                    onJournalTap: () {
                      _openJournal();
                    },
                    onFavoritesTap: () {},
                    onSwitchSessionTap: () => _switchToTherapiiSession(context),
                    onResizeBy: _resizeSidebarBy,
                    onResizeEnd: _saveSidebarWidth,
                  ),
                Expanded(
                  child: _FavoritesPane(showCompactHeader: !showLeftRail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resizeSidebarBy(double delta) {
    setState(() {
      _leftRailWidth = _clampPortalSidebarWidth(_leftRailWidth + delta);
    });
  }

  void _saveSidebarWidth() {
    _persistPortalSidebarWidth(_leftRailWidth);
  }
}

class _FavoritesPane extends StatelessWidget {
  final bool showCompactHeader;

  const _FavoritesPane({required this.showCompactHeader});

  Query<Map<String, dynamic>>? get _favoritesQuery {
    final userId = FirebaseAuthManager().currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorite_journal_articles')
        .orderBy('saved_at', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    final query = _favoritesQuery;
    final horizontalPadding = showCompactHeader ? 16.0 : 30.0;
    final palette = _PortalPalette.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding,
              showCompactHeader ? 12 : 24, horizontalPadding, 24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCompactHeader) ...[
                      const _CompactPortalHeader(),
                      const SizedBox(height: 22),
                    ],
                    Text(
                      'Favorites',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 38,
                        height: 1.02,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Everything you save from the journal feed appears here automatically.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (query == null)
                      const _FavoriteStateCard(
                        icon: Icons.person_off_rounded,
                        title: 'Sign in to view favorites',
                        message:
                            'Your saved journal articles are stored in Firebase and tied to your account.',
                      )
                    else
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: query.snapshots(),
                        builder: (context, snapshot) {
                          final items = snapshot.hasData
                              ? snapshot.data!.docs
                                  .map(_FavoriteArticleData.fromDoc)
                                  .toList(growable: false)
                              : const <_FavoriteArticleData>[];

                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              items.isEmpty) {
                            return const _FavoriteStateCard(
                              icon: Icons.hourglass_top_rounded,
                              title: 'Loading favorites',
                              message:
                                  'Saved journal articles from Firebase are being prepared.',
                            );
                          }

                          if (snapshot.hasError) {
                            return const _FavoriteStateCard(
                              icon: Icons.cloud_off_rounded,
                              title: 'Unable to load favorites',
                              message:
                                  'We could not read your saved journal articles from Firebase right now.',
                            );
                          }

                          if (items.isEmpty) {
                            return const _FavoriteStateCard(
                              icon: Icons.bookmark_outline_rounded,
                              title: 'No favorites yet',
                              message:
                                  'Tap the save icon on any journal article and it will appear here.',
                            );
                          }

                          return _FavoriteGrid(items: items);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteGrid extends StatelessWidget {
  final List<_FavoriteArticleData> items;

  const _FavoriteGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 820;
        if (!useTwoColumns) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _FavoriteArticleCard(item: items[i]),
                if (i < items.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        final left = <_FavoriteArticleData>[];
        final right = <_FavoriteArticleData>[];
        for (var i = 0; i < items.length; i++) {
          (i.isEven ? left : right).add(items[i]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _FavoriteColumn(items: left)),
            const SizedBox(width: 16),
            Expanded(child: _FavoriteColumn(items: right)),
          ],
        );
      },
    );
  }
}

class _FavoriteColumn extends StatelessWidget {
  final List<_FavoriteArticleData> items;

  const _FavoriteColumn({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _FavoriteArticleCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FavoriteArticleCard extends StatelessWidget {
  final _FavoriteArticleData item;

  const _FavoriteArticleCard({required this.item});

  void _openArticle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalArticlePage(
          title: item.title,
          category: item.category,
          subtitle: item.subtitle,
          readTime: item.readTime,
          imageUrl: item.imageUrl,
          authorName: item.authorName,
          authorRole: item.authorRole,
          publishedDate: item.publishedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Material(
      color: palette.panelStrong.withOpacity(palette.isDark ? 1 : 0.95),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openArticle(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: palette.panelSoft),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1754CF),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (item.savedLabel != null)
                          Text(
                            item.savedLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: palette.divider),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          item.readTime,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.bookmark_rounded,
                            size: 20, color: Color(0xFF1754CF)),
                      ],
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

class _FavoriteStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _FavoriteStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: palette.panelStrong.withOpacity(palette.isDark ? 1 : 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.textMuted, size: 20),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalReflectionPane extends StatefulWidget {
  final bool showCompactHeader;
  final String greeting;
  final TextEditingController controller;
  final bool isArchiving;
  final VoidCallback onArchive;

  const _JournalReflectionPane({
    required this.showCompactHeader,
    required this.greeting,
    required this.controller,
    required this.isArchiving,
    required this.onArchive,
  });

  @override
  State<_JournalReflectionPane> createState() => _JournalReflectionPaneState();
}

class _JournalReflectionPaneState extends State<_JournalReflectionPane> {
  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant _JournalReflectionPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      color: palette.scaffold,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSplitLayout = constraints.maxWidth >= 1120;

          if (showSplitLayout) {
            return Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.showCompactHeader ? 20 : 56,
                      widget.showCompactHeader ? 18 : 40,
                      48,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showCompactHeader) ...[
                          const _CompactPortalHeader(),
                          const SizedBox(height: 26),
                        ],
                        _JournalIntro(greeting: widget.greeting),
                        const SizedBox(height: 28),
                        Expanded(
                          child:
                              _ReflectionEditor(controller: widget.controller),
                        ),
                        const SizedBox(height: 24),
                        _ReflectionActions(
                          enabled: _hasText,
                          isArchiving: widget.isArchiving,
                          onArchive: widget.onArchive,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: palette.divider,
                ),
                SizedBox(
                  width: 430,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(34, 36, 32, 22),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: const _WisdomFeedColumn(),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              widget.showCompactHeader ? 16 : 24,
              widget.showCompactHeader ? 16 : 24,
              widget.showCompactHeader ? 16 : 24,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showCompactHeader) ...[
                  const _CompactPortalHeader(),
                  const SizedBox(height: 24),
                ],
                _JournalIntro(greeting: widget.greeting),
                const SizedBox(height: 24),
                SizedBox(
                  height: 480,
                  child: _ReflectionEditor(controller: widget.controller),
                ),
                const SizedBox(height: 22),
                _ReflectionActions(
                  enabled: _hasText,
                  isArchiving: widget.isArchiving,
                  onArchive: widget.onArchive,
                ),
                const SizedBox(height: 30),
                const _WisdomFeedColumn(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompactPortalHeader extends StatelessWidget {
  const _CompactPortalHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: palette.controlBackground,
            foregroundColor: palette.controlForeground,
          ),
          tooltip: 'Back',
        ),
        const SizedBox(width: 10),
        Text(
          'Therapii Portal',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _JournalIntro extends StatelessWidget {
  final String greeting;
  const _JournalIntro({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final greetingSize = width < 700 ? 42.0 : 64.0;
    final promptSize = width < 700 ? 22.0 : 28.0;
    final palette = _PortalPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            color: palette.textPrimary,
            fontFamily: 'Satoshi',
            fontSize: greetingSize,
            height: 0.92,
            fontWeight: FontWeight.w700,
            letterSpacing: -2.4,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '"What are you carrying with you tonight?"',
          style: TextStyle(
            color: palette.textMuted,
            fontFamily: 'Satoshi',
            fontStyle: FontStyle.italic,
            fontSize: promptSize,
            fontWeight: FontWeight.w500,
            height: 1.24,
          ),
        ),
      ],
    );
  }
}

class _ReflectionEditor extends StatelessWidget {
  final TextEditingController controller;
  const _ReflectionEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final palette = _PortalPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
        child: Stack(
          children: [
            TextField(
              controller: controller,
              expands: true,
              minLines: null,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 21,
                height: 1.65,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!hasText)
              IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Begin typing to release...',
                    style: TextStyle(
                      color: palette.textMuted.withValues(alpha: 0.55),
                      fontFamily: 'Satoshi',
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReflectionActions extends StatelessWidget {
  final bool enabled;
  final bool isArchiving;
  final VoidCallback onArchive;

  const _ReflectionActions({
    required this.enabled,
    required this.isArchiving,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 760;
    final palette = _PortalPalette.of(context);

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _ActionCircleButton(icon: Icons.mic_none_rounded),
        SizedBox(width: 16),
        _ActionCircleButton(icon: Icons.image_outlined),
      ],
    );

    final archiveButton = FilledButton(
      onPressed: enabled && !isArchiving ? onArchive : null,
      style: FilledButton.styleFrom(
        backgroundColor: palette.panelStrong,
        disabledBackgroundColor: palette.controlBorder,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isArchiving ? 'Archiving...' : 'Archive Reflection'),
          const SizedBox(width: 10),
          if (isArchiving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: Colors.white),
            )
          else
            const Icon(Icons.north_east_rounded, size: 18),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          actionButtons,
          const SizedBox(height: 18),
          archiveButton,
        ],
      );
    }

    return Row(
      children: [
        actionButtons,
        const Spacer(),
        archiveButton,
      ],
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  const _ActionCircleButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: palette.controlBackground,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: palette.textMuted, size: 28),
    );
  }
}

class _WisdomFeedColumn extends StatefulWidget {
  const _WisdomFeedColumn();

  @override
  State<_WisdomFeedColumn> createState() => _WisdomFeedColumnState();
}

class _WisdomFeedColumnState extends State<_WisdomFeedColumn> {
  static final AiConversationService _aiService = AiConversationService();
  final Set<String> _deletingIds = <String>{};

  Future<void> _deleteItem(_WisdomFeedItemData item) async {
    final currentUser = FirebaseAuthManager().currentUser;
    final patientId = currentUser?.uid;
    if (patientId == null ||
        patientId.isEmpty ||
        _deletingIds.contains(item.id)) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete wisdom note?'),
              content: const Text(
                'This note will be permanently removed from your wisdom feed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() {
      _deletingIds.add(item.id);
    });

    try {
      await _aiService.deletePatientSummary(
        patientId: patientId,
        summaryId: item.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wisdom note deleted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to delete this wisdom note right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthManager().currentUser;
    final patientId = currentUser?.uid;

    if (patientId == null || patientId.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WisdomFeedHeader(),
          SizedBox(height: 24),
          _WisdomFeedStateCard(
            icon: Icons.person_off_rounded,
            title: 'Unable to identify your account',
            message: 'Sign in again to load your wisdom notes from Firestore.',
          ),
          SizedBox(height: 28),
          _AnalysisCard(),
        ],
      );
    }

    return StreamBuilder<List<AiConversationSummary>>(
      stream:
          _aiService.streamPatientSummaries(patientId: patientId, limit: 20),
      builder: (context, snapshot) {
        final items = snapshot.hasData
            ? snapshot.data!
                .map(_WisdomFeedItemData.fromSummary)
                .toList(growable: true)
            : <_WisdomFeedItemData>[];
        items.sort((a, b) => b.sortDate.compareTo(a.sortDate));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WisdomFeedHeader(),
            const SizedBox(height: 24),
            if (snapshot.connectionState == ConnectionState.waiting &&
                items.isEmpty)
              const _WisdomFeedStateCard(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading wisdom notes',
                message:
                    'Saved notes from Firestore will appear here as soon as they are available.',
              )
            else if (snapshot.hasError)
              const _WisdomFeedStateCard(
                icon: Icons.cloud_off_rounded,
                title: 'Unable to load wisdom notes',
                message:
                    'We could not load your Firestore-backed wisdom notes right now.',
              )
            else if (items.isEmpty)
              const _WisdomFeedStateCard(
                icon: Icons.auto_awesome_motion_rounded,
                title: 'No wisdom notes yet',
                message:
                    'Your saved wisdom notes will appear here once summaries are written to Firestore.',
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                _WisdomFeedCard(
                  item: items[i],
                  isDeleting: _deletingIds.contains(items[i].id),
                  onDelete: () {
                    _deleteItem(items[i]);
                  },
                ),
                if (i < items.length - 1) const SizedBox(height: 26),
              ],
            const SizedBox(height: 28),
            const _AnalysisCard(),
          ],
        );
      },
    );
  }
}

class _WisdomFeedHeader extends StatelessWidget {
  const _WisdomFeedHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'WISDOM FEED',
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 3,
            ),
          ),
        ),
        Text(
          'UPDATED',
          style: TextStyle(
            color: palette.textMuted.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        SizedBox(width: 8),
        const Icon(Icons.circle, color: Color(0xFF8BB5FF), size: 10),
      ],
    );
  }
}

class _WisdomFeedStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _WisdomFeedStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.textMuted, size: 20),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WisdomFeedCard extends StatelessWidget {
  final _WisdomFeedItemData item;
  final bool isDeleting;
  final VoidCallback onDelete;
  const _WisdomFeedCard({
    required this.item,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.timestamp.toUpperCase(),
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: item.accent, size: 20),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: isDeleting ? null : onDelete,
                    tooltip: 'Delete note',
                    style: IconButton.styleFrom(
                      backgroundColor: item.accent
                          .withValues(alpha: palette.isDark ? 0.16 : 0.1),
                      foregroundColor: item.accent,
                      disabledBackgroundColor: palette.controlBorder,
                      disabledForegroundColor: palette.textMuted,
                      minimumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                    ),
                    icon: isDeleting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.textMuted,
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.quote,
            style: TextStyle(
              color: palette.textSecondary,
              fontFamily: 'Satoshi',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: 20,
              height: 1.65,
            ),
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final tag in item.tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: item.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: item.accent.withOpacity(0.12)),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: TextStyle(
                        color: item.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard();

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.analysisIconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.insights_rounded, color: Color(0xFF5C8EFF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Analysis',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '7-day emotional report',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFC0C8D4), size: 28),
        ],
      ),
    );
  }
}

class _WisdomFeedItemData {
  final String id;
  final String timestamp;
  final String quote;
  final List<String> tags;
  final Color accent;
  final IconData icon;
  final DateTime sortDate;

  const _WisdomFeedItemData({
    required this.id,
    required this.timestamp,
    required this.quote,
    required this.tags,
    required this.accent,
    required this.icon,
    required this.sortDate,
  });

  factory _WisdomFeedItemData.fromSummary(AiConversationSummary summary) {
    final tags = _extractTags(summary.summary);
    return _WisdomFeedItemData(
      id: summary.id,
      timestamp: _formatTimestamp(summary.createdAt),
      quote: _normalizeQuote(summary.summary),
      tags: tags,
      accent: _accentForSummary(summary.summary),
      icon: _iconForSummary(summary.summary),
      sortDate: summary.createdAt,
    );
  }

  static String _normalizeQuote(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '"No summary available."';
    return trimmed.startsWith('"') ? trimmed : '"$trimmed"';
  }

  static String _formatTimestamp(DateTime dateTime) {
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthLabels[dateTime.month - 1];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final meridiem = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dateTime.day} • $hour:$minute $meridiem';
  }

  static List<String> _extractTags(String summary) {
    final normalized = summary.toLowerCase();
    final tags = <String>[];
    final keywordMap = <String, String>{
      'ground': 'Grounding',
      'sleep': 'Sleep',
      'anx': 'Anxiety',
      'work': 'Work Harmony',
      'relationship': 'Relationships',
      'regulat': 'Self-Regulation',
      'growth': 'Growth',
      'patience': 'Patience',
      'mindful': 'Mindfulness',
      'calm': 'Calm',
    };

    for (final entry in keywordMap.entries) {
      if (normalized.contains(entry.key)) {
        tags.add(entry.value);
      }
      if (tags.length == 2) break;
    }

    return tags;
  }

  static Color _accentForSummary(String summary) {
    final normalized = summary.toLowerCase();
    if (normalized.contains('ground')) return const Color(0xFFB17CFF);
    if (normalized.contains('growth') || normalized.contains('patience')) {
      return const Color(0xFF47C98A);
    }
    return const Color(0xFF6EA8FF);
  }

  static IconData _iconForSummary(String summary) {
    final normalized = summary.toLowerCase();
    if (normalized.contains('ground')) return Icons.psychology_alt_rounded;
    if (normalized.contains('growth') || normalized.contains('patience'))
      return Icons.spa_rounded;
    return Icons.auto_awesome_rounded;
  }
}

class _FeedPane extends StatelessWidget {
  final bool showCompactHeader;
  final List<String> topics;
  final int selectedTopicIndex;
  final ValueChanged<int> onTopicSelected;
  final List<_FeedCardData> cards;
  final bool hasMoreArticles;
  final VoidCallback onLoadMore;

  const _FeedPane({
    required this.showCompactHeader,
    required this.topics,
    required this.selectedTopicIndex,
    required this.onTopicSelected,
    required this.cards,
    required this.hasMoreArticles,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = showCompactHeader ? 16.0 : 30.0;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final titleSize = mediaWidth < 600 ? 28.0 : 38.0;
    final palette = _PortalPalette.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding,
              showCompactHeader ? 12 : 24, horizontalPadding, 0),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCompactHeader) ...[
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: palette.controlBackground,
                              foregroundColor: palette.controlForeground,
                            ),
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Therapii Portal',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                    Text(
                      'Therapeutic Feed',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: titleSize,
                        height: 1.02,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Curated insights for your mental wellbeing',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _FeaturedHeroCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(
            minHeight: 88,
            maxHeight: 88,
            child: Container(
              color: palette.scaffold.withOpacity(palette.isDark ? 0.98 : 0.97),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    return _TopicPill(
                      label: topics[index],
                      selected: selectedTopicIndex == index,
                      onTap: () => onTopicSelected(index),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 20),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: _MasonryFeed(cards: cards),
              ),
            ),
          ),
        ),
        if (hasMoreArticles)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Center(
                child: OutlinedButton(
                  onPressed: onLoadMore,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: palette.loadMoreBackground
                        .withOpacity(palette.isDark ? 1 : 0.92),
                    foregroundColor: palette.textSecondary,
                    side: BorderSide(color: palette.border),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                  ),
                  child: const Text('Load More Articles'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedHeroCard extends StatelessWidget {
  const _FeaturedHeroCard();

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final titleSize = mediaWidth < 640 ? 28.0 : 44.0;
    const radius = BorderRadius.all(Radius.circular(30));

    return SizedBox(
      height: mediaWidth < 700 ? 320 : 430,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1491975474562-1f4e30bc9468?auto=format&fit=crop&w=1800&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF0D1F44),
                  ),
                );
              },
            ),
            Container(
              decoration: const BoxDecoration(color: Color(0x8A000000)),
            ),
            Positioned(
              right: -20,
              top: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x20FFFFFF),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 15, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'FEATURED INSIGHT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.schedule_rounded,
                          size: 16, color: Color(0xE6FFFFFF)),
                      const SizedBox(width: 4),
                      const Text(
                        '10 min read',
                        style: TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Art of Letting Go: How to Release Past Burdens',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.06,
                      fontSize: titleSize,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Holding onto the past can weigh heavily on the present. '
                    'Learn practical frameworks to process, accept, and move forward with grace.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.42,
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

class _TopicPill extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopicPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TopicPill> createState() => _TopicPillState();
}

class _TopicPillState extends State<_TopicPill> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);
    final selected = widget.selected;
    final bgColor = selected
        ? const Color(0xFF2E67DD)
        : (palette.isDark ? palette.panelStrong : Colors.white)
            .withOpacity(_hovered ? 1 : 0.96);
    final borderColor = selected
        ? const Color(0xAAFFFFFF)
        : (_hovered ? palette.controlBorder : palette.border);
    final shadow = selected
        ? <BoxShadow>[
            const BoxShadow(
              color: Color(0x441754CF),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
            const BoxShadow(
              color: Color(0x261754CF),
              blurRadius: 2,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(palette.isDark
                  ? (_hovered ? 0.24 : 0.18)
                  : (_hovered ? 0.08 : 0.05)),
              blurRadius: _hovered ? 14 : 10,
              offset: Offset(0, _hovered ? 6 : 4),
            ),
            if (!palette.isDark)
              const BoxShadow(
                color: Color(0xCCFFFFFF),
                blurRadius: 0,
                spreadRadius: 1,
                offset: Offset(0, 1),
              ),
          ];
    final scale = _pressed ? 0.98 : (_hovered ? 1.01 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: selected ? 1.2 : 1.0),
            boxShadow: shadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(999),
              splashColor: selected
                  ? Colors.white.withOpacity(0.18)
                  : const Color(0x221754CF),
              highlightColor: Colors.transparent,
              onHighlightChanged: (down) => setState(() => _pressed = down),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: selected
                          ? Container(
                              key: const ValueKey('selected-dot'),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.7)),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('empty-dot'), width: 0, height: 0),
                    ),
                    if (selected) const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: selected ? Colors.white : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MasonryFeed extends StatelessWidget {
  final List<_FeedCardData> cards;
  const _MasonryFeed({required this.cards});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final twoColumns = width >= 900;

    if (!twoColumns) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            _FeedArticleCard(data: cards[i]),
            if (i < cards.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    final leftColumn = <_FeedCardData>[];
    final rightColumn = <_FeedCardData>[];
    var leftHeight = 0;
    var rightHeight = 0;

    for (final card in cards) {
      if (leftHeight <= rightHeight) {
        leftColumn.add(card);
        leftHeight += card.estimatedHeight;
      } else {
        rightColumn.add(card);
        rightHeight += card.estimatedHeight;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _FeedColumn(cards: leftColumn)),
        const SizedBox(width: 16),
        Expanded(child: _FeedColumn(cards: rightColumn)),
      ],
    );
  }
}

class _FeedColumn extends StatelessWidget {
  final List<_FeedCardData> cards;
  const _FeedColumn({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          _FeedArticleCard(data: cards[i]),
          if (i < cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FeedArticleCard extends StatefulWidget {
  final _FeedCardData data;
  const _FeedArticleCard({required this.data});

  @override
  State<_FeedArticleCard> createState() => _FeedArticleCardState();
}

class _FeedArticleCardState extends State<_FeedArticleCard> {
  bool _isFavorite = false;
  bool _isSavingFavorite = false;

  static const _fallbackImageUrl =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80';
  static const _authorName = 'Dr. Eleanor Vance';
  static const _authorRole = 'Clinical Psychologist';
  static const _publishedDate = 'Oct 14, 2023';

  @override
  void initState() {
    super.initState();
    if (!widget.data.isQuoteCard) {
      _loadFavoriteState();
    }
  }

  String get _articleId {
    final normalized =
        widget.data.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String get _imageUrl => widget.data.imageUrl ?? _fallbackImageUrl;

  DocumentReference<Map<String, dynamic>>? get _favoriteDoc {
    final userId = FirebaseAuthManager().currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorite_journal_articles')
        .doc(_articleId);
  }

  Future<void> _loadFavoriteState() async {
    final doc = _favoriteDoc;
    if (doc == null) return;
    final snapshot = await doc.get();
    if (!mounted) return;
    setState(() => _isFavorite = snapshot.exists);
  }

  Future<void> _toggleFavorite() async {
    final doc = _favoriteDoc;
    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save favorites.')),
      );
      return;
    }
    if (_isSavingFavorite) return;

    setState(() => _isSavingFavorite = true);
    try {
      if (_isFavorite) {
        await doc.delete();
      } else {
        await doc.set({
          'title': widget.data.title,
          'category': widget.data.category,
          'subtitle': widget.data.subtitle,
          'read_time': widget.data.readTime,
          'image_url': _imageUrl,
          'author_name': _authorName,
          'author_role': _authorRole,
          'published_date': _publishedDate,
          'saved_at': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'Saved to favorites.' : 'Removed from favorites.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorites right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingFavorite = false);
      }
    }
  }

  void _openArticle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalArticlePage(
          title: widget.data.title,
          category: widget.data.category,
          subtitle: widget.data.subtitle,
          readTime: widget.data.readTime,
          imageUrl: _imageUrl,
          authorName: _authorName,
          authorRole: _authorRole,
          publishedDate: _publishedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isQuoteCard) {
      return _QuoteCard(data: widget.data);
    }

    final palette = _PortalPalette.of(context);

    return Material(
      color: palette.panelStrong.withOpacity(palette.isDark ? 1 : 0.95),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _openArticle,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.data.imageUrl != null) ...[
                SizedBox(
                  height: widget.data.imageHeight,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.data.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: palette.panelSoft),
                        ),
                        if (widget.data.personalized)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: palette.panelStrong.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 13, color: widget.data.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Personalized',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: widget.data.accent,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.data.accent,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: palette.divider),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          widget.data.readTime,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isSavingFavorite ? null : _toggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 20,
                              color: _isFavorite
                                  ? const Color(0xFF1754CF)
                                  : palette.textMuted,
                            ),
                          ),
                        ),
                      ],
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

class _QuoteCard extends StatelessWidget {
  final _FeedCardData data;
  const _QuoteCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        color:
            palette.isDark ? const Color(0xFF142033) : const Color(0xFFEAF0FF),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: Color(0xFF1D56D4), size: 34),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              height: 1.24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '- ${data.subtitle}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: palette.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                data.readTime,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.share_rounded, size: 20, color: palette.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _RightRail extends StatelessWidget {
  const _RightRail();

  Query<Map<String, dynamic>>? get _favoritesQuery {
    final userId = FirebaseAuthManager().currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorite_journal_articles')
        .orderBy('saved_at', descending: true)
        .limit(3);
  }

  @override
  Widget build(BuildContext context) {
    final query = _favoritesQuery;
    final palette = _PortalPalette.of(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(left: BorderSide(color: palette.border)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.panelStrong,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child:
                  const _WeeklyProgressWidget(progress: 0.75, minutesRead: 45),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Favorites',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                        _portalDestinationKey, _portalDestinationFavorites);
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const _FavoritesPage()),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF1754CF),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (query == null)
              const _MiniStateTile(
                title: 'Sign in to sync favorites',
                subtitle: 'Saved journal articles will appear here.',
              )
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  final items = snapshot.hasData
                      ? snapshot.data!.docs
                          .map(_FavoriteArticleData.fromDoc)
                          .toList(growable: false)
                      : const <_FavoriteArticleData>[];

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      items.isEmpty) {
                    return const _MiniStateTile(
                      title: 'Loading favorites',
                      subtitle: 'Fetching your saved articles.',
                    );
                  }

                  if (snapshot.hasError) {
                    return const _MiniStateTile(
                      title: 'Favorites unavailable',
                      subtitle: 'We could not load saved articles right now.',
                    );
                  }

                  if (items.isEmpty) {
                    return const _MiniStateTile(
                      title: 'Nothing saved yet',
                      subtitle:
                          'Use the save icon on any article to pin it here.',
                    );
                  }

                  return Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        _SavedItemTile(item: items[i]),
                        if (i < items.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: palette.isDark
                    ? const Color(0x331754CF)
                    : const Color(0x261754CF),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock audio guided meditations for deeper focus.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.panelStrong,
                      foregroundColor: const Color(0xFF1754CF),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: const Text('Start Trial'),
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

class _WeeklyProgressWidget extends StatelessWidget {
  final double progress;
  final int minutesRead;
  const _WeeklyProgressWidget(
      {required this.progress, required this.minutesRead});

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    final palette = _PortalPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Progress',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 122,
            height: 122,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 122,
                  height: 122,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 11,
                    strokeCap: StrokeCap.round,
                    backgroundColor: palette.controlBorder,
                    color: const Color(0xFF1754CF),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.panelStrong,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const Text(
                        'GOAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7B8498),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '$minutesRead mins read this week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedItemTile extends StatelessWidget {
  final _FavoriteArticleData item;
  const _SavedItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Material(
      color: palette.panelStrong,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JournalArticlePage(
                title: item.title,
                category: item.category,
                subtitle: item.subtitle,
                readTime: item.readTime,
                imageUrl: item.imageUrl,
                authorName: item.authorName,
                authorRole: item.authorRole,
                publishedDate: item.publishedDate,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: palette.panelSoft),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.readTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
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

class _MiniStateTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniStateTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PortalPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _PinnedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _FeedCardData {
  final String category;
  final String title;
  final String subtitle;
  final String readTime;
  final Color accent;
  final String? imageUrl;
  final double imageHeight;
  final bool personalized;
  final bool isQuoteCard;
  final int estimatedHeight;

  const _FeedCardData({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.readTime,
    required this.accent,
    required this.imageUrl,
    required this.imageHeight,
    this.personalized = false,
    required this.estimatedHeight,
  }) : isQuoteCard = false;

  const _FeedCardData.quote({
    required this.title,
    required this.subtitle,
    required this.readTime,
    required this.estimatedHeight,
  })  : category = 'Daily Wisdom',
        accent = const Color(0xFF1754CF),
        imageUrl = null,
        imageHeight = 0,
        personalized = false,
        isQuoteCard = true;
}

class _FavoriteArticleData {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final String readTime;
  final String imageUrl;
  final String authorName;
  final String authorRole;
  final String publishedDate;
  final DateTime? savedAt;

  const _FavoriteArticleData({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.readTime,
    required this.imageUrl,
    required this.authorName,
    required this.authorRole,
    required this.publishedDate,
    required this.savedAt,
  });

  factory _FavoriteArticleData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return _FavoriteArticleData(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Untitled article',
      category: (data['category'] as String?)?.trim().isNotEmpty == true
          ? (data['category'] as String).trim()
          : 'Journal',
      subtitle: (data['subtitle'] as String?)?.trim().isNotEmpty == true
          ? (data['subtitle'] as String).trim()
          : 'Saved from your journal portal.',
      readTime: (data['read_time'] as String?)?.trim().isNotEmpty == true
          ? (data['read_time'] as String).trim()
          : 'Saved article',
      imageUrl: (data['image_url'] as String?)?.trim().isNotEmpty == true
          ? (data['image_url'] as String).trim()
          : 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      authorName: (data['author_name'] as String?)?.trim().isNotEmpty == true
          ? (data['author_name'] as String).trim()
          : 'Therapii Editorial',
      authorRole: (data['author_role'] as String?)?.trim().isNotEmpty == true
          ? (data['author_role'] as String).trim()
          : 'Journal Team',
      publishedDate:
          (data['published_date'] as String?)?.trim().isNotEmpty == true
              ? (data['published_date'] as String).trim()
              : 'Recently saved',
      savedAt: (data['saved_at'] as Timestamp?)?.toDate(),
    );
  }

  String? get savedLabel {
    final date = savedAt;
    if (date == null) return null;
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays <= 0) {
      if (difference.inHours <= 0) {
        final minutes = difference.inMinutes.clamp(1, 59);
        return '$minutes min ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }
}
