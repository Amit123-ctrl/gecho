import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/registration_service.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> with SingleTickerProviderStateMixin {
  final RegistrationService _registrationService = RegistrationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Clean up expired requests when screen loads
    _registrationService.cleanupExpiredRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteExpiredRequests() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final expiredRequests = await FirebaseFirestore.instance
          .collection('registration_requests')
          .where('status', isEqualTo: 'expired')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in expiredRequests.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deleted ${expiredRequests.docs.length} expired requests'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  Future<void> _deleteRejectedRequests() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final rejectedRequests = await FirebaseFirestore.instance
          .collection('registration_requests')
          .where('status', isEqualTo: 'rejected')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in rejectedRequests.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deleted ${rejectedRequests.docs.length} rejected requests'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  Future<void> _approveRequest(String email, Map<String, dynamic> data) async {
    try {
      await _registrationService.approveRegistrationRequest(email, 'admin@gla.ac.in');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Approved ${data['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String email, Map<String, dynamic> data) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${data['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this request?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Please provide a reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _registrationService.rejectRegistrationRequest(email, 'admin@gla.ac.in', result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Rejected ${data['name']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showRequestDetails(String email, Map<String, dynamic> data) {
    final submittedAt = (data['submittedAt'] as Timestamp).toDate();
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final timeLeft = expiresAt.difference(DateTime.now());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: data['userType'] == 'student' 
                  ? Colors.green.shade100 
                  : Colors.blue.shade100,
              child: Icon(
                data['userType'] == 'student' ? Icons.school : Icons.group,
                color: data['userType'] == 'student' 
                    ? Colors.green.shade600 
                    : Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Unknown'),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Account Type', data['userType']?.toString().toUpperCase() ?? 'N/A'),
              
              if (data['userType'] == 'student') ...[
                _buildDetailRow('Student ID', data['studentId'] ?? 'N/A'),
                _buildDetailRow('Department', data['department'] ?? 'N/A'),
              ] else ...[
                _buildDetailRow('Club Name', data['clubName'] ?? 'N/A'),
                _buildDetailRow('Club Type', data['clubType'] ?? 'N/A'),
              ],
              
              _buildDetailRow('Reason', data['reason'] ?? 'No reason provided'),
              _buildDetailRow('Submitted', _formatDateTime(submittedAt)),
              _buildDetailRow('Expires', _formatDateTime(expiresAt)),
              _buildDetailRow('Time Left', '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m'),
              
              if (timeLeft.inHours < 24) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Expires soon!',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectRequest(email, data);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _approveRequest(email, data);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRequestCard(String email, Map<String, dynamic> data, {required bool isExpired, bool isRejected = false}) {
    final submittedAt = (data['submittedAt'] as Timestamp).toDate();
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    final timeLeft = expiresAt != null ? expiresAt.difference(DateTime.now()) : Duration.zero;
    final isExpiringSoon = !isExpired && !isRejected && expiresAt != null && timeLeft.inHours < 24 && timeLeft.inHours > 0;

    return Opacity(
      opacity: (isExpired || isRejected) ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: InkWell(
          onTap: (isExpired || isRejected) ? null : () => _showRequestDetails(email, data),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: data['userType'] == 'student' 
                          ? Colors.green.shade100 
                          : Colors.blue.shade100,
                      child: Icon(
                        data['userType'] == 'student' ? Icons.school : Icons.group,
                        color: data['userType'] == 'student' 
                            ? Colors.green.shade600 
                            : Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: (isExpired || isRejected) ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '❌ EXPIRED',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else if (isRejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🚫 REJECTED',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else if (isExpiringSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⚠️ ${timeLeft.inHours}h left',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Quick info
                Row(
                  children: [
                    Chip(
                      label: Text(
                        data['userType']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: data['userType'] == 'student' 
                          ? Colors.green.shade100 
                          : Colors.blue.shade100,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['userType'] == 'student' 
                          ? 'ID: ${data['studentId'] ?? 'N/A'}'
                          : data['clubName'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                
                // Rejection reason (if rejected)
                if (isRejected && data['rejectionReason'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['rejectionReason'],
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                          ),
                        ),
                        if (data['reviewedBy'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Rejected by: ${data['reviewedBy']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (data['reviewedAt'] != null) ...[
                          Text(
                            'On: ${_formatDateTime((data['reviewedAt'] as Timestamp).toDate())}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                if (!isExpired && !isRejected) ...[
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveRequest(email, data),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectRequest(email, data),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Requests'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Active'),
            Tab(icon: Icon(Icons.block), text: 'Rejected'),
            Tab(icon: Icon(Icons.history), text: 'Expired'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Universal search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveRequestsTab(),
                _buildRejectedRequestsTab(),
                _buildExpiredRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _registrationService.getPendingRegistrationRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];
        
        // Filter requests based on search query
        final filteredRequests = requests.where((doc) {
          if (_searchQuery.isEmpty) return true;
          
          final data = doc.data() as Map<String, dynamic>;
          final email = doc.id.toLowerCase();
          final name = (data['name'] as String?)?.toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          
          return email.contains(query) || name.contains(query);
        }).toList();
        
        // Sort requests by submittedAt on client side (newest first)
        filteredRequests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (bData['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });
        
        final limitedRequests = filteredRequests.take(20).toList();

        return Column(
          children: [
            // Header with count
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Text(
                    '${limitedRequests.length} Active Request${limitedRequests.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            
            // Requests list
            Expanded(
              child: limitedRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.inbox : Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No active requests' : 'No results found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: limitedRequests.length,
                      itemBuilder: (context, index) {
                        final doc = limitedRequests[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final email = doc.id;
                        
                        return _buildRequestCard(email, data, isExpired: false);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRejectedRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _registrationService.getAllRegistrationRequests(status: 'rejected'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];
        
        // Filter requests based on search query
        final filteredRequests = requests.where((doc) {
          if (_searchQuery.isEmpty) return true;
          
          final data = doc.data() as Map<String, dynamic>;
          final email = doc.id.toLowerCase();
          final name = (data['name'] as String?)?.toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          
          return email.contains(query) || name.contains(query);
        }).toList();

        return Column(
          children: [
            // Header with delete button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Text(
                    '${filteredRequests.length} Rejected Request${filteredRequests.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (requests.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isDeleting ? null : _deleteRejectedRequests,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Delete All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ),
            
            // Rejected requests list
            Expanded(
              child: filteredRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.check_circle_outline : Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No rejected requests' : 'No results found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        final doc = filteredRequests[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final email = doc.id;
                        
                        return _buildRequestCard(email, data, isExpired: false, isRejected: true);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpiredRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _registrationService.getAllRegistrationRequests(status: 'expired'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];
        
        // Filter requests based on search query
        final filteredRequests = requests.where((doc) {
          if (_searchQuery.isEmpty) return true;
          
          final data = doc.data() as Map<String, dynamic>;
          final email = doc.id.toLowerCase();
          final name = (data['name'] as String?)?.toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          
          return email.contains(query) || name.contains(query);
        }).toList();

        return Column(
          children: [
            // Header with delete button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Text(
                    '${filteredRequests.length} Expired Request${filteredRequests.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (requests.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isDeleting ? null : _deleteExpiredRequests,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Delete All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ),
            
            // Expired requests list
            Expanded(
              child: filteredRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.check_circle_outline : Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No expired requests' : 'No results found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        final doc = filteredRequests[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final email = doc.id;
                        
                        return _buildRequestCard(email, data, isExpired: true);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}