import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/openai/openai_config.dart';

class MyCustomSource extends StreamAudioSource {
  final Uint8List bytes;
  MyCustomSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

// Palette constants shared across the page.
const Color _ink = Color(0xFF0F172A);
const Color _warm = Color(0xFFFCFBF9);
const Color _primary = Color(0xFF1754CF);

/// Immersive, editorial-quality article page for the Journal portal.
class JournalArticlePage extends StatefulWidget {
  final String title;
  final String category;
  final String subtitle;
  final String readTime;
  final String imageUrl;
  final String authorName;
  final String authorRole;
  final String publishedDate;

  const JournalArticlePage({
    super.key,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.readTime,
    required this.imageUrl,
    required this.authorName,
    required this.authorRole,
    required this.publishedDate,
  });

  @override
  State<JournalArticlePage> createState() => _JournalArticlePageState();
}

class _JournalArticlePageState extends State<JournalArticlePage> {
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _progress = 0;
  bool _isFavorite = false;
  bool _isSavingFavorite = false;
  bool _isSpeaking = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _initializeAudioPlayer();
    _loadFavoriteState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset.clamp(0, max);
    final next = max == 0 ? 0.0 : offset / max;
    if (next != _progress) {
      setState(() => _progress = next.toDouble());
    }
  }

  void _initializeAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isSpeaking = false;
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        });
      } else if (state.playing) {
        setState(() => _isSpeaking = true);
      } else {
        setState(() => _isSpeaking = false);
      }
    });
  }

  String get _articleId {
    final normalized = widget.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  DocumentReference<Map<String, dynamic>>? get _favoriteDoc {
    final user = FirebaseAuthManager().currentUser;
    final userId = user?.uid;
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
          'title': widget.title,
          'category': widget.category,
          'subtitle': widget.subtitle,
          'read_time': widget.readTime,
          'image_url': widget.imageUrl,
          'author_name': widget.authorName,
          'author_role': widget.authorRole,
          'published_date': widget.publishedDate,
          'saved_at': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Saved to favorites.' : 'Removed from favorites.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorites right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingFavorite = false);
    }
  }

  String get _speakableArticleText => [
        widget.title,
        widget.subtitle,
        'By ${widget.authorName}, ${widget.authorRole}.',
        'We often conceptualize letting go as an act of dropping something like releasing a heavy stone from our hands. However, psychological research suggests that the process is far more active and nuanced.',
        'The human brain is wired for attachment. From an evolutionary perspective, holding onto memories, relationships, and familiar patterns even painful ones provided safety.',
        'The Zeigarnik Effect and Emotional Closure. Russian psychologist Bluma Zeigarnik discovered that people remember uncompleted or interrupted tasks better than completed ones.',
        'Forgiveness is giving up the hope that the past could have been any different.',
        'Acceptance does not mean agreement. It simply means acknowledging the reality of the situation without the emotional resistance that causes suffering.',
        'Practical Steps for Release. Start by identifying the physical sensations associated with the emotion you are holding.',
      ].join(' ');

  Future<void> _toggleReadAloud() async {
    try {
      if (_isSpeaking) {
        await _audioPlayer.pause();
        return;
      }
      
      if (_audioPlayer.audioSource == null) {
        setState(() => _isLoadingAudio = true);
        final client = const AiCompanionClient();
        // Use a "world-class" realistic voice. OpenAI's 'nova' or 'alloy' works well, 
        // but 'nova' is particularly good for soothing/calm articles.
        final bytes = await client.generateSpeech(_speakableArticleText, voice: 'nova', model: 'tts-1-hd');
        await _audioPlayer.setAudioSource(MyCustomSource(bytes));
        if (!mounted) return;
        setState(() => _isLoadingAudio = false);
      }
      
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _isLoadingAudio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read this article aloud right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 1180;
    final isDesktop = media.size.width >= 920;

    return Scaffold(
      backgroundColor: _warm,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHero(),
              SliverToBoxAdapter(child: _buildBody(isWide, isDesktop)),
              SliverToBoxAdapter(child: const SizedBox(height: 48)),
            ],
          ),
          _ReadingProgress(progress: _progress),
          _FloatingActions(
            isFavorite: _isFavorite,
            isSavingFavorite: _isSavingFavorite,
            isSpeaking: _isSpeaking,
            isLoadingAudio: _isLoadingAudio,
            onFavoriteTap: () {
              _toggleFavorite();
            },
            onReadAloudTap: () {
              _toggleReadAloud();
            },
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHero() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 360,
      elevation: 0,
      pinned: true,
      stretch: true,
      toolbarHeight: 66,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _GlassButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      actions: const [SizedBox(width: 12)],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x990f172a), Color(0x000f172a)],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: Row(
                children: [
                  _Pill(text: widget.category),
                  const SizedBox(width: 12),
                  _MetaChip(icon: Icons.schedule, label: widget.readTime),
                  const SizedBox(width: 10),
                  _MetaChip(icon: Icons.calendar_today, label: widget.publishedDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isWide, bool isDesktop) {
    final maxWidth = isWide ? 1180.0 : 980.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeadingBlock(
                title: widget.title,
                subtitle: widget.subtitle,
                author: widget.authorName,
                role: widget.authorRole,
                isSpeaking: _isSpeaking,
                isLoadingAudio: _isLoadingAudio,
                onListenTap: _toggleReadAloud,
              ),
              const SizedBox(height: 28),
              _ArticleBody(),
              const SizedBox(height: 32),
              _KeyTakeaways(),
              const SizedBox(height: 28),
              _SuggestedReadings(),
              const SizedBox(height: 40),
              _FooterCta(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingProgress extends StatelessWidget {
  final double progress;
  const _ReadingProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(999)),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.35),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF1754CF)),
          ),
        ),
      ),
    );
  }
}

class _FloatingActions extends StatelessWidget {
  final bool isFavorite;
  final bool isSavingFavorite;
  final bool isSpeaking;
  final bool isLoadingAudio;
  final VoidCallback onFavoriteTap;
  final VoidCallback onReadAloudTap;

  const _FloatingActions({
    required this.isFavorite,
    required this.isSavingFavorite,
    required this.isSpeaking,
    required this.isLoadingAudio,
    required this.onFavoriteTap,
    required this.onReadAloudTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassButton(
            icon: isFavorite ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
            onTap: isSavingFavorite ? () {} : onFavoriteTap,
          ),
          const SizedBox(height: 10),
          _GlassButton(
            icon: isSpeaking ? Icons.pause_rounded : Icons.headphones_rounded,
            isLoading: isLoadingAudio,
            onTap: onReadAloudTap,
          ),
          const SizedBox(height: 10),
          _GlassButton(icon: Icons.ios_share_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  const _GlassButton({required this.icon, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.8),
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A))) 
            : Icon(icon, size: 20, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _HeadingBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final String author;
  final String role;
  final bool isSpeaking;
  final bool isLoadingAudio;
  final VoidCallback onListenTap;

  const _HeadingBlock({
    required this.title, 
    required this.subtitle, 
    required this.author, 
    required this.role,
    required this.isSpeaking,
    required this.isLoadingAudio,
    required this.onListenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: _ink,
            height: 1.14,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Color(0xFF5B6475),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBOM6K6RA7JQOvi-m3MQTnfmYBKRrKelGmnsTMvfM_rYr0mL_3Ub2_5fWxOG9WXXtmCqEtoCXzHtzEnLoI2Ud-22Ef9j66UGxQgf_DzlAoEyU7aUBF021WPA5az2IAIzIffcuy317PNwlEp4IdjZlIHywBvaGdC8kTu5ZmmANOa1ik-p_xCT44w7vdNKhc3wq3V7NZdBIx4u_aoE_FlDVCPF6fDGi8uWGm2CUO5dENCyKp8epP09jlzABiPmOqf412oL6A11yCDgPU',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
                Text(role, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
            const Spacer(),
            _GhostButton(label: 'Follow', icon: Icons.add, onTap: () {}),
            const SizedBox(width: 10),
            _GhostButton(
              label: isLoadingAudio ? 'Loading...' : (isSpeaking ? 'Pause' : 'Listen'), 
              icon: isLoadingAudio ? Icons.hourglass_top_rounded : (isSpeaking ? Icons.pause_rounded : Icons.play_arrow_rounded), 
              onTap: isLoadingAudio ? () {} : onListenTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        side: const BorderSide(color: Color(0xFFE3E6EF)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF1754CF), Color(0xFF5A8BFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1754CF).withOpacity(0.24), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontSize: 11),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EBF4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Merriweather',
          fontSize: 17,
          height: 1.8,
          color: const Color(0xFF2C3344),
        ) ??
        const TextStyle(fontSize: 17, height: 1.8, color: Color(0xFF2C3344));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropCapParagraph(
          text:
              'We often conceptualize "letting go" as an act of dropping something—like releasing a heavy stone from our hands. However, psychological research suggests that the process is far more active and nuanced. It is not merely an absence of holding on, but a deliberate cognitive restructuring of our narrative.',
          style: body,
        ),
        const SizedBox(height: 18),
        Text(
          'The human brain is wired for attachment. From an evolutionary perspective, holding onto memories, relationships, and familiar patterns—even painful ones—provided safety. The unknown was dangerous. Today, this survival mechanism often manifests as rumination or an inability to move past emotional wounds.',
          style: body,
        ),
        const SizedBox(height: 28),
        _SectionHeading(title: 'The Zeigarnik Effect and Emotional Closure'),
        const SizedBox(height: 10),
        Text(
          'Russian psychologist Bluma Zeigarnik discovered that people remember uncompleted or interrupted tasks better than completed ones. This phenomenon explains why unresolved emotional business tends to loop in our minds. To truly let go, we often need to create a sense of completion, even if that completion is purely internal.',
          style: body,
        ),
        const SizedBox(height: 24),
        _QuoteCard(
          quote:
              'Forgiveness is giving up the hope that the past could have been any different.',
          author: 'Oprah Winfrey',
        ),
        const SizedBox(height: 24),
        Text(
          'Acceptance does not mean agreement. It simply means acknowledging the reality of the situation without the emotional resistance that causes suffering. By practicing radical acceptance, we free up the mental energy that was previously consumed by fighting against what already is.',
          style: body,
        ),
        const SizedBox(height: 28),
        _SectionHeading(title: 'Practical Steps for Release'),
        const SizedBox(height: 12),
        Text(
          'Start by identifying the physical sensations associated with the emotion you are holding. Is it a tightness in the chest? A knot in the stomach? Direct your breath to these areas. Often, the body holds onto trauma long after the mind has tried to rationalize it away. Somatic release is a crucial component of the healing journey.',
          style: body,
        ),
      ],
    );
  }
}

class _DropCapParagraph extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _DropCapParagraph({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    if (text.length < 2) return Text(text, style: style);
    final first = text.substring(0, 1);
    final rest = text.substring(1);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: first,
            style: style.copyWith(
              fontSize: style.fontSize! * 2.4,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: _ink,
            ),
          ),
          TextSpan(text: rest, style: style),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 24, height: 3, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(999))),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  const _QuoteCard({required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F9FF), Color(0xFFEFF3FF)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.format_quote_rounded, color: _primary, size: 26),
              SizedBox(width: 8),
              Text('Pull Quote', style: TextStyle(fontWeight: FontWeight.w800, color: _primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(author, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _KeyTakeaways extends StatelessWidget {
  const _KeyTakeaways();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: _primary),
              SizedBox(width: 8),
              Text('Key Takeaways', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          const _Bullet(text: 'Letting go is an active cognitive process, not passive.'),
          const SizedBox(height: 10),
          const _Bullet(text: 'The Zeigarnik Effect keeps unresolved emotions looping.'),
          const SizedBox(height: 10),
          const _Bullet(text: 'Somatic release is essential to clear trauma from the body.'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 8, right: 10),
          decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestedReadings extends StatelessWidget {
  const _SuggestedReadings();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _SuggestedItem(
        title: '5 Breathing Techniques for Instant Calm',
        readTime: '3 min read',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBCqPaRsRgdXm6mpPric3RW7DMTidtPWufmOpcZg2CMgqiAQE9lHTQhD_Tg7nJ-cTkiJ_FRRN_paFvj29i0KQpSxl_htHtrfSAtoEdJ3JKfpz3LroA5CItj2ufX-ELa7MtjetsGmTZsV3HwdNQuuIF75GCAy4ZyYYUV7L16drf9s2AjC2hGoISouWE0JHUEvG8N9LM7TRnVRJg7bQleTENc2pY10IXVugH3cvilGjuOsD9J6IxcnSelNruiPrMuSSqbJ1rkf48VC0o',
      ),
      _SuggestedItem(
        title: 'Understanding Attachment Styles',
        readTime: '5 min read',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuA5DTmIhEmsobz3WS-sUnlyHbFXDh6WvrnyHq3T1YRY0S4rAcPQlbgLtFVj5KDO-atU2qd93i3s9BPAtPQarwT1jGwoShJ3qXDiCjzwlgLn_hyXsSUPFNdLItFCDfeSzvUGrGC0bfczt39osp0PldxCygcU9zq9Rq4VMKOEDMw3XpqnLL6d93PGXPLzp8fiMNITN32kUIp-M65MUjPU_xDMSr7ifxDD7IbtYmNfaU2e6WVjhUUafD0YJOyIc4Inm7Q5yCn_TpOnlhk',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggested Reading',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _ink),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EAF2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: Image.network(item.imageUrl, width: 90, height: 128, fit: BoxFit.cover),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _ink,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(item.readTime, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FooterCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1754CF), Color(0xFF3E8BFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_rounded, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Take this further with a guided session. Our therapists can help personalize these practices to your story.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Book a Session'),
          ),
        ],
      ),
    );
  }
}

class _SuggestedItem {
  final String title;
  final String readTime;
  final String imageUrl;
  const _SuggestedItem({required this.title, required this.readTime, required this.imageUrl});
}
