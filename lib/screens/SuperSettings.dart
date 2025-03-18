import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminEventList.dart';

class SuperSettings extends StatefulWidget {
  const SuperSettings({super.key});

  @override
  State<SuperSettings> createState() => _SuperSettingsState();
}

class _SuperSettingsState extends State<SuperSettings> {
  List<dynamic> groups = [];
  bool allowProfileEdits = true;
  String? superAdminUserId;
  bool isLoading = true;

  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');

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
      _showError('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _fetchGroups() async {
    if (!await _isSuperAdmin()) {
      _showError('You do not have permission to view this page');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });
      List<dynamic> groupData = await _groupService.getAllGroups();
      setState(() {
        groups = groupData ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Failed to fetch groups: $e');
    }
  }

  Future<void> _createGroup(String groupName) async {
    if (!await _isSuperAdmin()) {
      _showError('You do not have permission to create groups');
      return;
    }

    try {
      await _groupService.createGroup({'name': groupName});
      await _fetchGroups();
      Navigator.pop(context);
      _showSuccess('Group created successfully');
    } catch (e) {
      _showError('Failed to create group: $e');
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    if (!await _isSuperAdmin()) {
      _showError('You do not have permission to delete groups');
      return;
    }

    try {
      await _groupService.deleteGroup(groupId);
      await _fetchGroups();
      Navigator.pop(context);
      _showSuccess('Group deleted successfully');
    } catch (e) {
      _showError('Failed to delete group: $e');
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
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _createGroup(controller.text);
                } else {
                  _showError('Group name cannot be empty');
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
        content: const Text("Are you sure you want to delete this group? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteGroup(groupId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete Group"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProfileEdits(bool value) async {
    if (!await _isSuperAdmin()) {
      _showError('You do not have permission to change this setting');
      return;
    }

    try {
      // TODO: Implement API call to update profile edit settings
      setState(() {
        allowProfileEdits = value;
      });
      _showSuccess('Profile edit settings updated');
    } catch (e) {
      _showError('Failed to update profile edit settings: $e');
    }
  }

  Future<void> _showAssignAdminDialog(String groupId, String currentAdminName) async {
    final TextEditingController fullnameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assign Admin to Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentAdminName != 'None')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Current Admin: $currentAdminName',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              TextField(
                controller: fullnameController,
                decoration: const InputDecoration(
                  hintText: "Enter admin's email",
                  labelText: "Admin's Email",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final users = await _userService.searchUsersByName(fullnameController.text);
                  if (users.isEmpty) {
                    throw Exception('No user found with that email');
                  }
                  
                  final user = users[0];
                  if (user['role'] != 'admin') {
                    throw Exception('Selected user is not an admin');
                  }
                  
                  await _userService.assignAdminToGroup(groupId, user['id']);
                  Navigator.pop(context);
                  await _fetchGroups();
                  _showSuccess('Admin assigned successfully');
                } catch (e) {
                  _showError('Failed to assign admin: $e');
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGroups,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Management Section
                  Text(
                    'Group Management',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Group'),
                  ),
                  const SizedBox(height: 16),
                  ...groups.map((group) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(group['name'] ?? ''),
                      subtitle: Text('Admin: ${group['admin_name'] ?? 'None'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminEventList(groupId: group['id'] ?? ''),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.admin_panel_settings),
                            onPressed: () => _showAssignAdminDialog(
                              group['id'] ?? '',
                              group['admin_name'] ?? 'None',
                            ),
                            tooltip: 'Assign Admin',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteGroupDialog(
                              group['id'] ?? '',
                              group['name'] ?? '',
                            ),
                            tooltip: 'Delete Group',
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                  
                  // System Settings Section
                  Text(
                    'System Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Allow Profile Edits'),
                    subtitle: const Text('Enable or disable user profile editing'),
                    value: allowProfileEdits,
                    onChanged: _toggleProfileEdits,
                  ),
                ],
              ),
            ),
    );
  }
}