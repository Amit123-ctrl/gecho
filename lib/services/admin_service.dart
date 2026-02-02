import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get collection name based on user type
  String _getCollectionName(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return 'admin_users';
      case 'student':
        return 'student_users';
      case 'club':
        return 'club_users';
      default:
        return 'student_users';
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      final studentsSnapshot = await _firestore.collection('student_users').get();
      final clubsSnapshot = await _firestore.collection('club_users').get();
      final adminsSnapshot = await _firestore.collection('admin_users').get();

      final totalUsers = studentsSnapshot.docs.length + 
                        clubsSnapshot.docs.length + 
                        adminsSnapshot.docs.length;

      return {
        'students': studentsSnapshot.docs.length,
        'clubs': clubsSnapshot.docs.length,
        'admins': adminsSnapshot.docs.length,
        'totalUsers': totalUsers,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'students': 0, 'clubs': 0, 'admins': 0, 'totalUsers': 0};
    }
  }

  // Get post statistics by category (excluding student posts)
  Future<Map<String, int>> getPostStats() async {
    try {
      final postsSnapshot = await _firestore.collection('posts').get();
      
      int clubPosts = 0;
      int adminPosts = 0;
      int totalComments = 0;
      int totalPosts = 0;

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();
        final authorType = data['authorType'] as String?;
        
        // Only count club and admin posts (students can't post)
        if (authorType == 'club') {
          clubPosts++;
          totalPosts++;
        } else if (authorType == 'admin') {
          adminPosts++;
          totalPosts++;
        }

        totalComments += (data['commentCount'] as int?) ?? 0;
      }

      return {
        'clubPosts': clubPosts,
        'adminPosts': adminPosts,
        'totalPosts': totalPosts,
        'totalComments': totalComments,
      };
    } catch (e) {
      print('Error getting post stats: $e');
      return {
        'clubPosts': 0,
        'adminPosts': 0,
        'totalPosts': 0,
        'totalComments': 0,
      };
    }
  }

  // Get all users from all collections
  Future<List<UserModel>> getAllUsers() async {
    List<UserModel> allUsers = [];

    try {
      // Get students
      final studentsSnapshot = await _firestore.collection('student_users').get();
      for (var doc in studentsSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }

      // Get clubs
      final clubsSnapshot = await _firestore.collection('club_users').get();
      for (var doc in clubsSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }

      // Get admins
      final adminsSnapshot = await _firestore.collection('admin_users').get();
      for (var doc in adminsSnapshot.docs) {
        allUsers.add(UserModel.fromFirestore(doc));
      }

      return allUsers;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Restrict a user
  Future<String?> restrictUser({
    required String userId,
    required String userType,
    required DateTime until,
    String? reason,
  }) async {
    try {
      final collection = _getCollectionName(userType);
      
      await _firestore.collection(collection).doc(userId).update({
        'isRestricted': true,
        'restrictedUntil': Timestamp.fromDate(until),
        'restrictionReason': reason,
      });

      print('User $userId restricted until $until');
      return null; // Success
    } catch (e) {
      print('Error restricting user: $e');
      return 'Failed to restrict user: ${e.toString()}';
    }
  }

  // Unrestrict a user
  Future<String?> unrestrictUser({
    required String userId,
    required String userType,
  }) async {
    try {
      final collection = _getCollectionName(userType);
      
      await _firestore.collection(collection).doc(userId).update({
        'isRestricted': false,
        'restrictedUntil': null,
        'restrictionReason': null,
      });

      print('User $userId unrestricted');
      return null; // Success
    } catch (e) {
      print('Error unrestricting user: $e');
      return 'Failed to unrestrict user: ${e.toString()}';
    }
  }

  // Check if user is currently restricted
  Future<bool> isUserRestricted(String userId, String userType) async {
    try {
      final collection = _getCollectionName(userType);
      final doc = await _firestore.collection(collection).doc(userId).get();
      
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isRestricted = data['isRestricted'] as bool? ?? false;
      
      if (!isRestricted) return false;

      final restrictedUntil = (data['restrictedUntil'] as Timestamp?)?.toDate();
      
      // Check if restriction has expired
      if (restrictedUntil != null && restrictedUntil.isBefore(DateTime.now())) {
        // Auto-unrestrict if expired
        await unrestrictUser(userId: userId, userType: userType);
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking restriction: $e');
      return false;
    }
  }
}
