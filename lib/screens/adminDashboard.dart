import 'package:church_app/screens/GroupMembers.dart';
import 'package:church_app/screens/Profile.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/eventService.dart';
import 'package:church_app/services/userServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';

// Ensure this import is correct

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
  String? groupId;

  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final EventService _eventService = EventService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');

  @override
  void initState() {
    super.initState();
    _fetchAdminUserId();
    _initializeGroupId();
  }

  Future<void> _fetchAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminUserId = prefs.getString('user_id');
    });
  }

  Future<void> _initializeGroupId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGroupId = prefs.getString('group_id');

    if (savedGroupId == null) {
      String groupName = await _promptForGroupName();
      String fetchedGroupId = await _fetchGroupIdByName(groupName);
      await prefs.setString('group_id', fetchedGroupId);
      setState(() {
        groupId = fetchedGroupId;
      });
    } else {
      setState(() {
        groupId = savedGroupId;
      });
    }

    _fetchDashboardData();
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

  Future<String> _fetchGroupIdByName(String groupName) async {
    try {
      final group = await _groupService.getGroupByName(groupName);
      
      // Check if the current user is an admin of this group
      if (adminUserId == null) {
        throw Exception('Admin user ID not found');
      }
      
      // Check if the current user is in the admins list
      List<dynamic> admins = group['admins'] ?? [];
      bool isAdmin = admins.any((admin) => admin['id'] == adminUserId);
      
      if (!isAdmin) {
        throw Exception('You are not an admin of this group');
      }
      
      return group['id'];
    } catch (e) {
      // Show error notification
      NotificationOverlay.of(context).showNotification(
        message: e.toString().contains('not an admin') 
          ? 'You are not an admin of this group. Please enter a group where you are an admin.'
          : 'Failed to fetch group: ${e.toString()}',
        type: NotificationType.error,
      );
      throw e;
    }
  }

  Future<void> _fetchDashboardData() async {
    if (groupId == null || groupId!.isEmpty) return;

    try {
      List<dynamic> members = await _groupService.getGroupMembers(groupId!);
      Map<String, dynamic> groupDetails = await _groupService.getGroupById(groupId!);
      List<dynamic> events = await _eventService.getEventsByGroup(groupId!);

      setState(() {
        groupName = groupDetails['name'];
        numberOfMembers = members.length;
        numberOfUpcomingEvents = events.length;
      });
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch dashboard data: $e',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Members", numberOfMembers.toString(), Icons.people_alt),
                _buildSummaryCard("Upcoming Events", numberOfUpcomingEvents.toString(), Icons.event),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add members screen (form)
                Navigator.pushReplacementNamed(context, '/createEvent');
                _addMember('newMemberId'); // Replace 'newMemberId' with actual member ID
              },
              icon: Icon(Icons.event),
              label: const Text("Add Events"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: groupId!)),
          );
        },
        child: const Icon(Icons.person_add_alt),
      ),
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
            Navigator.pushNamed(context, "/GroupMembers", arguments: groupId);
          } else if (index == 1) {
            Navigator.pushNamed(context, "/GroupAnalytics", arguments: groupId);
          }
        },
      ),
    );
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

  Future<void> _addMember(String memberId) async {
    try {
      await _groupService.addGroupMember(groupId!, memberId);
      _fetchDashboardData();
      NotificationOverlay.of(context).showNotification(
        message: 'Member added successfully',
        type: NotificationType.success,
      );
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to add member: $e',
        type: NotificationType.error,
      );
    }
  }
}