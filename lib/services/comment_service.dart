import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String text,
    required UserModel currentUser,
  }) async {
    try {
      if (text.trim().isEmpty) {
        return 'Comment cannot be empty';
      }

      final commentId = _firestore.collection('posts').doc(postId).collection('comments').doc().id;

      final comment = Comment(
        id: commentId,
        postId: postId,
        authorId: currentUser.uid,
        authorName: currentUser.name,
        authorType: currentUser.userType,
        authorProfileImage: currentUser.profileImageUrl,
        text: text.trim(),
        createdAt: DateTime.now(),
      );

      // Add comment to subcollection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      // Update comment count in post
      await _updateCommentCount(postId);

      return null; // Success
    } catch (e) {
      print('Error adding comment: $e');
      return 'Failed to add comment: ${e.toString()}';
    }
  }

  // Get comments for a post (real-time stream)
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Oldest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Comment.fromMap(doc.data(), doc.id);
        } catch (e) {
          print('Error parsing comment ${doc.id}: $e');
          return null;
        }
      }).where((comment) => comment != null).cast<Comment>().toList();
    });
  }

  // Delete a comment (admin or comment owner)
  Future<String?> deleteComment({
    required String postId,
    required String commentId,
    required String currentUserId,
    required bool isAdmin,
  }) async {
    try {
      // Get the comment to verify it exists and check ownership
      final commentDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return 'Comment not found';
      }

      final commentData = commentDoc.data()!;
      final commentAuthorId = commentData['authorId'] as String;

      // Check if user is admin or comment owner
      if (!isAdmin && currentUserId != commentAuthorId) {
        return 'You can only delete your own comments';
      }

      // Delete the comment
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comment count
      await _updateCommentCount(postId);

      return null; // Success
    } catch (e) {
      print('Error deleting comment: $e');
      return 'Failed to delete comment: ${e.toString()}';
    }
  }

  // Update comment count in post document
  Future<void> _updateCommentCount(String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      final commentCount = commentsSnapshot.docs.length;

      await _firestore
          .collection('posts')
          .doc(postId)
          .update({'commentCount': commentCount});

      print('Updated comment count for post $postId: $commentCount');
    } catch (e) {
      print('Error updating comment count: $e');
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      return commentsSnapshot.docs.length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }
}
