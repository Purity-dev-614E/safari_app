import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:church_app/services/analyticsService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _totalUsers = 0;
  int _totalGroups = 0;
  Map<String, dynamic>? _analytics;
  String? superAdminUserId;
  bool _isLoading = true;
  bool _isRefreshing = false;

  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');
  final AnalyticsService _analyticsService = AnalyticsService(baseUrl: 'https://safari-backend.on.shiper.app/api');

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUserId();
  }

  Future<void> _fetchSuperAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      superAdminUserId = prefs.getString('user_id');
    });
    _fetchDashboardData();
  }

  Future<bool> _isSuperAdmin() async {
    if (superAdminUserId == null) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(superAdminUserId!);
      return userDetails['role'] == 'super_admin';
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch user details: $e',
        type: NotificationType.error,
      );
      return false;
    }
  }

  Future<void> _fetchDashboardData() async {
    if (!await _isSuperAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to view this page',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      List<dynamic> users = await _userService.getAllUsers();
      List<dynamic> groups = await _groupService.getAllGroups();
      // Map<String, dynamic> analytics = await _analyticsService.getAnalytics();
      
      setState(() {
        _totalUsers = users.length;
        _totalGroups = groups.length;
        // _analytics = analytics;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch dashboard data: $e',
        type: NotificationType.error,
      );
    }
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Super Admin Dashboard',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _fetchDashboardData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/Profile');
            },
            icon: Icon(
              Icons.account_circle,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              icon: Icons.person,
                              label: "Total Users",
                              value: _totalUsers.toString(),
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              icon: Icons.group,
                              label: "Total Groups",
                              value: _totalGroups.toString(),
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildAnalyticsCard(
                        title: 'Attendance Trends',
                        content: Center(
                          child: Text(
                            _analytics != null
                                ? "Attendance Trends: ${_analytics!['attendance_trends'] ?? 'No Data'}"
                                : "Loading...",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAnalyticsCard(
                        title: 'Group Statistics',
                        content: Center(
                          child: Text(
                            _analytics != null
                                ? "Group Statistics: ${_analytics!['group_statistics'] ?? 'No Data'}"
                                : "Loading...",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/UserManagement');
                break;
              case 1:
                Navigator.pushNamed(context, "/SuperSettings");
                break;
              case 2:
                Navigator.pushNamed(context, "/SuperAnalytics");
                break;
            }
          },
        ),
      ),
    );
  }
}