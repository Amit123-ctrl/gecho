import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';

class PostDetailBottomSheet extends StatefulWidget {
  final Post post;

  const PostDetailBottomSheet({super.key, required this.post});

  @override
  State<PostDetailBottomSheet> createState() => _PostDetailBottomSheetState();
}

class _PostDetailBottomSheetState extends State<PostDetailBottomSheet> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  
  bool _isLiked = false;
  int _likeCount = 0;
  UserModel? _currentUser;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initializeLikeState();
    
    // Setup like animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final user = await _authService.getUserData(firebaseUser.uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }

  void _initializeLikeState() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      setState(() {
        _isLiked = widget.post.likes.contains(currentUserId);
        _likeCount = widget.post.likes.length;
      });
    }
  }

  Future<void> _toggleLike() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Optimistic update
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse();
        });
      }
    });

    // Update in database
    final error = await _postService.toggleLikeOnPost(widget.post.id, currentUserId);
    
    if (error != null && mounted) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;

    setState(() {
      _isSubmittingComment = true;
    });

    final error = await _commentService.addComment(
      postId: widget.post.id,
      text: _commentController.text.trim(),
      currentUser: _currentUser!,
    );

    if (mounted) {
      setState(() {
        _isSubmittingComment = false;
      });

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      } else {
        _commentController.clear();
        FocusScope.of(context).unfocus();
      }
    }
  }

  String _getRoleBadge(String userType) {
    switch (userType.toLowerCase()) {
      case 'student':
        return '🎓';
      case 'club':
        return '🏛️';
      case 'admin':
        return '👨‍💼';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with author info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: widget.post.authorProfileImage != null
                          ? NetworkImage(widget.post.authorProfileImage!)
                          : null,
                      child: widget.post.authorProfileImage == null
                          ? Text(
                              widget.post.authorDisplayName.isNotEmpty
                                  ? widget.post.authorDisplayName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.post.authorDisplayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getRoleBadge(widget.post.authorType),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Text(
                            _formatDate(widget.post.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image (if available)
                      if (widget.post.imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: widget.post.imageUrl!,
                          width: double.infinity,
                          height: 400,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 400,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 400,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.error)),
                          ),
                        ),

                      // Action buttons (like, comment)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // Like button
                            ScaleTransition(
                              scale: _likeAnimation,
                              child: IconButton(
                                icon: Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.black,
                                  size: 28,
                                ),
                                onPressed: _toggleLike,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Comment icon
                            Icon(
                              Icons.comment_outlined,
                              size: 26,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            StreamBuilder<List<Comment>>(
                              stream: _commentService.getComments(widget.post.id),
                              builder: (context, snapshot) {
                                final commentCount = snapshot.data?.length ?? widget.post.commentCount;
                                return Text(
                                  '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Caption and content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post type badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.post.isBlog ? Colors.purple.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.post.isBlog ? Icons.article : Icons.photo,
                                    size: 16,
                                    color: widget.post.isBlog ? Colors.purple.shade700 : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.post.isBlog ? 'Blog Post' : 'Photo Post',
                                    style: TextStyle(
                                      color: widget.post.isBlog ? Colors.purple.shade700 : Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Caption
                            Text(
                              widget.post.caption,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Blog content
                            if (widget.post.blogContent != null && widget.post.blogContent!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.post.blogContent!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  height: 1.5,
                                ),
                              ),
                            ],

                            // Tags
                            if (widget.post.tags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.post.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Comments section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<List<Comment>>(
                              stream: _commentService.getComments(widget.post.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                final comments = snapshot.data ?? [];

                                if (comments.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        'No comments yet. Be the first to comment!',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    final isOwnComment = _currentUser?.uid == comment.authorId;
                                    final canDelete = _currentUser?.userType == 'admin' || isOwnComment;

                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey.shade300,
                                          backgroundImage: comment.authorProfileImage != null
                                              ? NetworkImage(comment.authorProfileImage!)
                                              : null,
                                          child: comment.authorProfileImage == null
                                              ? Text(
                                                  comment.authorName.isNotEmpty
                                                      ? comment.authorName[0].toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(fontSize: 12),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    comment.authorName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _getRoleBadge(comment.authorType),
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatDate(comment.createdAt),
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.text,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canDelete)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.grey.shade600,
                                            ),
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete Comment'),
                                                  content: const Text('Are you sure you want to delete this comment?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true && _currentUser != null) {
                                                final error = await _commentService.deleteComment(
                                                  postId: widget.post.id,
                                                  commentId: comment.id,
                                                  currentUserId: _currentUser!.uid,
                                                  isAdmin: _currentUser!.userType == 'admin',
                                                );

                                                if (error != null && mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(error)),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Extra padding at bottom for comment input
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Comment input (fixed at bottom)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmittingComment
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.send,
                              color: _commentController.text.trim().isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.blue,
                            ),
                            onPressed: _commentController.text.trim().isEmpty ? null : _submitComment,
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
