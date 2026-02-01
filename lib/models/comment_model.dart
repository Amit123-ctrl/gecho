import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorType; // 'student', 'club', 'admin'
  final String? authorProfileImage;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    this.authorProfileImage,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorType: map['authorType'] ?? 'student',
      authorProfileImage: map['authorProfileImage'],
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorType': authorType,
      'authorProfileImage': authorProfileImage,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Helper method to get role badge emoji
  String get roleBadge {
    switch (authorType.toLowerCase()) {
      case 'admin':
        return '👨‍💼';
      case 'club':
        return '🏛️';
      case 'student':
        return '🎓';
      default:
        return '👤';
    }
  }

  // Helper method to get role color
  String get roleColor {
    switch (authorType.toLowerCase()) {
      case 'admin':
        return 'orange';
      case 'club':
        return 'blue';
      case 'student':
        return 'green';
      default:
        return 'grey';
    }
  }
}
