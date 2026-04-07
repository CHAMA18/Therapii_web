import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/models/chat_message.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/services/chat_service.dart';
import 'package:therapii/services/user_service.dart';

class PatientChatPage extends StatefulWidget {
  final app_user.User otherUser;
  const PatientChatPage({super.key, required this.otherUser});

  @override
  State<PatientChatPage> createState() => _PatientChatPageState();
}

class _PatientChatPageState extends State<PatientChatPage> {
  final FirebaseAuthManager _authManager = FirebaseAuthManager();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  app_user.User? _viewer;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _contextOptIn = false;

  @override
  void initState() {
    super.initState();
    _loadViewer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadViewer() async {
    final firebaseUser = _authManager.currentUser;
    if (firebaseUser == null) {
      setState(() {
        _error = 'You must be signed in to view messages.';
        _loading = false;
      });
      return;
    }

    try {
      final user = await _userService.getUser(firebaseUser.uid);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _error = 'Profile not found.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _viewer = user;
        _loading = false;
      });
      await _markConversationRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load your profile. Please try again.';
        _loading = false;
      });
    }
  }

  String? get _therapistId {
    if (_viewer == null) return null;
    if (_viewer!.isTherapist) return _viewer!.id;
    if (widget.otherUser.isTherapist) return widget.otherUser.id;
    return _viewer!.therapistId;
  }

  String? get _patientId {
    if (_viewer == null) return null;
    if (_viewer!.isTherapist) return widget.otherUser.id;
    return _viewer!.id;
  }

  bool get _viewerIsTherapist => _viewer?.isTherapist ?? false;

  String get _displayName => _fullNameOrEmail(widget.otherUser);

  String _fullNameOrEmail(app_user.User user) {
    final name = user.fullName.trim();
    if (name.isNotEmpty) return name;
    return user.email;
  }

  Future<void> _handleSendText() async {
    final viewer = _viewer;
    final therapistId = _therapistId;
    final patientId = _patientId;

    if (viewer == null || therapistId == null || patientId == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await _chatService.sendMessage(
        therapistId: therapistId,
        patientId: patientId,
        senderId: viewer.id,
        text: text,
        senderIsTherapist: viewer.isTherapist,
      );
      if (!mounted) return;
      _messageController.clear();
      await _markConversationRead();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleSendAudio(String localPath, int durationSeconds) async {
    final viewer = _viewer;
    final therapistId = _therapistId;
    final patientId = _patientId;

    if (viewer == null || therapistId == null || patientId == null) return;

    setState(() => _sending = true);
    try {
      final audioUrl = await _chatService.uploadAudio(
        localPath: localPath,
        patientId: patientId,
        therapistId: therapistId,
      );

      await _chatService.sendMessage(
        therapistId: therapistId,
        patientId: patientId,
        senderId: viewer.id,
        text: '',
        senderIsTherapist: viewer.isTherapist,
        audioUrl: audioUrl,
        durationSeconds: durationSeconds,
      );

      if (!mounted) return;
      await _markConversationRead();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send voice message: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markConversationRead() async {
    final therapistId = _therapistId;
    final patientId = _patientId;
    final viewer = _viewer;
    if (therapistId == null || patientId == null || viewer == null) return;
    await _chatService.markConversationRead(
      therapistId: therapistId,
      patientId: patientId,
      viewerIsTherapist: viewer.isTherapist,
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = scheme.primary;
    final therapistId = _therapistId;
    final patientId = _patientId;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
        ),
        actions: [
          IconButton(
            tooltip: _contextOptIn ? 'Remove chat from AI context' : 'Add chat as AI context',
            icon: Icon(
              _contextOptIn ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
              color: _contextOptIn ? scheme.primary : scheme.onSurface.withOpacity(0.7),
            ),
            onPressed: () {
              setState(() => _contextOptIn = !_contextOptIn);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_contextOptIn
                      ? 'Chat pinned as context for the AI model.'
                      : 'Chat removed from AI context.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      )
                    : (therapistId == null || patientId == null)
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Unable to determine conversation participants.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: StreamBuilder<List<ChatMessage>>(
                                  stream: _chatService.streamMessages(
                                    therapistId: therapistId,
                                    patientId: patientId,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    final messages = snapshot.data ?? [];
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _markConversationRead();
                                      _scrollToBottom();
                                    });

                                    if (messages.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 40),
                                              Text(
                                                'Start the conversation by sending a message.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
                                              ),
                                              const SizedBox(height: 40),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                                      itemCount: messages.length,
                                      itemBuilder: (context, index) {
                                        final message = messages[index];
                                        final viewer = _viewer;
                                        final isMe = viewer != null && message.senderId == viewer.id;
                                        final previous = index > 0 ? messages[index - 1] : null;
                                        final showAvatar = !isMe && (previous == null || previous.senderId == viewer?.id);

                                        return Padding(
                                          padding: EdgeInsets.only(bottom: index == messages.length - 1 ? 0 : 14),
                                          child: _ChatBubble(
                                            message: message,
                                            isMe: isMe,
                                            color: bubbleColor,
                                            showAvatar: showAvatar,
                                            avatarInitial: widget.otherUser.firstName.isNotEmpty
                                                ? widget.otherUser.firstName[0].toUpperCase()
                                                : '•',
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              _ChatComposer(
                                controller: _messageController,
                                onSendText: _handleSendText,
                                onSendAudio: _handleSendAudio,
                                sending: _sending,
                              ),
                            ],
                          ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final Color color;
  final bool showAvatar;
  final String avatarInitial;
  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.color,
    this.showAvatar = false,
    this.avatarInitial = '?',
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.audioUrl != null) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.message.audioUrl!);
      _player.positionStream.listen((pos) {
        if (mounted) setState(() => _playbackPosition = pos);
      });
      _player.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _playbackDuration = dur);
      });
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
          if (state.processingState == ProcessingState.completed) {
            _player.seek(Duration.zero);
            _player.pause();
          }
        }
      });
      _isPlayerInitialized = true;
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _togglePlay() {
    if (!_isPlayerInitialized) return;
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  BorderRadius _bubbleRadius() {
    const radius = Radius.circular(18);
    const flat = Radius.circular(8);
    if (widget.isMe) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: flat,
        bottomLeft: radius,
        bottomRight: radius,
      );
    }
    return const BorderRadius.only(
      topLeft: flat,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );
  }

  Widget _buildContent(Color textColor, Color barColor, Color progressColor) {
    if (widget.message.audioUrl != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: textColor, size: 36),
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: _playbackDuration.inMilliseconds > 0
                        ? 100 * (_playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds)
                        : 0,
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(_playbackPosition.inMilliseconds > 0 ? _playbackPosition : Duration(seconds: widget.message.durationSeconds ?? 0)),
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    } else {
      return Text(widget.message.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.4));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: _bubbleRadius(),
              ),
              child: _buildContent(Colors.white, Colors.white.withValues(alpha: 0.3), Colors.white),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showAvatar)
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.color,
            child: Text(widget.avatarInitial, style: const TextStyle(color: Colors.white, fontSize: 14)),
          )
        else
          const SizedBox(width: 32),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECEF),
              borderRadius: _bubbleRadius(),
            ),
            child: _buildContent(Colors.black87, Colors.black12, Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSendText;
  final Future<void> Function(String path, int durationSeconds)? onSendAudio;
  final bool sending;
  const _ChatComposer({
    required this.controller,
    required this.onSendText,
    required this.onSendAudio,
    required this.sending,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  bool _hasText = false;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordTimer?.cancel();
    if (_isRecording) {
      unawaited(_recorder.stop());
    }
    unawaited(_recorder.dispose());
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<String> _recordPath() async {
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    if (kIsWeb) return fileName;
    try {
      final dir = await getTemporaryDirectory();
      return '${dir.path}/$fileName';
    } catch (_) {
      return fileName;
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      final duration = _recordDuration.inSeconds;
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });
      if (path != null && widget.onSendAudio != null && duration > 0) {
        await widget.onSendAudio!(path, duration);
      }
    } else {
      final ok = await _recorder.hasPermission();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required.')),
        );
        return;
      }
      final path = await _recordPath();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      });
    }
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            if (_isRecording) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(_format(_recordDuration), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const Spacer(),
            ] else ...[
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (widget.onSendText != null && _hasText) widget.onSendText!();
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your response',
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            if (!_hasText)
              IconButton(
                onPressed: widget.sending ? null : _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : scheme.primary),
                tooltip: _isRecording ? 'Stop and Send' : 'Record Voice',
              )
            else
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.sending || !_hasText ? null : widget.onSendText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    elevation: 0,
                  ),
                  child: widget.sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text(
                          'Send',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
