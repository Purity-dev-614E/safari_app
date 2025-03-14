import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperSettings extends StatefulWidget {
  const SuperSettings({super.key});

  @override
  State<SuperSettings> createState() => _SuperSettingsState();
}

class _SuperSettingsState extends State<SuperSettings> {
  List<dynamic> groups = [];
  bool allowProfileEdits = true;
  String? superAdminUserId;

  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');
  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUserId();
    _fetchGroups();
  }

  Future<void> _fetchSuperAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      superAdminUserId = prefs.getString('user_id');
    });
  }

  Future<bool> _isSuperAdmin() async {
    if (superAdminUserId == null) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(superAdminUserId!);
      return userDetails['role'] == 'super_admin';
    } catch (e) {
      print('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _fetchGroups() async {
    if (!await _isSuperAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to view this page')),
      );
      return;
    }

    try {
      List<dynamic> groupData = await _groupService.getAllGroups();
      setState(() {
        groups = groupData;
      });
    } catch (e) {
      print('Failed to fetch groups: $e');
    }
  }

  Future<void> _createGroup(String groupName) async {
    if (!await _isSuperAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to create groups')),
      );
      return;
    }

    try {
      await _groupService.createGroup({'name': groupName});
      _fetchGroups();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group')),
      );
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    if (!await _isSuperAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to delete groups')),
      );
      return;
    }

    try {
      await _groupService.deleteGroup(groupId);
      _fetchGroups();
    } catch (e) {
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

  Future<void> _toggleProfileEdits(bool value) async {
    if (!await _isSuperAdmin()) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('You do not have permission to change this setting')),
    );
    return;
    }

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