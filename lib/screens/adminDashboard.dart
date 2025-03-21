import 'package:church_app/constants/api_constants.dart';
import 'package:church_app/screens/AddMembers.dart';
import 'package:church_app/screens/GroupMembers.dart';
import 'package:church_app/screens/Profile.dart';
import 'package:church_app/screens/eventDetails.dart';
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

  Future<void> _fetchEventsByGroup() async {
    if (groupId == null || groupId!.isEmpty) return;

    try {
      List<dynamic> events = await _eventService.getEventsByGroup(groupId!);
      setState(() {
        numberOfUpcomingEvents = events.length;
      });
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch events: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _fetchAdminGroups() async {
    if (adminUserId == null || adminUserId!.isEmpty) {
      print('Admin User ID is null or empty');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final groups = await _groupService.getAdminGroups(adminUserId!) ?? [];
      print('Admin User ID: $adminUserId');
      print('Retrieved Groups: $groups');

      if (groups.isEmpty) {
        throw Exception('No groups found for the admin user');
      }

      // Since admin can only be assigned to one group, we take the first group
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('group_id', groups[0]['id'] ?? '');

      setState(() {
        groupId = groups[0]['id'] ?? '';
        groupName = groups[0]['name'] ?? 'Unknown Group';
      });
      print('Group ID: $groupId');
      print('Group Name: $groupName');
      _fetchDashboardData();
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
        title: const Text("Admin Dashboard"),
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
                      Expanded(child: _buildSummaryCard("Members", numberOfMembers.toString(), Icons.people_alt)),
                      Expanded(child: _buildSummaryCard("Upcoming Events", numberOfUpcomingEvents.toString(), Icons.event)),
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
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          backgroundColor: Colors.blue[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    "Events coming up",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _eventService.getEventsByGroup(groupId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No upcoming events'));
                        } else {
                          final events = snapshot.data!;
                          return ListView.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              return Card(
                                color: Colors.blue[50],
                                child: ListTile(
                                  leading: Icon(Icons.event, color: Colors.blueAccent),
                                  title: Text(
                                    events[index]['title'],
                                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(events[index]['location']),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetails(event: events[index]),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
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