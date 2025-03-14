import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:church_app/services/analyticsService.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');
  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');
  final AnalyticsService _analyticsService = AnalyticsService(baseUrl: 'http://your-backend-url.com/api');

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
      print('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _fetchDashboardData() async {
    if (!await _isSuperAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to view this page')),
      );
      return;
    }

    try {
      List<dynamic> users = await _userService.getAllUsers();
      List<dynamic> groups = await _groupService.getAllGroups();
      // Fetch analytics data
      String groupName = await _promptForGroupName(); // Prompt for group name
      String? groupId = await _fetchGroupId(groupName); // Fetch group ID
      if (groupId != null) {
        Map<String, dynamic>? analytics = (await _analyticsService.getGroupMembers(groupId)) as Map<String, dynamic>?;

        setState(() {
          _totalUsers = users.length;
          _totalGroups = groups.length;
          _analytics = analytics;
        });
      }
    } catch (e) {
      print('Failed to fetch dashboard data: $e');
    }
  }

  Future<String?> _fetchGroupId(String groupName) async {
    try {
      List<dynamic> groups = await _groupService.getAllGroups();
      for (var group in groups) {
        if (group['name'] == groupName) {
          return group['id'];
        }
      }
    } catch (e) {
      print('Failed to fetch group ID: $e');
    }
    return null;
  }

  Future<String> _promptForGroupName() async {
    String groupName = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Group Name'),
          content: TextField(
            onChanged: (value) {
              groupName = value;
            },
            decoration: InputDecoration(hintText: "Group Name"),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return groupName;
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(letterSpacing: 2.0),
        ),
        actions: [
          IconButton(
            onPressed: _fetchDashboardData, // Trigger data refresh
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/SuperSettings');
            }, // Navigate to the settings screen
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.person,
                      label: "Total Users",
                      value: _totalUsers.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.group,
                      label: "Total Groups",
                      value: _totalGroups.toString(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    label: "Create Group",
                    icon: Icons.add,
                    onPressed: ()
                    {
                      _promptForGroupName();
                    }, // Navigate to create group form
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    _analytics != null ? "Attendance Trends: ${_analytics!['attendance_trends']}" : "Loading...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    _analytics != null ? "Group Statistics: ${_analytics!['group_statistics']}" : "Loading...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/UserManagement');
              }, // Navigate to User Management screen
              icon: Icon(Icons.people_outlined),
              label: const Text("User Management"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, "/SuperAnalytics");
              }, // Navigate to Analytics screen
              icon: Icon(Icons.analytics),
              label: const Text("Analytics"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}