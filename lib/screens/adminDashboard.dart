import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/eventService.dart';
import 'package:church_app/services/userServices.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adminEventList.dart';

class AdminDashboard extends StatefulWidget {
  final String groupId;

  const AdminDashboard({super.key, required this.groupId});

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
    _fetchDashboardData();
  }

  Future<void> _fetchAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminUserId = prefs.getString('user_id');
    });
  }

  Future<void> _fetchDashboardData() async {
    if (widget.groupId.isEmpty) return;

    try {
      List<dynamic> members = await _groupService.getGroupMembers(widget.groupId);
      Map<String, dynamic> groupDetails = await _groupService.getGroupById(widget.groupId);
      List<dynamic> events = await _eventService.getEventsByGroup(widget.groupId);

      setState(() {
        groupName = groupDetails['name'];
        numberOfMembers = members.length;
        numberOfUpcomingEvents = events.length;
      });
    } catch (e) {
      print('Failed to fetch dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
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
                _addMember('newMemberId'); // Replace 'newMemberId' with actual member ID
              },
              icon: Icon(Icons.person_add_alt_1),
              label: const Text("Add Member"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminEventList(groupId: 'yourGroupId'), // Replace 'yourGroupId' with actual group ID
            ),
          );
        },
        child: const Icon(Icons.event),
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
            Navigator.pushNamed(context, "/GroupMembers", arguments: widget.groupId);
          } else if (index == 1) {
            Navigator.pushNamed(context, "/GroupAnalytics", arguments: widget.groupId);
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
      await _groupService.addGroupMember(widget.groupId, memberId);
      _fetchDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add member')),
      );
    }
  }
}