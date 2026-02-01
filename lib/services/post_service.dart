import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'image_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();

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
        return 'student_users'; // Default fallback
    }
  }
  final Uuid _uuid = const Uuid();

  // Get all posts from global posts collection (everyone can see all posts)
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Post> posts = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          // Convert Firestore timestamp to milliseconds for Post.fromMap
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          if (data['priorityExpiresAt'] is Timestamp) {
            data['priorityExpiresAt'] = (data['priorityExpiresAt'] as Timestamp).millisecondsSinceEpoch;
          }
          return Post.fromMap(data, doc.id);
        } catch (e) {
          print('Error parsing post ${doc.id}: $e');
          return null;
        }
      }).where((post) => post != null).cast<Post>().toList();

      // Sort posts: Priority posts (not expired) first, then by creation date
      posts.sort((a, b) {
        final now = DateTime.now();
        
        // Check if posts are priority and not expired
        final aIsPriorityActive = a.isPriority && 
            (a.priorityExpiresAt == null || a.priorityExpiresAt!.isAfter(now));
        final bIsPriorityActive = b.isPriority && 
            (b.priorityExpiresAt == null || b.priorityExpiresAt!.isAfter(now));
        
        // Priority posts come first
        if (aIsPriorityActive && !bIsPriorityActive) return -1;
        if (!aIsPriorityActive && bIsPriorityActive) return 1;
        
        // If both are priority or both are not priority, sort by creation date
        return b.createdAt.compareTo(a.createdAt);
      });

      return posts;
    });
  }

  // Delete post from global posts collection
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      print('Post $postId deleted successfully');
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Get posts from all known users (legacy method - updated for role-based collections)
  Stream<List<Post>> _getAllPostsFromKnownUsers() async* {
    // Create a list to hold all posts
    List<Post> allPosts = [];
    
    // Get posts from all user types and collections
    for (String userType in ['admin', 'student', 'club']) {
      try {
        final collection = _getCollectionName(userType);
        final usersSnapshot = await _firestore.collection(collection).get();
        
        for (final userDoc in usersSnapshot.docs) {
          try {
            final userPosts = await _firestore
                .collection(collection)
                .doc(userDoc.id)
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .get();
            
            final posts = userPosts.docs
                .map((doc) => Post.fromMap(doc.data(), doc.id))
                .toList();
            
            allPosts.addAll(posts);
          } catch (e) {
            print('Error getting posts for user ${userDoc.id}: $e');
          }
        }
      } catch (e) {
        print('Error getting posts from $userType collection: $e');
      }
    }
    
    // Sort all posts by creation date
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    yield allPosts;
    
    // Set up real-time updates
    await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
      allPosts.clear();
      
      // Refresh posts from all collections
      for (String userType in ['admin', 'student', 'club']) {
        try {
          final collection = _getCollectionName(userType);
          final usersSnapshot = await _firestore.collection(collection).get();
          
          for (final userDoc in usersSnapshot.docs) {
            try {
              final userPosts = await _firestore
                  .collection(collection)
                  .doc(userDoc.id)
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .get();
              
              final posts = userPosts.docs
                  .map((doc) => Post.fromMap(doc.data(), doc.id))
                  .toList();
              
              allPosts.addAll(posts);
            } catch (e) {
              print('Error getting posts for user ${userDoc.id}: $e');
            }
          }
        } catch (e) {
          print('Error getting posts from $userType collection: $e');
        }
      }
      
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield allPosts;
    }
  }

  // Alternative method for when index is ready
  Stream<List<Post>> getAllPostsWithIndex() {
    return _firestore
        .collectionGroup('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get posts by specific user with user type
  Stream<List<Post>> getUserPostsByType(String userId, String userType) {
    final collection = _getCollectionName(userType);
    return _firestore
        .collection(collection)
        .doc(userId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get posts by specific user (legacy - tries all collections)
  Stream<List<Post>> getUserPosts(String userId) {
    // Try to find user in each collection and return their posts
    return Stream.fromFuture(_getUserPostsFromAnyCollection(userId));
  }

  Future<List<Post>> _getUserPostsFromAnyCollection(String userId) async {
    for (String userType in ['admin', 'student', 'club']) {
      try {
        final collection = _getCollectionName(userType);
        final userPosts = await _firestore
            .collection(collection)
            .doc(userId)
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .get();

        if (userPosts.docs.isNotEmpty) {
          return userPosts.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList();
        }
      } catch (e) {
        print('Error getting posts from $userType collection: $e');
      }
    }
    return [];
  }

  // Get single post by trying all collections
  Future<Post?> getPost(String userId, String postId) async {
    for (String userType in ['admin', 'student', 'club']) {
      try {
        final collection = _getCollectionName(userType);
        final doc = await _firestore
            .collection(collection)
            .doc(userId)
            .collection('posts')
            .doc(postId)
            .get();
        
        if (doc.exists) {
          return Post.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        print('Error getting post from $userType collection: $e');
      }
    }
    return null;
  }

  // Get single post with user type
  Future<Post?> getPostByType(String userId, String postId, String userType) async {
    try {
      final collection = _getCollectionName(userType);
      final doc = await _firestore
          .collection(collection)
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .get();
      
      if (doc.exists) {
        return Post.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Create post in global posts collection (new method for all users)
  Future<String?> createPost({
    required String caption,
    required UserModel author,
    PostType type = PostType.photo,
    File? imageFile,
    String? blogContent,
    List<String> tags = const [],
    bool isPriority = false,
  }) async {
    try {
      final postId = _uuid.v4();
      String? imageUrl;
      
      // Upload image if it's a photo post
      if (type == PostType.photo && imageFile != null) {
        imageUrl = await _imageService.uploadImage(
          imageFile: imageFile,
          userId: author.uid,
          postId: postId,
          folder: 'posts',
        );
        
        if (imageUrl == null) {
          return 'Failed to upload image. Please check your internet connection and try again.';
        }
      }

      // Set priority expiry date if this is a priority post (2 days from now)
      DateTime? priorityExpiresAt;
      if (isPriority && author.userType == 'admin') {
        priorityExpiresAt = DateTime.now().add(const Duration(days: 2));
      }

      // Create post
      final post = Post(
        id: postId,
        authorId: author.uid,
        authorUsername: author.name,
        authorDisplayName: author.effectiveDisplayName,
        authorProfileImage: author.profileImageUrl,
        authorType: author.userType,
        type: type,
        imageUrl: imageUrl,
        caption: caption,
        blogContent: blogContent,
        tags: tags,
        createdAt: DateTime.now(),
        isPriority: isPriority && author.userType == 'admin',
        priorityExpiresAt: priorityExpiresAt,
      );

      // Save to global posts collection
      await _firestore
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      return null; // Success
    } catch (e) {
      print('Error creating post: $e');
      return 'Failed to create post: ${e.toString()}';
    }
  }

  // Create photo post with user type
  Future<String?> createPhotoPostByType({
    required File imageFile,
    required String caption,
    required UserModel author,
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      String? imageUrl;
      
      // Upload image to Cloudinary
      imageUrl = await _imageService.uploadImage(
        imageFile: imageFile,
        userId: author.uid,
        postId: postId,
        folder: 'posts',
      );
      
      if (imageUrl != null) {
        print('Image uploaded successfully to Cloudinary: $imageUrl');
      } else {
        print('Cloudinary upload failed');
        return 'Failed to upload image. Please check your internet connection and try again.';
      }

      // Create post in user's posts collection
      final post = Post(
        id: postId,
        authorId: author.uid,
        authorUsername: author.name, // Using name as username
        authorDisplayName: author.effectiveDisplayName,
        authorProfileImage: author.profileImageUrl,
        authorType: author.userType,
        type: PostType.photo,
        imageUrl: imageUrl,
        caption: caption,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // Save to appropriate user collection
      final collection = _getCollectionName(author.userType);
      await _firestore
          .collection(collection)
          .doc(author.uid)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      // Update user's post count
      await _updateUserPostCountByType(author.uid, author.userType);

      return null; // Success
    } catch (e) {
      print('Error creating photo post: $e');
      return 'Failed to create photo post: ${e.toString()}';
    }
  }

  // Create photo post (legacy support)
  Future<String?> createPhotoPost({
    required File imageFile,
    required String caption,
    required User author,
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      String? imageUrl;
      
      // Upload image to Cloudinary
      imageUrl = await _imageService.uploadImage(
        imageFile: imageFile,
        userId: author.id,
        postId: postId,
        folder: 'posts',
      );
      
      if (imageUrl != null) {
        print('Image uploaded successfully to Cloudinary: $imageUrl');
      } else {
        print('Cloudinary upload failed');
        return 'Failed to upload image. Please check your internet connection and try again.';
      }

      // Create post in user's posts collection
      final post = Post(
        id: postId,
        authorId: author.id,
        authorUsername: author.username,
        authorDisplayName: author.displayName,
        authorProfileImage: author.profileImageUrl,
        authorType: 'student', // Default for legacy User model
        type: PostType.photo,
        imageUrl: imageUrl,
        caption: caption,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // Try to save to appropriate collection (fallback to student_users)
      await _firestore
          .collection('student_users')
          .doc(author.id)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      // Update user's post count
      await _updateUserPostCountByType(author.id, 'student');

      return null; // Success
    } catch (e) {
      print('Error creating photo post: $e');
      return 'Failed to create photo post: ${e.toString()}';
    }
  }

  // Create blog post with user type
  Future<String?> createBlogPostByType({
    required String title,
    required String content,
    required UserModel author,
    File? coverImage, // This parameter is kept for compatibility but ignored
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      
      // Blog posts are text-only - no images allowed
      print('Creating text-only blog post');

      // Create blog post
      final post = Post(
        id: postId,
        authorId: author.uid,
        authorUsername: author.name,
        authorDisplayName: author.effectiveDisplayName,
        authorProfileImage: author.profileImageUrl,
        authorType: author.userType,
        type: PostType.blog,
        imageUrl: null, // Blog posts have no images
        caption: title,
        blogContent: content,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // Save to appropriate user collection
      final collection = _getCollectionName(author.userType);
      await _firestore
          .collection(collection)
          .doc(author.uid)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      // Update user's post count
      await _updateUserPostCountByType(author.uid, author.userType);

      return null; // Success
    } catch (e) {
      return 'Failed to create blog post: ${e.toString()}';
    }
  }

  // Create blog post (legacy support)
  Future<String?> createBlogPost({
    required String title,
    required String content,
    required User author,
    File? coverImage, // This parameter is kept for compatibility but ignored
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      
      // Blog posts are text-only - no images allowed
      print('Creating text-only blog post');

      // Create blog post
      final post = Post(
        id: postId,
        authorId: author.id,
        authorUsername: author.username,
        authorDisplayName: author.displayName,
        authorProfileImage: author.profileImageUrl,
        authorType: 'student', // Default for legacy User model
        type: PostType.blog,
        imageUrl: null, // Blog posts have no images
        caption: title,
        blogContent: content,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // Save to student_users collection (fallback)
      await _firestore
          .collection('student_users')
          .doc(author.id)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      // Update user's post count
      await _updateUserPostCountByType(author.id, 'student');

      return null; // Success
    } catch (e) {
      return 'Failed to create blog post: ${e.toString()}';
    }
  }

  // Delete post by type (only by post owner)
  Future<String?> deletePostByType(String userId, String postId, String userType, String? imageUrl) async {
    try {
      final collection = _getCollectionName(userType);
      
      // Delete from user's posts collection
      await _firestore
          .collection(collection)
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .delete();
      
      // Delete image from Cloudinary if exists
      if (imageUrl != null && imageUrl.contains('cloudinary.com')) {
        try {
          // Extract public_id from Cloudinary URL for deletion
          final publicId = 'posts/$userId/$postId';
          await _imageService.deleteImage(publicId);
          print('Image deleted from Cloudinary');
        } catch (e) {
          print('Error deleting image from Cloudinary: $e');
        }
      }

      // Delete all comments for this post
      final commentsSnapshot = await _firestore
          .collection(collection)
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Update user's post count
      await _updateUserPostCountByType(userId, userType);
      
      return null; // Success
    } catch (e) {
      return 'Failed to delete post: ${e.toString()}';
    }
  }



  // Toggle like on post by type
  Future<void> toggleLikeByType(String userId, String postId, String userType, String currentUserId) async {
    final collection = _getCollectionName(userType);
    final postRef = _firestore
        .collection(collection)
        .doc(userId)
        .collection('posts')
        .doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;
      
      final post = Post.fromMap(postDoc.data()!, postId);
      List<String> likes = List.from(post.likes);
      
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }
      
      transaction.update(postRef, {'likes': likes});
    });
  }

  // Toggle like on post (legacy - tries all collections)
  Future<void> toggleLike(String userId, String postId, String currentUserId) async {
    // Try to find post in any collection and toggle like
    for (String userType in ['admin', 'student', 'club']) {
      try {
        final collection = _getCollectionName(userType);
        final postDoc = await _firestore
            .collection(collection)
            .doc(userId)
            .collection('posts')
            .doc(postId)
            .get();
        
        if (postDoc.exists) {
          await toggleLikeByType(userId, postId, userType, currentUserId);
          return; // Found and updated, exit
        }
      } catch (e) {
        print('Error toggling like in $userType collection: $e');
      }
    }
  }

  // Toggle like on global post (for posts collection)
  Future<String?> toggleLikeOnPost(String postId, String currentUserId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }
        
        final data = postDoc.data()!;
        List<String> likes = List<String>.from(data['likes'] ?? []);
        
        if (likes.contains(currentUserId)) {
          likes.remove(currentUserId);
          print('User $currentUserId unliked post $postId');
        } else {
          likes.add(currentUserId);
          print('User $currentUserId liked post $postId');
        }
        
        transaction.update(postRef, {'likes': likes});
      });
      
      return null; // Success
    } catch (e) {
      print('Error toggling like on post: $e');
      return 'Failed to update like: ${e.toString()}';
    }
  }

  // Update user's post count by type
  Future<void> _updateUserPostCountByType(String userId, String userType) async {
    try {
      final collection = _getCollectionName(userType);
      final postsSnapshot = await _firestore
          .collection(collection)
          .doc(userId)
          .collection('posts')
          .get();
      
      await _firestore.collection(collection).doc(userId).update({
        'postsCount': postsSnapshot.docs.length,
      });
    } catch (e) {
      print('Error updating post count: $e');
    }
  }

  // Update user's post count (legacy - tries all collections)
  Future<void> _updateUserPostCount(String userId) async {
    // Try to find user in each collection and update their post count
    for (String userType in ['admin', 'student', 'club']) {
      try {
        final collection = _getCollectionName(userType);
        final userDoc = await _firestore.collection(collection).doc(userId).get();
        
        if (userDoc.exists) {
          final postsSnapshot = await _firestore
              .collection(collection)
              .doc(userId)
              .collection('posts')
              .get();
          
          await _firestore.collection(collection).doc(userId).update({
            'postsCount': postsSnapshot.docs.length,
          });
          return; // Found and updated, exit
        }
      } catch (e) {
        print('Error updating post count for $userType: $e');
      }
    }
  }

  // Update existing posts with image URLs
  Future<void> updateExistingPostsWithImages() async {
    try {
      final postsSnapshot = await _firestore
          .collection('users')
          .doc('current_user')
          .collection('posts')
          .get();

      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'photo' && data['imageUrl'] == null) {
          await doc.reference.update({
            'imageUrl': 'https://picsum.photos/400/600?random=${doc.id.hashCode}',
          });
        }
      }
      print('Updated existing posts with image URLs');
    } catch (e) {
      print('Error updating posts: $e');
    }
  }

  // Create dummy posts for testing
  Future<void> createDummyPosts() async {
    try {
      // Check if posts already exist for current user
      final existingPosts = await _firestore
          .collection('users')
          .doc('current_user')
          .collection('posts')
          .limit(1)
          .get();
      
      if (existingPosts.docs.isNotEmpty) {
        return; // Posts already exist
      }

      final posts = [
        {
          'authorId': 'current_user',
          'authorUsername': 'john_doe',
          'authorDisplayName': 'John Doe',
          'authorProfileImage': null,
          'type': 'photo',
          'imageUrl': 'https://picsum.photos/400/600?random=1',
          'caption': 'Beautiful sunset from my evening walk 🌅 #photography #nature',
          'blogContent': null,
          'likes': ['user_2', 'user_3'],
          'commentCount': 5,
          'tags': ['photography', 'nature', 'sunset'],
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'authorId': 'current_user',
          'authorUsername': 'john_doe',
          'authorDisplayName': 'John Doe',
          'authorProfileImage': null,
          'type': 'blog',
          'imageUrl': null,
          'caption': 'My Journey into Photography',
          'blogContent': '''
Photography has been my passion for over 5 years now. It all started with a simple smartphone camera, but the desire to capture the perfect moment drove me to learn more about composition, lighting, and storytelling through images.

**The Beginning**
I remember my first "real" photo - a candid shot of my friend laughing at a coffee shop. The natural light streaming through the window, the genuine expression, the way everything just came together perfectly. That's when I knew I wanted to pursue photography seriously.

**Learning the Craft**
I spent countless hours watching YouTube tutorials, reading photography blogs, and most importantly, practicing. Every day I would challenge myself to take at least one photo that told a story or captured an emotion.

**Equipment Evolution**
While gear doesn't make the photographer, having the right tools certainly helps. I started with a basic DSLR and gradually upgraded my lenses and equipment as I learned what type of photography I was most passionate about.

**Finding My Style**
After experimenting with various genres - portraits, landscapes, street photography, macro - I discovered that I love capturing candid moments and natural emotions. There's something magical about freezing a genuine smile or a thoughtful expression.

**The Future**
Photography continues to challenge and inspire me every day. Each shoot teaches me something new, and I'm constantly amazed by the stories that can be told through a single frame.

What started as a hobby has become a way of seeing the world differently. Through the lens, I've learned to notice the extraordinary in the ordinary, and that perspective has enriched my life in countless ways.

Keep shooting, keep learning, and most importantly, keep having fun with it! 📸
          ''',
          'likes': ['user_2'],
          'commentCount': 8,
          'tags': ['photography', 'journey', 'passion', 'blog'],
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
        },
      ];

      // Create posts for current user
      for (final postData in posts) {
        final postId = _uuid.v4();
        await _firestore
            .collection('users')
            .doc('current_user')
            .collection('posts')
            .doc(postId)
            .set(postData);
      }

      // Create posts for other users
      final otherUserPosts = [
        {
          'userId': 'user_2',
          'postData': {
            'authorId': 'user_2',
            'authorUsername': 'sarah_wilson',
            'authorDisplayName': 'Sarah Wilson',
            'authorProfileImage': null,
            'type': 'blog',
            'imageUrl': null,
            'caption': '10 Tips for Better Travel Photography',
            'blogContent': '''
Travel photography is an art that combines technical skill with creative vision. Here are my top 10 tips for capturing amazing photos on your next adventure:

1. **Golden Hour Magic**: Shoot during the golden hour (just after sunrise or before sunset) for warm, soft lighting that makes everything look magical.

2. **Tell a Story**: Don't just capture landmarks. Include people, local culture, and candid moments that tell the story of your journey.

3. **Pack Light**: Bring only essential gear. A heavy camera bag will slow you down and make you less likely to take spontaneous shots.

4. **Research Locations**: Scout locations online before you arrive. Apps like PhotoPills can help you plan the perfect shot.

5. **Interact with Locals**: Some of the best travel photos come from genuine interactions with local people. Always ask permission before photographing someone.

6. **Capture Details**: Don't forget the small details - local food, architecture details, street signs, and textures that make each place unique.

7. **Use Leading Lines**: Look for natural lines in the landscape or architecture that draw the viewer's eye into the photo.

8. **Weather is Your Friend**: Don't pack up when the weather gets interesting. Storm clouds, rain, and fog can create dramatic and memorable images.

9. **Backup Everything**: Always have multiple backup solutions for your photos. Memory cards fail, and losing travel photos is heartbreaking.

10. **Edit Thoughtfully**: Post-processing can enhance your photos, but don't overdo it. Keep the natural beauty of the places you visit.

Remember, the best camera is the one you have with you. Sometimes the most memorable shots come from unexpected moments, so always be ready!

Happy travels and happy shooting! 📸✈️
            ''',
            'likes': ['current_user', 'user_3'],
            'commentCount': 12,
            'tags': ['travel', 'photography', 'tips', 'blog'],
            'createdAt': DateTime.now().subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
          }
        },
        {
          'userId': 'user_3',
          'postData': {
            'authorId': 'user_3',
            'authorUsername': 'mike_photo',
            'authorDisplayName': 'Mike Photography',
            'authorProfileImage': null,
            'type': 'photo',
            'imageUrl': null,
            'caption': 'Morning coffee and planning the next shoot ☕📷 #photographer #coffee #workflow',
            'blogContent': null,
            'likes': ['current_user'],
            'commentCount': 3,
            'tags': ['photographer', 'coffee', 'workflow'],
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          }
        }
      ];

      // Create posts for other users
      for (final userPost in otherUserPosts) {
        final postId = _uuid.v4();
        await _firestore
            .collection('users')
            .doc(userPost['userId'] as String)
            .collection('posts')
            .doc(postId)
            .set(userPost['postData'] as Map<String, dynamic>);
      }

      // Update post counts for all users
      await _updateUserPostCount('current_user');
      await _updateUserPostCount('user_2');
      await _updateUserPostCount('user_3');

    } catch (e) {
      print('Error creating dummy posts: $e');
    }
  }
}