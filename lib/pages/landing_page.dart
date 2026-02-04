import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:therapii/pages/auth_welcome_page.dart';

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
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _glowController;

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
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AuthWelcomePage(initialTab: AuthTab.login)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                ),
                const _AdaptiveConsciousnessSection(),
                _SupportInTheVoidSection(
                  floatController: _floatController,
                  glowController: _glowController,
                ),
                _PremiumSection(onRequestAccess: _navigateToAuth),
                const _FooterSection(),
              ],
            ),
          ),
          _NavBar(onSignIn: _navigateToAuth),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final VoidCallback onSignIn;
  const _NavBar({required this.onSignIn});

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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: const Icon(Icons.psychology_alt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Therapii',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            // Nav links (only on wide screens)
            if (isWide)
              Row(
                children: [
                  _NavLink(label: 'Journal'),
                  const SizedBox(width: 40),
                  _NavLink(label: 'Methodology'),
                  const SizedBox(width: 40),
                  _NavLink(label: 'Access'),
                ],
              ),
            // Sign In button
            ElevatedButton(
              onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'Sign In',
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
  const _NavLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.6),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AnimationController shimmerController;
  final AnimationController floatController;
  final VoidCallback onSignIn;
  final VoidCallback onBeginExperience;

  const _HeroSection({
    required this.shimmerController,
    required this.floatController,
    required this.onSignIn,
    required this.onBeginExperience,
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
                  _ShimmerText(controller: shimmerController, isWide: isWide),
                  SizedBox(height: isWide ? 32 : 24),
                  // Subtitle
                  Text(
                    'An immersive AI companion designed to extend the therapeutic relationship beyond the session.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: isWide ? 20 : 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: isWide ? 48 : 32),
                  // CTA buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _GlassButton(label: 'Begin Experience', onTap: onBeginExperience),
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
                child: _FloatingMessageCard(),
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

  const _ShimmerText({required this.controller, required this.isWide});

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
              Text(
                'The Future of',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 80 : 40,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                'Emotional Care',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 80 : 40,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.1,
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
            child: Text(
              '"How are you feeling about the new job today?"',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.9),
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
              Text(
                'AI ACTIVE NOW',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2,
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
  const _AdaptiveConsciousnessSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1024;
    final isMedium = screenWidth > 768;

    final features = [
      _FeatureData(
        number: 'I',
        title: 'Foundational Care',
        description: 'Immediate support trained on global therapeutic modalities. Always present, always aware.',
        icon: Icons.psychology,
      ),
      _FeatureData(
        number: 'II',
        title: 'Therapist Mirroring',
        description: 'The AI studies your therapist\'s voice, engagement style, and specialization to create a seamless extension of care.',
        icon: Icons.manage_accounts,
        isHighlighted: true,
      ),
      _FeatureData(
        number: 'III',
        title: 'Deep Resonance',
        description: 'Hyper-personalized engagement based on long-term patient history, evolving needs, and subtle emotional cues.',
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
                Text(
                  'INTELLIGENCE LEVELS',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Adaptive Consciousness',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isMedium ? 48 : 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
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
                  children: features
                      .map((f) => Expanded(child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _FeatureCard(data: f),
                          )))
                      .toList(),
                )
              : Column(
                  children: features
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: _FeatureCard(data: f),
                          ))
                      .toList(),
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

  const _FeatureCard({required this.data});

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
                  Text(
                    widget.data.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.data.description,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.6,
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

  const _SupportInTheVoidSection({
    required this.floatController,
    required this.glowController,
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
                Expanded(child: _VoidTextContent()),
                const SizedBox(width: 80),
                Expanded(
                  child: _PhoneMockup(
                    floatController: floatController,
                    glowController: glowController,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _VoidTextContent(),
                const SizedBox(height: 64),
                _PhoneMockup(
                  floatController: floatController,
                  glowController: glowController,
                ),
              ],
            ),
    );
  }
}

class _VoidTextContent extends StatelessWidget {
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
              const TextSpan(text: 'Support in\nthe '),
              TextSpan(
                text: 'Void.',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Your personalized AI support system, floating in the space between sessions. Available on iOS and Android.',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Download iOS', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text('Android', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
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

  const _PhoneMockup({required this.floatController, required this.glowController});

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
                              _ChatBubble(
                                isAi: true,
                                message: 'Sarah, take a deep breath. Based on your heart rate, you seem elevated.',
                              ),
                              const SizedBox(height: 16),
                              _ChatBubble(
                                isAi: false,
                                message: 'I\'m anxious about the presentation.',
                              ),
                              const SizedBox(height: 16),
                              _ChatBubble(
                                isAi: true,
                                message: 'Let\'s visualize the outcome together. What is the best case scenario?',
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
                              Text(
                                'Type a message...',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.2),
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

  const _PremiumSection({required this.onRequestAccess});

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        'EXCLUSIVE BETA',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Therapii Premium',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unrestricted access to the world\'s most advanced emotional intelligence engine.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$29',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ month',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Features
                    ...['24/7 Deep Learning Analysis', 'Therapist Dashboard Integration', 'Unlimited Voice & Text Interaction']
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, color: Colors.white, size: 16),
                                  const SizedBox(width: 12),
                                  Text(
                                    f,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    const SizedBox(height: 24),
                    // CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onRequestAccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Request Access',
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
  const _FooterSection();

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
                    Icon(Icons.psychology_alt, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Therapii',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                // Copyright
                Text(
                  '© 2025 Therapii Inc. London • New York • Tokyo',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 2,
                  ),
                ),
                // Social links
                Row(
                  children: [
                    _FooterLink(label: 'Instagram'),
                    const SizedBox(width: 24),
                    _FooterLink(label: 'Twitter'),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.psychology_alt, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Therapii',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterLink(label: 'Instagram'),
                    const SizedBox(width: 24),
                    _FooterLink(label: 'Twitter'),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '© 2025 Therapii Inc.',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;

  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
