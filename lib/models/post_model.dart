enum PostType { photo, blog }

class Post {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorProfileImage;
  final String authorType; // 'student', 'club', 'admin'
  final PostType type;
  final String? imageUrl;
  final String caption;
  final String? blogContent; // For blog posts
  final List<String> likes;
  final int commentCount;
  final List<String> tags;
  final DateTime createdAt;
  final bool isPriority; // For admin priority posts
  final DateTime? priorityExpiresAt; // When priority expires

  Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorProfileImage,
    required this.authorType,
    required this.type,
    this.imageUrl,
    required this.caption,
    this.blogContent,
    this.likes = const [],
    this.commentCount = 0,
    this.tags = const [],
    required this.createdAt,
    this.isPriority = false,
    this.priorityExpiresAt,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    // Handle likes field - can be either int (old format) or List<String> (new format)
    List<String> parsedLikes = [];
    if (map['likes'] != null) {
      if (map['likes'] is List) {
        parsedLikes = List<String>.from(map['likes']);
      }
      // If it's an int (old format), just ignore it and start fresh with empty list
    }

    return Post(
      id: id,
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorDisplayName: map['authorDisplayName'] ?? '',
      authorProfileImage: map['authorProfileImage'],
      authorType: map['authorType'] ?? 'student',
      type: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${map['type']}',
        orElse: () => PostType.photo,
      ),
      imageUrl: map['imageUrl'],
      caption: map['caption'] ?? '',
      blogContent: map['blogContent'],
      likes: parsedLikes,
      commentCount: map['commentCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isPriority: map['isPriority'] ?? false,
      priorityExpiresAt: map['priorityExpiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['priorityExpiresAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorProfileImage': authorProfileImage,
      'authorType': authorType,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'caption': caption,
      'blogContent': blogContent,
      'likes': likes,
      'commentCount': commentCount,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isPriority': isPriority,
      'priorityExpiresAt': priorityExpiresAt?.millisecondsSinceEpoch,
    };
  }

  bool get isPhoto => type == PostType.photo;
  bool get isBlog => type == PostType.blog;
}