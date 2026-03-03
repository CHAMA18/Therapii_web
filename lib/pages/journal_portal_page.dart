import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_article_page.dart';
import 'package:therapii/theme_mode_controller.dart';
import 'package:therapii/utils/admin_access.dart';

enum _PortalSidebarItem { home, journal }

const _portalDestinationKey = 'journal_portal_destination';
const _portalDestinationHome = 'home';
const _portalDestinationJournal = 'journal';

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
      subtitle: 'Scripts and mindset shifts for protecting your energy with compassion.',
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
      subtitle: 'A steadier way to regain momentum when life interrupts your plans.',
      readTime: '5 min read',
      accent: Color(0xFF3157D5),
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 208,
      estimatedHeight: 396,
    ),
    _FeedCardData.quote(
      title: '"Healing is not becoming someone new. It is returning to who you were beneath survival."',
      subtitle: 'Therapii Wisdom',
      readTime: "Editor's Note",
      estimatedHeight: 334,
    ),
    _FeedCardData(
      category: 'Relationships',
      title: 'Rupture and Repair in Close Relationships',
      subtitle: 'Conflict does not have to mean disconnection when repair is intentional.',
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
      subtitle: 'Grounding patterns for nights when overthinking keeps your body awake.',
      readTime: '4 min read',
      accent: Color(0xFFCC6A24),
      imageUrl:
          'https://images.unsplash.com/photo-1493836512294-502baa1986e2?auto=format&fit=crop&w=1200&q=80',
      imageHeight: 224,
      estimatedHeight: 404,
    ),
  ];

  final List<_SavedArticleData> _savedArticles = const [
    _SavedArticleData(
      title: 'Navigating Grief in Modern Times',
      readTime: '6 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1472396961693-142e6e269027?auto=format&fit=crop&w=600&q=80',
    ),
    _SavedArticleData(
      title: 'The Power of Routine',
      readTime: '5 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80',
    ),
    _SavedArticleData(
      title: 'Meditation 101',
      readTime: '8 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  int _selectedTopicIndex = 0;
  int _visibleCardCount = _initialVisibleCardCount;
  bool _isRestoringDestination = true;

  @override
  void initState() {
    super.initState();
    _restoreDestination();
  }

  Future<void> _restoreDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final destination = prefs.getString(_portalDestinationKey) ?? _portalDestinationHome;

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

    await prefs.setString(_portalDestinationKey, _portalDestinationHome);
    if (!mounted) return;
    setState(() => _isRestoringDestination = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringDestination) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final showLeftRail = width >= 1100;
    final showRightRail = width >= 1480;
    final isAdmin = AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
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
                    activeItem: _PortalSidebarItem.home,
                    onHomeTap: () {},
                    onJournalTap: () {
                      _openJournal();
                    },
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
                if (showRightRail) _RightRail(savedItems: _savedArticles),
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
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  List<_FeedCardData> get _visibleCards {
    final upperBound = _visibleCardCount.clamp(0, _cards.length) as int;
    return _cards.take(upperBound).toList(growable: false);
  }

  void _loadMoreArticles() {
    if (_visibleCardCount >= _cards.length) return;
    setState(() {
      _visibleCardCount = (_visibleCardCount + _loadMoreBatchSize).clamp(0, _cards.length) as int;
    });
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: -130,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x331754CF), Color(0x001754CF)],
                  radius: 0.85,
                ),
              ),
            ),
          ),
          Positioned(
            right: 120,
            top: 36,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x191856B5), Color(0x001856B5)],
                  radius: 0.9,
                ),
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
  final _PortalSidebarItem activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onJournalTap;
  const _LeftRail({
    required this.isAdmin,
    required this.activeItem,
    required this.onHomeTap,
    required this.onJournalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 276,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F9FF), Color(0xFFF0F4FF)],
        ),
        border: Border(right: BorderSide(color: Color(0xFFE1E7F5))),
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
          const SizedBox(height: 8),
          const _ThemeModeButton(),
          const Spacer(),
          const _LogoutButton(),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 12)),
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
                const Text(
                  'Therapii Portal',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      isAdmin ? 'Admin Account' : 'Free Member',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1754CF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF1754CF).withOpacity(0.28)),
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

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: themeModeController.toggleLightDark,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE1E7F5)),
          foregroundColor: const Color(0xFF0F172A),
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            await FirebaseAuthManager().signOut();
          } catch (_) {}
          if (context.mounted) Navigator.of(context).maybePop();
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE1E7F5)),
          foregroundColor: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: active ? const Color(0xFFDCE8FF) : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          color: active ? const Color(0xFF1754CF) : const Color(0xFF697386),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            color: active ? const Color(0xFF1754CF) : const Color(0xFF283245),
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
  static const _homeSurface = Color(0xFFF4F6FB);
  static const _homePanel = Color(0xFFFDFDFF);
  static const _homeBorder = Color(0xFFDDE3EF);

  static const List<_WisdomFeedItemData> _wisdomFeed = [
    _WisdomFeedItemData(
      timestamp: 'Yesterday • 10:42 PM',
      quote:
          '"You noticed a pattern of seeking validation in stressful environments. This awareness is the first step toward internal stability."',
      tags: ['Self-Regulation', 'Work Harmony'],
      accent: Color(0xFF6EA8FF),
      icon: Icons.auto_awesome_rounded,
    ),
    _WisdomFeedItemData(
      timestamp: 'May 12 • Evening',
      quote:
          '"Your description of the ocean breeze suggests that sensory-based grounding techniques are highly effective for you."',
      tags: ['Grounding'],
      accent: Color(0xFFB17CFF),
      icon: Icons.psychology_alt_rounded,
    ),
    _WisdomFeedItemData(
      timestamp: 'May 10 • Post-session',
      quote:
          '"Growth is often quiet. You\'ve consistently mentioned patience three times this week. A shift is occurring."',
      tags: ['Patience', 'Growth'],
      accent: Color(0xFF47C98A),
      icon: Icons.spa_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _persistDestination();
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

  void _archiveReflection() {
    final hasText = _reflectionController.text.trim().isNotEmpty;
    if (!hasText) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reflection archived. Your wisdom feed will continue adapting.'),
      ),
    );
    setState(() => _reflectionController.clear());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showLeftRail = width >= 1200;
    final isAdmin = AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);

    return Scaffold(
      backgroundColor: _homeSurface,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLeftRail)
              _LeftRail(
                isAdmin: isAdmin,
                activeItem: _PortalSidebarItem.journal,
                onHomeTap: () {
                  _openHome();
                },
                onJournalTap: () {},
              ),
            Expanded(
              child: _JournalReflectionPane(
                showCompactHeader: !showLeftRail,
                greeting: '${_greeting()}, ${_firstName()}.',
                controller: _reflectionController,
                wisdomFeed: _wisdomFeed,
                onArchive: _archiveReflection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalReflectionPane extends StatefulWidget {
  final bool showCompactHeader;
  final String greeting;
  final TextEditingController controller;
  final List<_WisdomFeedItemData> wisdomFeed;
  final VoidCallback onArchive;

  const _JournalReflectionPane({
    required this.showCompactHeader,
    required this.greeting,
    required this.controller,
    required this.wisdomFeed,
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
    return Container(
      color: _JournalReflectionPageState._homeSurface,
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
                          child: _ReflectionEditor(controller: widget.controller),
                        ),
                        const SizedBox(height: 24),
                        _ReflectionActions(
                          enabled: _hasText,
                          onArchive: widget.onArchive,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: const Color(0xFFE1E7F5),
                ),
                SizedBox(
                  width: 430,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(34, 36, 32, 22),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _WisdomFeedColumn(items: widget.wisdomFeed),
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
                  onArchive: widget.onArchive,
                ),
                const SizedBox(height: 30),
                _WisdomFeedColumn(items: widget.wisdomFeed),
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
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A2131),
          ),
          tooltip: 'Back',
        ),
        const SizedBox(width: 10),
        const Text(
          'Therapii Portal',
          style: TextStyle(
            color: Color(0xFF1A2131),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            color: Color(0xFF1E293B),
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
            color: Color(0xFF9CA3AF),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _JournalReflectionPageState._homePanel,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: _JournalReflectionPageState._homeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B1324),
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
              style: const TextStyle(
                color: Color(0xFF334155),
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
              const IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Begin typing to release...',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
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
  final VoidCallback onArchive;

  const _ReflectionActions({
    required this.enabled,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _ActionCircleButton(icon: Icons.mic_none_rounded),
        SizedBox(width: 16),
        _ActionCircleButton(icon: Icons.image_outlined),
      ],
    );

    final archiveButton = FilledButton(
      onPressed: enabled ? onArchive : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Archive Reflection'),
          SizedBox(width: 10),
          Icon(Icons.north_east_rounded, size: 18),
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
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _JournalReflectionPageState._homeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B1324),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF9CA3AF), size: 28),
    );
  }
}

class _WisdomFeedColumn extends StatelessWidget {
  final List<_WisdomFeedItemData> items;
  const _WisdomFeedColumn({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text(
                'WISDOM FEED',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
            ),
            Text(
              'UPDATED',
              style: TextStyle(
                color: Color(0xFFB0B8C4),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.circle, color: Color(0xFF8BB5FF), size: 10),
          ],
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < items.length; i++) ...[
          _WisdomFeedCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 26),
        ],
        const SizedBox(height: 28),
        const _AnalysisCard(),
      ],
    );
  }
}

class _WisdomFeedCard extends StatelessWidget {
  final _WisdomFeedItemData item;
  const _WisdomFeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: _JournalReflectionPageState._homePanel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _JournalReflectionPageState._homeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0B1324),
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
                  style: const TextStyle(
                    color: Color(0xFFA0A8B5),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(item.icon, color: item.accent, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.quote,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontFamily: 'Satoshi',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: 20,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tag in item.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _JournalReflectionPageState._homePanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _JournalReflectionPageState._homeBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.insights_rounded, color: Color(0xFF5C8EFF)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Analysis',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '7-day emotional report',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC0C8D4), size: 28),
        ],
      ),
    );
  }
}

class _WisdomFeedItemData {
  final String timestamp;
  final String quote;
  final List<String> tags;
  final Color accent;
  final IconData icon;

  const _WisdomFeedItemData({
    required this.timestamp,
    required this.quote,
    required this.tags,
    required this.accent,
    required this.icon,
  });
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, showCompactHeader ? 12 : 24, horizontalPadding, 0),
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
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A2131),
                            ),
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Therapii Portal',
                            style: TextStyle(
                              color: Color(0xFF1A2131),
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
                        color: const Color(0xFF111726),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Curated insights for your mental wellbeing',
                      style: TextStyle(
                        color: Color(0xFF6E7482),
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
              color: const Color(0xFFF4F6FB).withOpacity(0.97),
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
          padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 20),
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
                    backgroundColor: Colors.white.withOpacity(0.92),
                    foregroundColor: const Color(0xFF4B5565),
                    side: const BorderSide(color: Color(0xFFD8DDE8)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D1F44), Color(0xFF394866)],
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xD9000000), Color(0x70000000), Color(0x00000000)],
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                    radius: 0.9,
                  ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
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
                      const Icon(Icons.schedule_rounded, size: 16, color: Color(0xE6FFFFFF)),
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
    final selected = widget.selected;
    final bgGradient = selected
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E67DD), Color(0xFF1546B9)],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withOpacity(_hovered ? 1 : 0.96),
              const Color(0xFFF2F5FB).withOpacity(_hovered ? 1 : 0.92),
            ],
          );
    final borderColor = selected
        ? const Color(0xAAFFFFFF)
        : (_hovered ? const Color(0xFFC7D0E2) : const Color(0xFFD8DDE8));
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
              color: const Color(0xFF1B2436).withOpacity(_hovered ? 0.08 : 0.05),
              blurRadius: _hovered ? 14 : 10,
              offset: Offset(0, _hovered ? 6 : 4),
            ),
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
            gradient: bgGradient,
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
              splashColor: selected ? Colors.white.withOpacity(0.18) : const Color(0x221754CF),
              highlightColor: Colors.transparent,
              onHighlightChanged: (down) => setState(() => _pressed = down),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
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
                                border: Border.all(color: Colors.white.withOpacity(0.7)),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty-dot'), width: 0, height: 0),
                    ),
                    if (selected) const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF4A5568),
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

class _FeedArticleCard extends StatelessWidget {
  final _FeedCardData data;
  const _FeedArticleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isQuoteCard) {
      return _QuoteCard(data: data);
    }

    return Material(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JournalArticlePage(
                title: data.title,
                category: data.category,
                subtitle: data.subtitle,
                readTime: data.readTime,
                imageUrl: data.imageUrl ??
                    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
                authorName: 'Dr. Eleanor Vance',
                authorRole: 'Clinical Psychologist',
                publishedDate: 'Oct 14, 2023',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE1EC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1324).withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.imageUrl != null) ...[
                SizedBox(
                  height: data.imageHeight,
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
                          data.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFCBD5E1)),
                        ),
                        if (data.personalized)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 13, color: data.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Personalized',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: data.accent,
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
                      data.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: data.accent,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF151B2A),
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE6EAF2)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          data.readTime,
                          style: const TextStyle(
                            color: Color(0xFF8A91A2),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.bookmark_border_rounded, size: 20, color: Colors.black.withOpacity(0.45)),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE1EC)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF0FF), Color(0xFFDCE6FF), Color(0xFFF4F7FF)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: Color(0xFF1D56D4), size: 34),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111A2B),
              height: 1.24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '- ${data.subtitle}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C667A),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFD3DCEE)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                data.readTime,
                style: const TextStyle(
                  color: Color(0xFF8A91A2),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.share_rounded, size: 20, color: Colors.black.withOpacity(0.45)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RightRail extends StatelessWidget {
  final List<_SavedArticleData> savedItems;
  const _RightRail({required this.savedItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFF),
        border: Border(left: BorderSide(color: Color(0xFFE3E6F0))),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDE1EC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const _WeeklyProgressWidget(progress: 0.75, minutesRead: 45),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Saved for Later',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF121A2A),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
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
            for (var i = 0; i < savedItems.length; i++) ...[
              _SavedItemTile(item: savedItems[i]),
              if (i < savedItems.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x261754CF), Color(0x101754CF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF121A2A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock audio guided meditations for deeper focus.',
                    style: TextStyle(
                      color: Color(0xFF4C5567),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
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
  const _WeeklyProgressWidget({required this.progress, required this.minutesRead});

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Progress',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF131B2C),
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
                    backgroundColor: const Color(0xFFE4E8F1),
                    color: const Color(0xFF1754CF),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF131B2C),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5F6778),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedItemTile extends StatelessWidget {
  final _SavedArticleData item;
  const _SavedItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE1EC)),
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
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE4E7EF)),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2234),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.readTime,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B8498),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight || maxHeight != oldDelegate.maxHeight || child != oldDelegate.child;
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

class _SavedArticleData {
  final String title;
  final String readTime;
  final String imageUrl;

  const _SavedArticleData({
    required this.title,
    required this.readTime,
    required this.imageUrl,
  });
}
