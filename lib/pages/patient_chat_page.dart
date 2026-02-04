import 'package:flutter/material.dart';
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

  Future<void> _handleSend() async {
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
      if (mounted) {
        setState(() => _sending = false);
      }
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
                                            text: message.text,
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
                                onSend: _handleSend,
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

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Color color;
  final bool showAvatar;
  final String avatarInitial;
  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.color,
    this.showAvatar = false,
    this.avatarInitial = '?',
  });

  BorderRadius _bubbleRadius() {
    const radius = Radius.circular(18);
    const flat = Radius.circular(8);
    if (isMe) {
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

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(color: Colors.white, fontSize: 15, height: 1.4);
    if (isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: _bubbleRadius(),
              ),
              child: Text(text, style: textStyle),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEEF2FC),
              border: Border.all(color: color.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Text(
                avatarInitial,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: _bubbleRadius(),
            ),
            child: Text(text, style: textStyle),
          ),
        ),
      ],
    );
  }
}

class _ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final bool sending;
  const _ChatComposer({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (widget.onSend != null) widget.onSend!();
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
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: widget.sending || !_hasText ? null : widget.onSend,
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
