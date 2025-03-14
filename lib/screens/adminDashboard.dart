import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/eventService.dart';
import 'package:church_app/services/userServices.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String groupName = '';
  int numberOfMembers = 0;
  int numberOfUpcomingEvents = 0;
  String? adminUserId;

  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');
  final EventService _eventService = EventService(baseUrl: 'http://your-backend-url.com/api');
  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');

  @override
  void initState() {
    super.initState();
    _fetchAdminUserId();
    _promptForGroupName();
  }

  Future<void> _fetchAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminUserId = prefs.getString('user_id');
    });
  }

  Future<String?> _fetchGroupId(String groupName) async {
    try {
      List<dynamic> groups = await _groupService.getAllGroups();
      for (var group in groups) {
        if (group['name'] == groupName && await _isAdminOfGroup(group['id'])) {
          return group['id'];
        }
      }
    } catch (e) {
      print('Failed to fetch group ID: $e');
    }
    return null;
  }

  Future<bool> _isAdminOfGroup(String groupId) async {
    if (adminUserId == null) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(adminUserId!);
      return userDetails['role'] == 'admin';
    } catch (e) {
      print('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _promptForGroupName() async {
    String? enteredGroupName = await _showGroupNameDialog();
    if (enteredGroupName != null) {
      _fetchDashboardData(enteredGroupName);
    }
  }

  Future<String?> _showGroupNameDialog() async {
    String? groupName;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
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
                Navigator.of(context).pop(groupName);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchDashboardData(String groupName) async {
    String? groupId = await _fetchGroupId(groupName);
    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are not an admin of this group')),
      );
      return;
    }

    try {
      List<dynamic> members = await _groupService.getGroupMembers(groupId);
      Map<String, dynamic> groupDetails = await _groupService.getGroupById(groupId);
      List<dynamic> events = await _eventService.getEventsByGroup(groupId);

      setState(() {
        this.groupName = groupDetails['name'];
        numberOfMembers = members.length;
        numberOfUpcomingEvents = events.length;
      });
    } catch (e) {
      print('Failed to fetch dashboard data: $e');
    }
  }

  Future<void> _addMember(String memberId) async {
    String? groupId = await _fetchGroupId(groupName);
    if (groupId == null) return;

    try {
      await _groupService.addGroupMember(groupId, memberId);
      _fetchDashboardData(groupName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add member')),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Name Header
            Text(
              groupName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Members", numberOfMembers.toString(), Icons.people_alt),
                _buildSummaryCard("Upcoming Events", numberOfUpcomingEvents.toString(), Icons.event),
              ],
            ),

            // Quick Actions
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add members screen (form)
                _addMember('newMemberId'); // Replace 'newMemberId' with actual member ID
              },
              icon: Icon(Icons.person_add_alt_1),
              label: const Text("Add Member"),
            ),
          ],
        ),
      ),
      // Floating ActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add member Screen
          _addMember('newMemberId'); // Replace 'newMemberId' with actual member ID
        },
        child: const Icon(Icons.person_add_alt_1),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: "Members",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
        onTap: (index) {
          // Handle Navigation
          if (index == 0) {
            Navigator.pushNamed(context, "/GroupMembers");
          } else if (index == 1) {
            Navigator.pushNamed(context, "/GroupAnalytics");
          }
        },
      ),
    );
  }
}