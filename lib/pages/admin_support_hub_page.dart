import 'package:flutter/material.dart';
import 'package:therapii/models/support_conversation.dart';
import 'package:therapii/services/support_service.dart';
import 'package:therapii/pages/admin_support_chat_page.dart';
import 'package:intl/intl.dart';

class AdminSupportHubPage extends StatelessWidget {
  const AdminSupportHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final supportService = SupportService();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: const Text('Support Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<List<SupportConversation>>(
              stream: supportService.streamAdminConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final conversations = snapshot.data ?? [];
                
                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: scheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No active support conversations.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final convo = conversations[index];
                    final unread = convo.adminUnreadCount > 0;
                    final format = DateFormat('MMM d, h:mm a');
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: unread ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant.withValues(alpha: 0.5),
                          width: unread ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: unread ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          child: Text(
                            convo.userEmail.isNotEmpty ? convo.userEmail[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: unread ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                convo.userEmail,
                                style: TextStyle(
                                  fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              format.format(convo.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: unread ? scheme.primary : scheme.onSurfaceVariant,
                                fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  convo.lastMessageText ?? 'No messages yet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
                                    fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (unread)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${convo.adminUnreadCount}',
                                    style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminSupportChatPage(
                                userId: convo.userId,
                                userEmail: convo.userEmail,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
