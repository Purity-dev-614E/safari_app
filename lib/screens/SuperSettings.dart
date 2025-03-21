import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'adminEventList.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

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
  bool isRefreshing = false;

  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);
  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);

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
      return userDetails['role'] == 'super admin';
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch user details: $e',
        type: NotificationType.error,
      );
      return false;
    }
  }

  Future<void> _fetchGroups() async {
    if (!await _isSuperAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to view this page',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      List<dynamic> groupData = await _groupService.getAllGroups();
      setState(() {
        groups = groupData ?? [];
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch groups: $e',
        type: NotificationType.error,
      );
    }
  }

  // Future<void>getAdminName(String name) async {
  //   SharedPreferences prefs =  await SharedPreferences.getInstance();
  //
  // }

  Future<void> _createGroup(String groupName) async {
    if (!await _isSuperAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to create groups',
        type: NotificationType.error,
      );
      return;
    }

    try {
      await _groupService.createGroup({'name': groupName});
      await _fetchGroups();
      Navigator.pop(context);
      NotificationOverlay.of(context).showNotification(
        message: 'Group created successfully',
        type: NotificationType.success,
      );
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to create group: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    if (!await _isSuperAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to delete groups',
        type: NotificationType.error,
      );
      return;
    }

    try {
      await _groupService.deleteGroup(groupId);
      await _fetchGroups();
      Navigator.pop(context);
      NotificationOverlay.of(context).showNotification(
        message: 'Group deleted successfully',
        type: NotificationType.success,
      );
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to delete group: $e',
        type: NotificationType.error,
      );
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.group_add,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Create Group",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter Group Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _createGroup(controller.text);
                } else {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Group name cannot be empty',
                    type: NotificationType.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Delete $groupName",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text("Are you sure you want to delete this group? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteGroup(groupId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete Group"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProfileEdits(bool value) async {
    if (!await _isSuperAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to change this setting',
        type: NotificationType.error,
      );
      return;
    }

    try {
      // TODO: Implement API call to update profile edit settings
      setState(() {
        allowProfileEdits = value;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Profile edit settings updated',
        type: NotificationType.success,
      );
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to update profile edit settings: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _showAssignAdminDialog(String groupId, String currentAdminName) async {
    final TextEditingController fullnameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Assign Admin to Group',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentAdminName != 'None')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Admin: $currentAdminName',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: fullnameController,
                decoration: InputDecoration(
                  hintText: "Enter admin's Name",
                  labelText: "Admin's Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.blue.shade700),
              ),
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
                  
                  await _groupService.assignAdminToGroup(groupId, user['id']);
                  Navigator.pop(context);
                  await _fetchGroups();
                  NotificationOverlay.of(context).showNotification(
                    message: 'Admin assigned successfully',
                    type: NotificationType.success,
                  );
                } catch (e) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Failed to assign admin: $e',
                    type: NotificationType.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Super Admin Settings",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : _fetchGroups,
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: Colors.blue.shade700,
                  ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading settings...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchGroups,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Management Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Group Management',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showCreateGroupDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Group'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...groups.map((group) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.blue.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  group['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Admin: ${group['group_admin_id'] ?? 'None'}',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      icon: Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.blue.shade700,
                                      ),
                                      onPressed: () => _showAssignAdminDialog(
                                        group['id'] ?? '',
                                        group['admin_name'] ?? 'None',
                                      ),
                                      tooltip: 'Assign Admin',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade700,
                                      ),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // System Settings Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'System Settings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: Text(
                                'Allow Profile Edits',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Enable or disable user profile editing',
                                style: TextStyle(
                                  color: Colors.blue.shade700.withOpacity(0.7),
                                ),
                              ),
                              value: allowProfileEdits,
                              onChanged: _toggleProfileEdits,
                              activeColor: Colors.blue.shade700,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}