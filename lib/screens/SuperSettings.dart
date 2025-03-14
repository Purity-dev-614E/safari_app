import 'package:flutter/material.dart';
import 'package:church_app/services/super_services.dart';

class Supersettings extends StatefulWidget {
  const Supersettings({super.key});

  @override
  State<Supersettings> createState() => _SupersettingsState();
}

class _SupersettingsState extends State<Supersettings> {
  List<dynamic> groups = [];
  bool allowProfileEdits = true;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    List<dynamic> groupData = await AdminServices.getAllGroups();
    setState(() {
      groups = groupData;
    });
  }

  Future<void> _createGroup(String groupName) async {
    bool success = await AdminServices.createGroup(groupName);
    if (success) {
      _fetchGroups();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group')),
      );
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    bool success = await AdminServices.deleteGroup(groupId);
    if (success) {
      _fetchGroups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete group')),
      );
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Group"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter Group Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _createGroup(controller.text);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteGroupDialog(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete $groupName"),
        content: const Text("Are you sure you want to delete this group?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteGroup(groupId);
              Navigator.pop(context);
            },
            child: Text(
              "Delete Group",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleProfileEdits(bool value) {
    setState(() {
      allowProfileEdits = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          // Group management section
          ListTile(
            title: const Text(
              "Group Management",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 8.0),
          // List of groups with delete action
          ...groups.map((group) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: ListTile(
                title: Text(group['name']),
                trailing: IconButton(
                  onPressed: () => _showDeleteGroupDialog(group['id'], group['name']),
                  icon: Icon(Icons.delete, color: Colors.red),
                ),
              ),
            );
          }).toList(),
          const Divider(height: 32),
          // App permissions section
          SwitchListTile(
            title: const Text(
              "Profile Edits",
              style: TextStyle(fontSize: 16.0),
            ),
            value: allowProfileEdits,
            onChanged: _toggleProfileEdits,
          ),
        ],
      ),
    );
  }
}