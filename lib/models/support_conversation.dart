import 'package:cloud_firestore/cloud_firestore.dart';

class SupportConversation {
  final String id;
  final String userId;
  final String userEmail;
  final String? lastMessageText;
  final DateTime updatedAt;
  final int adminUnreadCount;
  final int userUnreadCount;

  const SupportConversation({
    required this.id,
    required this.userId,
    required this.userEmail,
    this.lastMessageText,
    required this.updatedAt,
    this.adminUnreadCount = 0,
    this.userUnreadCount = 0,
  });

  factory SupportConversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SupportConversation(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userEmail: data['user_email'] ?? '',
      lastMessageText: data['last_message_text'] as String?,
      updatedAt: _timestampToDate(data['updated_at']) ?? DateTime.now(),
      adminUnreadCount: (data['admin_unread_count'] ?? 0) as int,
      userUnreadCount: (data['user_unread_count'] ?? 0) as int,
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
