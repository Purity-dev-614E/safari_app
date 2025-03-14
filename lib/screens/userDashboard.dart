import 'package:flutter/material.dart';
import 'package:church_app/services/user_services.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _totalMembers = 0;
  String _nextEvent = "";
  List<dynamic> _upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Fetch total number of group members
    List<dynamic> groups = await UserServices.getUserGroups();
    setState(() {
      _totalMembers = groups.length;
    });

    // Fetch upcoming events
    List<dynamic> events = await UserServices.getEvents();
    setState(() {
      _upcomingEvents = events;
      if (events.isNotEmpty) {
        _nextEvent = events[0]['name'];
      }
    });
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
      body: Padding(
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