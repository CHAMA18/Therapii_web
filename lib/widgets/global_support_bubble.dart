import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapii/pages/support_chat_page.dart';

class GlobalSupportBubble extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const GlobalSupportBubble({super.key, required this.navigatorKey});

  @override
  State<GlobalSupportBubble> createState() => _GlobalSupportBubbleState();
}

class _GlobalSupportBubbleState extends State<GlobalSupportBubble> {
  Offset? _position;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Only show bubble if user is logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final size = MediaQuery.of(context).size;
        
        // Default position: bottom-right, but above typical floating action buttons
        _position ??= Offset(size.width - 76, size.height - 140);

        final theme = Theme.of(context);

        return AnimatedPositioned(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          left: _position!.dx,
          top: _position!.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  _position!.dx + details.delta.dx,
                  _position!.dy + details.delta.dy,
                );
              });
            },
            onPanEnd: (details) {
              double newX = _position!.dx;
              double newY = _position!.dy;

              // Keep within vertical bounds
              if (newY < 60) newY = 60; // Avoid status bar
              if (newY > size.height - 100) newY = size.height - 100; // Avoid bottom edge

              // Snap to left or right edge
              if (newX < size.width / 2) {
                newX = 20; // Snap to left
              } else {
                newX = size.width - 76; // Snap to right (assuming 56 width + 20 padding)
              }

              setState(() {
                _isDragging = false;
                _position = Offset(newX, newY);
              });
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final ctx = widget.navigatorKey.currentContext;
                  if (ctx != null) {
                    showDialog(
                      context: ctx,
                      barrierColor: Colors.transparent,
                      builder: (dialogContext) {
                        final windowSize = MediaQuery.of(dialogContext).size;
                        return Dialog(
                          alignment: Alignment.bottomRight,
                          insetPadding: EdgeInsets.only(
                            right: 24,
                            bottom: 80,
                            top: 24,
                            left: windowSize.width > 600 ? windowSize.width - 400 - 24 : 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 8,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 400,
                              maxHeight: windowSize.height * 0.8,
                            ),
                            child: const SupportChatPage(),
                          ),
                        );
                      },
                    );
                  }
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
