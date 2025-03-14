import 'package:flutter/material.dart';
import 'package:church_app/services/eventService.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userServices.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _totalMembers = 0;
  String _nextEvent = "";
  List<dynamic> _upcomingEvents = [];
  bool _isLoading = true;

  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');
  final EventService _eventService = EventService(baseUrl: 'http://your-backend-url.com/api');
  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;

    try {
      // Check if user is in a group
      List<dynamic> groups = await _groupService.getAllGroups();
      bool isInGroup = false;
      String? userGroupId;

      for (var group in groups) {
        List<dynamic> members = await _groupService.getGroupMembers(group['id']);
        if (members.any((member) => member['id'] == userId)) {
          isInGroup = true;
          userGroupId = group['id'];
          _totalMembers = members.length;
          break;
        }
      }

      // Fetch upcoming events
      List<dynamic> events;
      if (isInGroup && userGroupId != null) {
        events = await _eventService.getEventsByGroup(userGroupId);
      } else {
        events = await _eventService.getAllEvents();
        List<dynamic> users = await _userService.getAllUsers();
        _totalMembers = users.length;
      }

      setState(() {
        _upcomingEvents = events;
        if (events.isNotEmpty) {
          _nextEvent = events[0]['name'];
        }
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/Profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Total Members", _totalMembers.toString()),
                _buildSummaryCard("Next Event", _nextEvent),
              ],
            ),

            const SizedBox(height: 20),

            // Upcoming Events List
            Expanded(
              child: ListView.builder(
                itemCount: _upcomingEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(
                    _upcomingEvents[index]['name'],
                    _upcomingEvents[index]['date'],
                    _upcomingEvents[index]['location'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary Card Widget
  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Event Card Widget
  Widget _buildEventCard(String eventName, String dateTime, String location) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$dateTime • $location"),
        leading: const Icon(Icons.event, color: Colors.blue),
      ),
    );
  }
}