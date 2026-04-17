import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapii/models/support_message.dart';
import 'package:therapii/services/support_service.dart';
import 'package:intl/intl.dart';

import 'package:therapii/openai/openai_config.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _supportService = SupportService();
  final _auth = FirebaseAuth.instance;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isAiMode = true;
  bool _isAiReplying = false;
  final AiCompanionClient _aiClient = const AiCompanionClient();
  
  String? _userId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      _userEmail = user.email ?? 'Unknown';
      _supportService.markRead(_userId!, isAdmin: false);
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
    if (text.isEmpty || _userId == null) return;
    
    _textController.clear();
    
    await _supportService.sendMessage(
      userId: _userId!,
      userEmail: _userEmail!,
      senderId: _userId!,
      text: text,
      isAdmin: false,
    );
    
    _scrollToBottom();
    
    if (_isAiMode) {
      setState(() {
        _isAiReplying = true;
      });
      
      try {
        // Fetch recent messages
        final messagesStream = await _supportService.streamMessages(_userId!).first;
        final history = messagesStream.map((m) {
          return AiChatMessage(
            role: m.senderId == _userId ? 'user' : 'assistant',
            content: m.text,
          );
        }).toList();
        
        // Add system prompt
        final aiMessages = [
          AiChatMessage(
            role: 'system',
            content: 'You are the official Support AI for Therapii, an app for therapists and clients. Keep answers brief, helpful, and empathetic. If you cannot solve an issue, advise the user to switch to "Talk to Human" so our team can assist them.',
          ),
          ...history,
        ];
        
        final responseText = await _aiClient.sendChat(messages: aiMessages);
        
        if (responseText.isNotEmpty) {
          await _supportService.sendMessage(
            userId: _userId!,
            userEmail: _userEmail!,
            senderId: 'support_ai',
            text: responseText,
            isAdmin: true,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI Support Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAiReplying = false;
          });
          _scrollToBottom();
        }
      }
    }
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    if (_userId == null) {
      return Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: Text('Must be logged in to access support.')),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
        children: [
          _buildIntercomHeader(theme),
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: _supportService.streamMessages(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_chat_unread_rounded, size: 64, color: scheme.primary.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send us a message and we\'ll get back to you as soon as possible.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Delay scrolling to ensure list is rendered
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _supportService.markRead(_userId!, isAdmin: false);
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _userId;
                    
                    // Add slight margin top if previous message was from someone else
                    bool addMargin = false;
                    if (index > 0) {
                      addMargin = messages[index - 1].senderId != msg.senderId;
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
    )));
  }

  Widget _buildIntercomHeader(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/therapii_logo_white.png', height: 28, errorBuilder: (c, e, s) => const SizedBox()),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hi there 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We help your experience be as smooth as possible. How can we help today?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAiMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isAiMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isAiMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        'Talk To AI',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _isAiMode ? scheme.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAiMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isAiMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isAiMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        'Talk To Human',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: !_isAiMode ? scheme.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isAiMode) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 36,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(radius: 16, backgroundColor: scheme.secondaryContainer, child: Icon(Icons.person, color: scheme.onSecondaryContainer, size: 20)),
                      ),
                      Positioned(
                        left: 20,
                        child: CircleAvatar(radius: 16, backgroundColor: scheme.tertiaryContainer, child: Icon(Icons.person, color: scheme.onTertiaryContainer, size: 20)),
                      ),
                      Positioned(
                        left: 40,
                        child: CircleAvatar(radius: 16, backgroundColor: scheme.surface, child: Icon(Icons.person, color: scheme.primary, size: 20)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our usual reply time',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Under 5 mins',
                            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isAiReplying)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is typing...',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Container(
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
                  enabled: !_isAiReplying,
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
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
                  onPressed: _isAiReplying ? null : _sendMessage,
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
