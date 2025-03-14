import 'package:flutter/material.dart';
import 'package:church_app/services/admin_services.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String groupName = '';
  int numberOfMembers = 0;
  int numberOfUpcomingEvents = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Fetch group name and members
    List<dynamic> members = await AdminServices.getGroupMembers('groupId'); // Replace 'groupId' with actual group ID
    Map<String, dynamic> groupDetails = await AdminServices.getGroupDetails('groupId'); // Replace 'groupId' with actual group ID
    List<dynamic> events = await AdminServices.getUpcomingEvents('groupId'); // Replace 'groupId' with actual group ID

    setState(() {
      groupName = groupDetails['name'];
      numberOfMembers = members.length;
      numberOfUpcomingEvents = events.length;
    });
  }

  Future<void> _addMember(String memberId) async {
    bool success = await AdminServices.addMemberToGroup('groupId', memberId); // Replace 'groupId' with actual group ID
    if (success) {
      _fetchDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member added successfully')),
      );
    } else {
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