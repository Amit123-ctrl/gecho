import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/comments_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  bool _isExpanded = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _checkIfLiked();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userData = await _authService.getUserData(firebaseUser.uid);
        setState(() {
          _currentUser = userData;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  void _checkIfLiked() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() {
      _isLiked = widget.post.likes.contains(currentUserId);
    });
  }

  Future<void> _toggleLike() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like posts')),
      );
      return;
    }

    // Optimistic UI update
    setState(() {
      _isLiked = !_isLiked;
    });

    // Update in Firestore
    final error = await _postService.toggleLikeOnPost(widget.post.id, currentUserId);
    
    if (error != null) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: widget.post),
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _postService.deletePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting post: $e')),
          );
        }
      }
    }
  }

  bool get _canDeletePost {
    if (_currentUser == null) {
      print('Cannot delete: _currentUser is null');
      return false;
    }
    
    print('Checking delete permission: userType=${_currentUser!.userType}, uid=${_currentUser!.uid}, postAuthorId=${widget.post.authorId}');
    
    // Admins can delete ANY post (including their own)
    if (_currentUser!.userType == 'admin') {
      print('User is admin - can delete');
      return true;
    }
    
    // Users can delete their own posts
    final canDelete = _currentUser!.uid == widget.post.authorId;
    print('User can delete own post: $canDelete');
    return canDelete;
  }

  bool get _isPriorityActive {
    if (!widget.post.isPriority) return false;
    if (widget.post.priorityExpiresAt == null) return true;
    return widget.post.priorityExpiresAt!.isAfter(DateTime.now());
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return Colors.red[600]!;
      case 'club':
        return Colors.blue[600]!;
      case 'student':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getInitial() {
    // Try display name first
    if (widget.post.authorDisplayName.isNotEmpty) {
      return widget.post.authorDisplayName[0].toUpperCase();
    }
    // Fall back to username
    if (widget.post.authorUsername.isNotEmpty) {
      return widget.post.authorUsername[0].toUpperCase();
    }
    // Last resort
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    // Get full content for blog posts
    String fullContent = widget.post.isBlog && widget.post.blogContent != null
        ? widget.post.blogContent!
        : widget.post.caption;
    
    // Determine if content needs truncation (only if longer than 200 chars)
    const int maxLength = 200;
    bool needsTruncation = fullContent.length > maxLength;
    String displayContent = _isExpanded || !needsTruncation
        ? fullContent
        : '${fullContent.substring(0, maxLength)}...';

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator
          if (_isPriorityActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Priority Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Expires ${_formatTimestamp(widget.post.priorityExpiresAt!.millisecondsSinceEpoch)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

          // Header - Author info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.post.authorProfileImage != null
                      ? CachedNetworkImageProvider(widget.post.authorProfileImage!)
                      : null,
                  child: widget.post.authorProfileImage == null
                      ? Text(
                          _getInitial(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                // Username and role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.post.authorDisplayName.isNotEmpty 
                                ? widget.post.authorDisplayName 
                                : widget.post.authorUsername,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // User type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(widget.post.authorType),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.post.authorType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${widget.post.authorUsername}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options
                if (_canDeletePost)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete Post', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),

          // Image - Full width, no rounded corners
          if (widget.post.imageUrl != null)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl!,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 400,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 400,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.error)),
              ),
            ),

          // Action buttons - Like, Comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black87,
                    size: 28,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.black87,
                    size: 26,
                  ),
                  onPressed: _openComments,
                ),
              ],
            ),
          ),

          // Like count
          if (widget.post.likes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${widget.post.likes.length} ${widget.post.likes.length == 1 ? 'like' : 'likes'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

          // Caption/Content with expandable text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blog post indicator
                if (widget.post.isBlog)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Blog Post',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Caption/Title
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '${widget.post.authorDisplayName.isNotEmpty ? widget.post.authorDisplayName : widget.post.authorUsername} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: displayContent),
                    ],
                  ),
                ),

                // Read more / Show less button
                if (needsTruncation)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _isExpanded ? 'Show less' : 'Read more',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Tags
                if (widget.post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.post.tags.map((tag) {
                      return Text(
                        '#$tag',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Comment count and timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.commentCount > 0)
                  GestureDetector(
                    onTap: _openComments,
                    child: Text(
                      'View all ${widget.post.commentCount} ${widget.post.commentCount == 1 ? 'comment' : 'comments'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(widget.post.createdAt.millisecondsSinceEpoch).toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}