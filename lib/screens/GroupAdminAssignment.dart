import 'package:flutter/material.dart';
import '../services/userServices.dart';
import '../services/groupServices.dart';

class GroupAdminAssignment extends StatefulWidget {
  final UserService userService;
  final GroupService groupService;

  const GroupAdminAssignment({
    Key? key,
    required this.userService,
    required this.groupService,
  }) : super(key: key);

  @override
  _GroupAdminAssignmentState createState() => _GroupAdminAssignmentState();
}

class _GroupAdminAssignmentState extends State<GroupAdminAssignment> {
  List<dynamic> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      setState(() => isLoading = true);
      final fetchedGroups = await widget.groupService.getAllGroups();
      setState(() {
        groups = fetchedGroups;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch groups: $e')),
      );
    }
  }

  Future<void> _showAssignAdminDialog(String groupId) async {
    final TextEditingController nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assign Admin to Group'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Enter admin's name",
              labelText: "Admin's Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // First search for the user by name
                  final users = await widget.userService.searchUsersByName(nameController.text);
                  if (users.isEmpty) {
                    throw Exception('No user found with that name');
                  }
                  
                  // Assign the first matching user as admin
                  await widget.userService.assignAdminToGroup(groupId, users[0]['id']);
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin assigned successfully')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to assign admin: $e')),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Group Admins'),
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return ListTile(
            title: Text(group['name']),
            subtitle: Text('Current Admin: ${group['admin_name'] ?? 'None'}'),
            trailing: IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => _showAssignAdminDialog(group['id']),
            ),
          );
        },
      ),
    );
  }
} 