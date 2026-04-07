import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:therapii/models/support_conversation.dart';
import 'package:therapii/models/support_message.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _convos = 'support_conversations';

  Stream<SupportConversation?> streamConversation(String userId) {
    return _firestore
        .collection(_convos)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? SupportConversation.fromDoc(doc) : null);
  }

  Stream<List<SupportMessage>> streamMessages(String userId) {
    return _firestore
        .collection(_convos)
        .doc(userId)
        .collection('messages')
        .orderBy('sent_at')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => SupportMessage.fromDoc(doc)).toList());
  }

  Future<void> sendMessage({
    required String userId,
    required String userEmail,
    required String senderId,
    required String text,
    required bool isAdmin,
  }) async {
    final convoRef = _firestore.collection(_convos).doc(userId);
    final msgsRef = convoRef.collection('messages');
    final timestamp = FieldValue.serverTimestamp();

    await convoRef.set({
      'user_id': userId,
      'user_email': userEmail,
      'last_message_text': text,
      'updated_at': timestamp,
      'admin_unread_count': isAdmin ? 0 : FieldValue.increment(1),
      'user_unread_count': isAdmin ? FieldValue.increment(1) : 0,
    }, SetOptions(merge: true));

    await msgsRef.add({
      'sender_id': senderId,
      'text': text,
      'is_admin': isAdmin,
      'sent_at': timestamp,
    });
  }

  Stream<List<SupportConversation>> streamAdminConversations() {
    return _firestore
        .collection(_convos)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => SupportConversation.fromDoc(doc)).toList());
  }

  Future<void> markRead(String userId, {required bool isAdmin}) async {
    try {
      await _firestore.collection(_convos).doc(userId).update({
        isAdmin ? 'admin_unread_count' : 'user_unread_count': 0,
      });
    } catch (e) {
      // Ignored if document doesn't exist yet
    }
  }
}
