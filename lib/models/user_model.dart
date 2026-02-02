import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? displayName; // From Google Auth
  final String userType; // 'student' or 'club'
  final String? profileImageUrl;
  final String? photoURL; // From Google Auth
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isActive;
  final bool isApproved; // University approval status

  // Student-specific fields
  final String? studentId;
  final String? department;
  final int? year;

  // Club-specific fields
  final String? clubName;
  final String? clubType;
  final String? description;
  final List<String>? clubMembers;

  // Social stats
  final int followersCount;
  final int followingCount;
  final int postsCount;

  // Restriction fields
  final bool isRestricted;
  final DateTime? restrictedUntil;
  final String? restrictionReason;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.displayName,
    required this.userType,
    this.profileImageUrl,
    this.photoURL,
    this.bio,
    required this.createdAt,
    this.lastActive,
    this.isActive = true,
    this.isApproved = false,
    this.studentId,
    this.department,
    this.year,
    this.clubName,
    this.clubType,
    this.description,
    this.clubMembers,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isRestricted = false,
    this.restrictedUntil,
    this.restrictionReason,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      displayName: data['displayName'],
      userType: data['userType'] ?? 'student',
      profileImageUrl: data['profileImageUrl'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      isApproved: data['isApproved'] ?? false,
      studentId: data['studentId'],
      department: data['department'],
      year: data['year'],
      clubName: data['clubName'],
      clubType: data['clubType'],
      description: data['description'],
      clubMembers: data['clubMembers'] != null 
          ? List<String>.from(data['clubMembers']) 
          : null,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      isRestricted: data['isRestricted'] ?? false,
      restrictedUntil: (data['restrictedUntil'] as Timestamp?)?.toDate(),
      restrictionReason: data['restrictionReason'],
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {
      'email': email,
      'name': name,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'isApproved': isApproved,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isRestricted': isRestricted,
    };

    // Add optional fields if they exist
    if (displayName != null) data['displayName'] = displayName;
    if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
    if (photoURL != null) data['photoURL'] = photoURL;
    if (bio != null) data['bio'] = bio;
    if (lastActive != null) data['lastActive'] = Timestamp.fromDate(lastActive!);
    if (restrictedUntil != null) data['restrictedUntil'] = Timestamp.fromDate(restrictedUntil!);
    if (restrictionReason != null) data['restrictionReason'] = restrictionReason;
    
    // Student-specific fields
    if (studentId != null) data['studentId'] = studentId;
    if (department != null) data['department'] = department;
    if (year != null) data['year'] = year;
    
    // Club-specific fields
    if (clubName != null) data['clubName'] = clubName;
    if (clubType != null) data['clubType'] = clubType;
    if (description != null) data['description'] = description;
    if (clubMembers != null) data['clubMembers'] = clubMembers;

    return data;
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? displayName,
    String? userType,
    String? profileImageUrl,
    String? photoURL,
    String? bio,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isActive,
    bool? isApproved,
    String? studentId,
    String? department,
    int? year,
    String? clubName,
    String? clubType,
    String? description,
    List<String>? clubMembers,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isRestricted,
    DateTime? restrictedUntil,
    String? restrictionReason,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      year: year ?? this.year,
      clubName: clubName ?? this.clubName,
      clubType: clubType ?? this.clubType,
      description: description ?? this.description,
      clubMembers: clubMembers ?? this.clubMembers,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isRestricted: isRestricted ?? this.isRestricted,
      restrictedUntil: restrictedUntil ?? this.restrictedUntil,
      restrictionReason: restrictionReason ?? this.restrictionReason,
    );
  }

  // Helper methods
  bool get isStudent => userType == 'student';
  bool get isClub => userType == 'club';
  
  String get effectiveDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (isClub && clubName != null) {
      return clubName!;
    }
    return name;
  }

  String get subtitle {
    if (isStudent) {
      return studentId != null ? 'Student ID: $studentId' : 'Student';
    } else {
      return clubType != null ? '$clubType Club' : 'Club';
    }
  }

  String get universityRole {
    if (isStudent) {
      return department != null ? '$department Student' : 'Student';
    } else {
      return clubName ?? 'Club';
    }
  }
}

// Legacy User class for backward compatibility (if needed)
class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}