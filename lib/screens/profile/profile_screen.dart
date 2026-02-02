import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../widgets/post_grid_item.dart';
import '../../widgets/post_detail_bottom_sheet.dart';
import '../auth/login_screen.dart';
import '../admin/approval_requests_screen.dart';
import 'analytics_tab.dart';
import 'user_management_tab.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  UserModel? _currentUser;
  TabController? _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userData = await _authService.getUserData(firebaseUser.uid);
        if (userData != null) {
          setState(() {
            _currentUser = userData;
            _initializeTabController();
            _isLoading = false;
          });
        } else {
          // Create a basic user model from Firebase user for demo
          setState(() {
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? 'User',
              displayName: firebaseUser.displayName ?? 'User',
              userType: 'student', // Default
              createdAt: DateTime.now(),
              isActive: true,
            );
            _initializeTabController();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeTabController() {
    if (_currentUser == null) return;
    
    int tabCount = 0;
    if (_currentUser!.userType == 'student') {
      tabCount = 0; // No tabs for students
    } else if (_currentUser!.userType == 'admin') {
      tabCount = 3; // Photo, Blog, Analytics
    } else {
      tabCount = 2; // Photo, Blog for clubs
    }
    
    if (tabCount > 0) {
      _tabController = TabController(length: tabCount, vsync: this);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // Use the callback if provided, otherwise fallback to navigation
        if (widget.onLogout != null) {
          widget.onLogout!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Not logged in', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser!.displayName ?? 'Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          _buildProfileHeader(),
          
          // Tabs (if user is not a student)
          if (_tabController != null)
            TabBar(
              controller: _tabController,
              tabs: _buildTabs(),
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey,
            ),
          
          if (_tabController != null) const Divider(height: 1),
          
          // Content area with tabs or posts
          Expanded(
            child: _tabController != null
                ? TabBarView(
                    controller: _tabController,
                    children: _buildTabViews(),
                  )
                : _buildStudentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Students cannot create posts',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check the Feed tab to see posts from clubs and announcements',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabs() {
    if (_currentUser!.userType == 'admin') {
      return const [
        Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
        Tab(icon: Icon(Icons.article), text: 'Blogs'),
        Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
      ];
    } else {
      // Clubs
      return const [
        Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
        Tab(icon: Icon(Icons.article), text: 'Blogs'),
      ];
    }
  }

  List<Widget> _buildTabViews() {
    if (_currentUser!.userType == 'admin') {
      return [
        _buildPostsGrid(PostType.photo),
        _buildPostsList(PostType.blog),
        _buildAnalyticsTab(),
      ];
    } else {
      // Clubs
      return [
        _buildPostsGrid(PostType.photo),
        _buildPostsList(PostType.blog),
      ];
    }
  }

  Widget _buildAnalyticsTab() {
    return Column(
      children: [
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.blue.shade600,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Statistics'),
                    Tab(text: 'User Management'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      AnalyticsTab(),
                      UserManagementTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid(PostType postType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allPosts = snapshot.data?.docs ?? [];
        
        // Filter by post type and sort by createdAt
        final posts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] as String?;
          return type == (postType == PostType.photo ? 'photo' : 'blog');
        }).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          return Post.fromMap(data, doc.id);
        }).toList();

        // Sort by createdAt on client side
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (posts.isEmpty) {
          return _buildEmptyState(postType);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostGridItem(post: posts[index]);
          },
        );
      },
    );
  }

  Widget _buildPostsList(PostType postType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allPosts = snapshot.data?.docs ?? [];
        
        // Filter by post type and sort by createdAt
        final posts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] as String?;
          return type == (postType == PostType.photo ? 'photo' : 'blog');
        }).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          return Post.fromMap(data, doc.id);
        }).toList();

        // Sort by createdAt on client side
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (posts.isEmpty) {
          return _buildEmptyState(postType);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _showPostDetail(context, post),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.caption,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.blogContent ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${post.likes.length}'),
                          const SizedBox(width: 16),
                          Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPostDetail(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailBottomSheet(post: post),
    );
  }

  Widget _buildEmptyState(PostType postType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            postType == PostType.photo ? Icons.photo_library_outlined : Icons.article_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${postType == PostType.photo ? 'photo' : 'blog'} posts yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser!.userType == 'student'
                ? 'Check the Feed tab to see posts from clubs and announcements'
                : 'Create your first ${postType == PostType.photo ? 'photo' : 'blog'} post',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Profile picture
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: _currentUser!.photoURL != null
                    ? NetworkImage(_currentUser!.photoURL!)
                    : null,
                child: _currentUser!.photoURL == null
                    ? Text(
                        (_currentUser!.displayName?.isNotEmpty ?? false)
                            ? _currentUser!.displayName![0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 20),
              
              // Stats
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('authorId', isEqualTo: _currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final postCount = snapshot.data?.docs.length ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', postCount),
                        _buildStatColumn('Type', _currentUser!.userType.toUpperCase()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Name and info
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.displayName ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (_currentUser!.department != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.department!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_currentUser!.studentId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Student ID: ${_currentUser!.studentId}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_currentUser!.clubName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.clubName!,
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Column(
            children: [
              // Admin-specific buttons
              if (_currentUser!.userType == 'admin') ...[
                SizedBox(
                  width: double.infinity,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('registration_requests')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final requestCount = snapshot.data?.docs.length ?? 0;
                      
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ApprovalRequestsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.pending_actions),
                            const SizedBox(width: 8),
                            const Text('Approval Requests'),
                            if (requestCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  requestCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              Row(
                children: [
                  // Only show Edit Profile for non-students
                  if (_currentUser!.userType != 'student') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit profile coming soon!')),
                          );
                        },
                        child: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }


}