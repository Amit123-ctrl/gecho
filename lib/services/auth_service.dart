import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Main login method - checks credentials against Firebase database
  Future<UserModel?> signInWithEmailPasswordAndType(String email, String password, String accountType) async {
    try {
      print('Starting login for $email as $accountType');
      
      // Step 1: Determine which collection to check
      String collection;
      switch (accountType.toLowerCase()) {
        case 'admin':
          collection = 'admin_users';
          break;
        case 'student':
          collection = 'student_users';
          break;
        case 'club':
          collection = 'club_users';
          break;
        default:
          throw Exception('Invalid account type');
      }
      
      print('Checking collection: $collection');
      
      // Step 2: Find user in Firebase database
      final query = await _firestore
          .collection(collection)
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (query.docs.isEmpty) {
        throw Exception('No $accountType account found with this email');
      }
      
      final userDoc = query.docs.first;
      final userData = userDoc.data();
      
      print('User found: ${userData['name']}');
      
      // Step 3: Check if user is restricted
      final isRestricted = userData['isRestricted'] as bool? ?? false;
      if (isRestricted) {
        final restrictedUntil = (userData['restrictedUntil'] as Timestamp?)?.toDate();
        if (restrictedUntil != null && restrictedUntil.isAfter(DateTime.now())) {
          final reason = userData['restrictionReason'] as String?;
          throw Exception('RESTRICTED|${restrictedUntil.toIso8601String()}|${reason ?? 'No reason provided'}');
        }
      }
      
      // Step 4: Check password
      if (userData['password'] != password) {
        throw Exception('Incorrect password');
      }
      
      print('Password correct');
      
      // Step 5: Create Firebase Auth user for app navigation
      firebase_auth.UserCredential authResult;
      
      final tempPassword = dotenv.env['FIREBASE_TEMP_PASSWORD'] ?? 'TempPass123!';
      
      try {
        authResult = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        print('Firebase Auth user created');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          authResult = await _auth.signInWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
          print('Firebase Auth user signed in');
        } else {
          throw Exception('Authentication failed');
        }
      }
      
      // Step 6: Create user model
      final user = UserModel(
        uid: authResult.user!.uid,
        email: userData['email'] ?? email,
        name: userData['name'] ?? '',
        displayName: userData['displayName'] ?? userData['name'] ?? '',
        userType: accountType.toLowerCase(),
        createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
        isActive: userData['isActive'] ?? true,
        studentId: userData['studentId'],
        department: userData['department'],
        year: userData['year'],
        clubName: userData['clubName'],
        clubType: userData['clubType'],
      );
      
      // Step 7: Store in main users collection
      await _firestore.collection('users').doc(authResult.user!.uid).set(user.toFirestore());
      
      print('Login successful for ${user.email}');
      return user;
      
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  // Sign in with Google (placeholder for admin screen)
  Future<UserModel?> signInWithGoogle() async {
    try {
      // This is a placeholder - implement Google sign in if needed
      throw Exception('Google sign in not implemented yet');
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  // Add approved user (placeholder for admin panel)
  Future<void> addApprovedUser({
    required String email,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Add user to the appropriate collection
      String collection;
      switch (userType.toLowerCase()) {
        case 'admin':
          collection = 'admin_users';
          break;
        case 'student':
          collection = 'student_users';
          break;
        case 'club':
          collection = 'club_users';
          break;
        default:
          throw Exception('Invalid user type');
      }

      await _firestore.collection(collection).add({
        'email': email.toLowerCase(),
        'userType': userType.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        ...userData,
      });

      print('User $email added to $collection');
    } catch (e) {
      print('Error adding approved user: $e');
      rethrow;
    }
  }
}