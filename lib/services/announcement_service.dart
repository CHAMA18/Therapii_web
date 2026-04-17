import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:therapii/models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Announcement>> getActiveAnnouncements(AnnouncementTarget userType) {
    return _firestore
        .collection('announcements')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final all = snapshot.docs.map((doc) => Announcement.fromMap(doc.id, doc.data())).toList();
          return all.where((a) => a.target == AnnouncementTarget.both || a.target == userType).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
  }

  Stream<List<Announcement>> getAllAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Announcement.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> createAnnouncement(String message, AnnouncementTarget target) async {
    await _firestore.collection('announcements').add({
      'message': message,
      'target': target.name,
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleAnnouncement(String id, bool isActive) async {
    await _firestore.collection('announcements').doc(id).update({
      'is_active': isActive,
    });
  }
  
  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }
}
