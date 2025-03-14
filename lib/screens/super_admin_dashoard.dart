import 'package:flutter/material.dart';
import 'package:church_app/services/super_services.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _totalUsers = 0;
  int _totalGroups = 0;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    List<dynamic> users = await AdminServices.getAllUsers();
    List<dynamic> groups = await AdminServices.getAllGroups();
    Map<String, dynamic>? analytics = await AdminServices.getAnalytics();

    setState(() {
      _totalUsers = users.length;
      _totalGroups = groups.length;
      _analytics = analytics;
    });
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/CreateGroup');
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


class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _groupName;

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      bool success = await AdminServices.createGroup(_groupName!);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Group Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter group name';
                  }
                  return null;
                },
                onSaved: (value) => _groupName = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createGroup,
                child: const Text("Create Group"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
