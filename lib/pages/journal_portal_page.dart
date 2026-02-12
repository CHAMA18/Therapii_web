import 'package:flutter/material.dart';

class JournalPortalPage extends StatelessWidget {
  const JournalPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) const _LeftNav(),
            const Expanded(child: _FeedContent()),
            if (isWide) const _RightRail(),
          ],
        ),
      ),
    );
  }
}

class _LeftNav extends StatelessWidget {
  const _LeftNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 24, child: Icon(Icons.person)),
          const SizedBox(height: 12),
          const Text('Therapii Portal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 24),
          _navTile(Icons.home_outlined, 'Home'),
          _navTile(Icons.menu_book_outlined, 'Journal', active: true),
          _navTile(Icons.chat_bubble_outline, 'Chat'),
          _navTile(Icons.settings_outlined, 'Settings'),
          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _navTile(IconData icon, String label, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F0FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: active ? const Color(0xFF1754CF) : const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF1754CF) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedContent extends StatelessWidget {
  const _FeedContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Therapeutic Feed', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Curated insights for your mental wellbeing', style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 20),
              _heroCard(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Tag('For You', active: true),
                  _Tag('Resilience'),
                  _Tag('Mindfulness'),
                  _Tag('Anxiety'),
                  _Tag('Sleep'),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 2 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: const [
                  _ArticleCard(
                    title: 'Understanding Attachment Styles',
                    subtitle: 'How early bonds shape relationship patterns today.',
                    chip: 'Cognitive Therapy',
                  ),
                  _ArticleCard(
                    title: '5 Breathing Techniques for Instant Calm',
                    subtitle: 'Simple methods to regulate your nervous system.',
                    chip: 'Mindfulness',
                  ),
                  _ArticleCard(
                    title: 'Why Journaling Works',
                    subtitle: 'Expressive writing can lower stress and improve clarity.',
                    chip: 'Self-Care',
                  ),
                  _ArticleCard(
                    title: 'Sleep Hygiene Basics',
                    subtitle: 'Small environmental tweaks for better sleep.',
                    chip: 'Sleep Hygiene',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF374151)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Featured Insight', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text(
            'The Art of Letting Go: How to Release Past Burdens',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
          ),
          SizedBox(height: 8),
          Text(
            'Frameworks to process, accept, and move forward with more ease.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _RightRail extends StatelessWidget {
  const _RightRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Weekly Progress', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('45 mins read this week', style: TextStyle(color: Color(0xFF6B7280))),
          SizedBox(height: 20),
          Text('Saved for Later', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          _SavedItem('Navigating Grief in Modern Times'),
          _SavedItem('The Power of Routine'),
          _SavedItem('Meditation 101'),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool active;
  const _Tag(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1754CF) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? const Color(0xFF1754CF) : const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF4B5563),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String chip;
  const _ArticleCard({
    required this.title,
    required this.subtitle,
    required this.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chip, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1754CF))),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, height: 1.2)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _SavedItem extends StatelessWidget {
  final String title;
  const _SavedItem(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
