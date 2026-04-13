import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapii/models/support_message.dart';
import 'package:therapii/services/support_service.dart';
import 'package:intl/intl.dart';

class AdminSupportChatPage extends StatefulWidget {
  final String userId;
  final String userEmail;

  const AdminSupportChatPage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<AdminSupportChatPage> createState() => _AdminSupportChatPageState();
}

class _AdminSupportChatPageState extends State<AdminSupportChatPage> {
  final _supportService = SupportService();
  final _auth = FirebaseAuth.instance;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  String? _adminId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _adminId = user.uid;
      _supportService.markRead(widget.userId, isAdmin: true);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _adminId == null) return;
    
    _textController.clear();
    
    await _supportService.sendMessage(
      userId: widget.userId,
      userEmail: widget.userEmail,
      senderId: _adminId!,
      text: text,
      isAdmin: true,
    );
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 1,
        shadowColor: scheme.shadow.withValues(alpha: 0.1),
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userEmail,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'User ID: ${widget.userId.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<SupportMessage>>(
                    stream: _supportService.streamMessages(widget.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages.'));
                      }
                      
                      // Delay scrolling to ensure list is rendered
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _supportService.markRead(widget.userId, isAdmin: true);
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.isAdmin;
                          
                          bool addMargin = false;
                          if (index > 0) {
                            addMargin = messages[index - 1].isAdmin != msg.isAdmin;
                          } else {
                            addMargin = true;
                          }

                          return _buildMessageBubble(msg, isMe, addMargin, scheme);
                        },
                      );
                    },
                  ),
                ),
                _buildInputArea(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage msg, bool isMe, bool addMargin, ColorScheme scheme) {
    final format = DateFormat('h:mm a');
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 4, top: addMargin ? 16 : 0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              format.format(msg.sentAt),
              style: TextStyle(
                color: isMe ? scheme.onPrimary.withValues(alpha: 0.7) : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a reply...',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send_rounded, color: scheme.onPrimary, size: 20),
              onPressed: _sendMessage,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
