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
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Support Hub'),
        centerTitle: true,
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
                  return const Center(child: Text('No support conversations.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final convo = conversations[index];
                    final unread = convo.adminUnreadCount > 0;
                    final format = DateFormat('MMM d, h:mm a');
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: unread ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          convo.userEmail.isNotEmpty ? convo.userEmail[0].toUpperCase() : 'U',
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                      ),
                      title: Text(
                        convo.userEmail,
                        style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text(
                        convo.lastMessageText ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
                          fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            format.format(convo.updatedAt),
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                          if (unread)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
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
