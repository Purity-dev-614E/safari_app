import 'package:church_app/constants/api_constants.dart';
import 'package:church_app/screens/GroupMembers.dart';
import 'package:church_app/screens/Profile.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/eventService.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String groupName = 'Unknown Group';
  int numberOfMembers = 0;
  int numberOfUpcomingEvents = 0;
  String? adminUserId;
  String? groupId;
  bool isLoading = true;

  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);
  final EventService _eventService = EventService(baseUrl: ApiConstants.baseUrl);

  @override
  void initState() {
    super.initState();
    _fetchAdminUserId();
  }

  Future<void> _fetchAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminUserId = prefs.getString('user_id') ?? '';
    });
    if (adminUserId != null && adminUserId!.isNotEmpty) {
      _fetchAdminGroups();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAdminGroups() async {
    try {
      final groups = await _groupService.getAdminGroups(adminUserId!);
      if (groups.length == 1) {
        setState(() {
          groupId = groups[0]['id'] ?? '';
          groupName = groups[0]['name'] ?? 'Unknown Group';
        });
        _fetchDashboardData();
      } else {
        // Handle multiple groups or navigate to a selection screen
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch groups: $e',
        type: NotificationType.error,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    if (groupId == null || groupId!.isEmpty) return;

    try {
      List<dynamic> members = await _groupService.getGroupMembers(groupId!);
      Map<String, dynamic> groupDetails = await _groupService.getGroupById(groupId!);
      List<dynamic> events = await _eventService.getEventsByGroup(groupId!);

      setState(() {
        groupName = groupDetails['name'] ?? 'Unknown Group';
        numberOfMembers = members.length;
        numberOfUpcomingEvents = events.length;
        isLoading = false;
      });
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch dashboard data: $e',
        type: NotificationType.error,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard("Members", numberOfMembers.toString(), Icons.people_alt),
                      _buildSummaryCard("Upcoming Events", numberOfUpcomingEvents.toString(), Icons.event),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/createEvent');
                    },
                    icon: const Icon(Icons.event),
                    label: const Text("Add Events"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (groupId != null && groupId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: groupId!)),
            );
          }
        },
        child: const Icon(Icons.person_add_alt),
        backgroundColor: Colors.blueAccent,
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
          if (index == 0 && groupId != null && groupId!.isNotEmpty) {
            Navigator.pushNamed(context, "/GroupMembers", arguments: groupId);
          } else if (index == 1 && groupId != null && groupId!.isNotEmpty) {
            Navigator.pushNamed(context, "/GroupAnalytics", arguments: groupId);
          }
        },
        selectedItemColor: Colors.blueAccent,
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
            Icon(icon, size: 40, color: Colors.blueAccent),
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
}