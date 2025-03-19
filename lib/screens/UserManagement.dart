import 'package:flutter/material.dart';
import 'package:church_app/services/userServices.dart';
import 'package:church_app/services/groupServices.dart';
import '../constants/api_constants.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

class User {
  final String id;
  final String full_name;
  final String email;
  final String role;
  final String group;

  User({
    required this.id,
    required this.full_name,
    required this.email,
    required this.role,
    required this.group,
  });
}

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  List<User> users = [];
  List<dynamic> groups = [];
  String searchQuery = '';
  bool _isLoading = true;

  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);
  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      List<dynamic> userData = await _userService.getAllUsers();
      List<dynamic> groupData = await _groupService.getAllGroups();
      setState(() {
        users = userData.map((data) => User(
          id: data['id'] ?? '',
          full_name: data['full_name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          group: data['group'] ?? '',
        )).toList();
        groups = groupData ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        NotificationOverlay.of(context).showNotification(
          message: 'Failed to fetch data: $e',
          type: NotificationType.error,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      return user.full_name.toLowerCase().contains(lowerCaseQuery) ||
          user.email.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  Future<void> _onDeleteUser(User user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text('Are you sure you want to delete ${user.full_name}?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.id);
        setState(() {
          users.remove(user);
        });
        if (mounted) {
          NotificationOverlay.of(context).showNotification(
            message: 'User ${user.full_name} deleted successfully',
            type: NotificationType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationOverlay.of(context).showNotification(
            message: 'Failed to delete user ${user.full_name}',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  Future<void> _onAssignGroup(User user, String newGroup) async {
    try {
      await _groupService.addGroupMember(newGroup, user.id);
      setState(() {
        int index = users.indexOf(user);
        users[index] = User(
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          role: user.role,
          group: newGroup,
        );
      });
      if (mounted) {
        NotificationOverlay.of(context).showNotification(
          message: '${user.full_name} assigned to $newGroup',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationOverlay.of(context).showNotification(
          message: 'Failed to assign ${user.full_name} to $newGroup',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _onUpdateRole(User user, String newRole) async {
    try {
      await _userService.updateUserRole(user.id, newRole);
      setState(() {
        int index = users.indexOf(user);
        users[index] = User(
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          role: newRole,
          group: user.group,
        );
      });
      if (mounted) {
        NotificationOverlay.of(context).showNotification(
          message: '${user.full_name}\'s role updated to $newRole',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationOverlay.of(context).showNotification(
          message: 'Failed to update role for ${user.full_name}',
          type: NotificationType.error,
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Management",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading users...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search by Name or Email",
                        prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        hintStyle: TextStyle(color: Colors.blue.shade300),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  // User List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        user.full_name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.full_name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          Text(
                                            user.email,
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.role,
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Role Update Dropdown
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: user.role.isNotEmpty ? user.role : null, // Ensure a valid value
                                          decoration: InputDecoration(
                                            labelText: 'Role',
                                            labelStyle: TextStyle(color: Colors.blue.shade700),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          items: ['super admin', 'admin', 'user']
                                              .map((role) => DropdownMenuItem(
                                            value: role,
                                            child: Text(
                                              role,
                                              style: TextStyle(color: Colors.blue.shade700),
                                            ),
                                          ))
                                              .toList(),
                                          onChanged: (newRole) {
                                            if (newRole != null) {
                                              _onUpdateRole(user, newRole);
                                            }
                                          },
                                        ),
                                      ),
                                    ),

                                    // Group Assignment Dropdown
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: user.group.isNotEmpty ? user.group : null, // Ensure a valid value
                                          decoration: InputDecoration(
                                            labelText: 'Group',
                                            labelStyle: TextStyle(color: Colors.blue.shade700),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          items: groups.map<DropdownMenuItem<String>>((group) {
                                            return DropdownMenuItem<String>(
                                              value: group['id'], // Ensure this is the correct ID
                                              child: Text(
                                                group['name'] ?? 'Unknown Group', // Handle missing name
                                                style: TextStyle(color: Colors.blue.shade700),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (newGroup) {
                                            if (newGroup != null) {
                                              _onAssignGroup(user, newGroup);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: IconButton(
                                        onPressed: () => _onDeleteUser(user),
                                        icon: Icon(Icons.delete, color: Colors.red.shade700),
                                        tooltip: 'Delete User',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}