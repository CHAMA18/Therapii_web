import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String id;
  final String senderId;
  final String text;
  final bool isAdmin;
  final DateTime sentAt;

  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.isAdmin,
    required this.sentAt,
  });

  factory SupportMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SupportMessage(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      text: data['text'] ?? '',
      isAdmin: data['is_admin'] ?? false,
      sentAt: _timestampToDate(data['sent_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
