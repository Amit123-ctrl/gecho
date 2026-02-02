import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final AdminService _adminService = AdminService();
  Map<String, int>? _userStats;
  Map<String, int>? _postStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userStats = await _adminService.getUserStats();
      final postStats = await _adminService.getPostStats();

      setState(() {
        _userStats = userStats;
        _postStats = postStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Statistics Section
            Text(
              'User Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildUserStatsCards(),
            
            const SizedBox(height: 32),
            
            // Post Statistics Section
            Text(
              'Post Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildPostStatsCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatsCards() {
    if (_userStats == null) {
      return const Text('No user statistics available');
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Students',
                _userStats!['students'] ?? 0,
                Icons.school,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Clubs',
                _userStats!['clubs'] ?? 0,
                Icons.groups,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Admins',
                _userStats!['admins'] ?? 0,
                Icons.admin_panel_settings,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Users',
                _userStats!['totalUsers'] ?? 0,
                Icons.people,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostStatsCards() {
    if (_postStats == null) {
      return const Text('No post statistics available');
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Club Posts',
                _postStats!['clubPosts'] ?? 0,
                Icons.photo_library,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Admin Posts',
                _postStats!['adminPosts'] ?? 0,
                Icons.photo_library,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total Posts',
          _postStats!['totalPosts'] ?? 0,
          Icons.collections,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
