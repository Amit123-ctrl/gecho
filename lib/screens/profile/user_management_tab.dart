import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final AdminService _adminService = AdminService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showRestrictDialog(UserModel user) async {
    final durationController = TextEditingController(text: '7');
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restrict ${user.effectiveDisplayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (days)',
                hintText: 'Enter number of days',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter restriction reason',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restrict'),
          ),
        ],
      ),
    );

    if (result == true) {
      final days = int.tryParse(durationController.text) ?? 7;
      final until = DateTime.now().add(Duration(days: days));
      final reason = reasonController.text.trim();

      final error = await _adminService.restrictUser(
        userId: user.uid,
        userType: user.userType,
        until: until,
        reason: reason.isEmpty ? null : reason,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.effectiveDisplayName} restricted for $days days'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _unrestrictUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Restriction'),
        content: Text('Remove restriction from ${user.effectiveDisplayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unrestrict'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await _adminService.unrestrictUser(
        userId: user.uid,
        userType: user.userType,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.effectiveDisplayName} unrestricted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isRestricted = user.isRestricted && 
        (user.restrictedUntil == null || user.restrictedUntil!.isAfter(DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getUserTypeColor(user.userType).withOpacity(0.2),
          child: Icon(
            _getUserTypeIcon(user.userType),
            color: _getUserTypeColor(user.userType),
          ),
        ),
        title: Text(
          user.effectiveDisplayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isRestricted ? TextDecoration.lineThrough : null,
            color: isRestricted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              user.userType.toUpperCase(),
              style: TextStyle(
                color: _getUserTypeColor(user.userType),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (isRestricted) ...[
              const SizedBox(height: 4),
              Text(
                'Restricted until ${_formatDate(user.restrictedUntil!)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (user.restrictionReason != null)
                Text(
                  'Reason: ${user.restrictionReason}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
            ],
          ],
        ),
        trailing: isRestricted
            ? IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _unrestrictUser(user),
                tooltip: 'Remove restriction',
              )
            : IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () => _showRestrictDialog(user),
                tooltip: 'Restrict user',
              ),
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return Colors.orange;
      case 'club':
        return Colors.green;
      case 'student':
      default:
        return Colors.blue;
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'club':
        return Icons.groups;
      case 'student':
      default:
        return Icons.school;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
