import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementTarget { therapist, patient, both }

class Announcement {
  final String id;
  final String message;
  final AnnouncementTarget target;
  final bool isActive;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.message,
    required this.target,
    required this.isActive,
    required this.createdAt,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      message: map['message'] ?? '',
      target: AnnouncementTarget.values.firstWhere(
        (e) => e.name == map['target'],
        orElse: () => AnnouncementTarget.both,
      ),
      isActive: map['is_active'] ?? true,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'target': target.name,
      'is_active': isActive,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
