import 'package:flutter/material.dart';
import 'package:church_app/services/userServices.dart';
import 'package:church_app/services/groupServices.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String group;

  User({
    required this.id,
    required this.name,
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

  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');

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
          name: data['full_name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          group: data['group'] ?? '',
        )).toList();
        groups = groupData ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(lowerCaseQuery) ||
          user.email.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  Future<void> _onDeleteUser(User user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
        _showSuccess('User ${user.name} deleted successfully');
      } catch (e) {
        _showError('Failed to delete user ${user.name}');
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
          name: user.name,
          email: user.email,
          role: user.role,
          group: newGroup,
        );
      });
      _showSuccess('${user.name} assigned to $newGroup');
    } catch (e) {
      _showError('Failed to assign ${user.name} to $newGroup');
    }
  }

  Future<void> _onUpdateRole(User user, String newRole) async {
    try {
      await _userService.updateUserRole(user.id, newRole);
      setState(() {
        int index = users.indexOf(user);
        users[index] = User(
          id: user.id,
          name: user.name,
          email: user.email,
          role: newRole,
          group: user.group,
        );
      });
      _showSuccess('${user.name}\'s role updated to $newRole');
    } catch (e) {
      _showError('Failed to update role for ${user.name}');
    }
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
        title: const Text("User Management"),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search by Name or Email",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        user.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            user.email,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.role,
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontWeight: FontWeight.bold,
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
                                      child: DropdownButtonFormField<String>(
                                        value: user.role,
                                        decoration: InputDecoration(
                                          labelText: 'Role',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: ['super admin', 'admin', 'user']
                                            .map((role) => DropdownMenuItem(
                                                  value: role,
                                                  child: Text(role),
                                                ))
                                            .toList(),
                                        onChanged: (newRole) {
                                          if (newRole != null) {
                                            _onUpdateRole(user, newRole);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Group Assignment Dropdown
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: user.group,
                                        decoration: InputDecoration(
                                          labelText: 'Group',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: groups.map<DropdownMenuItem<String>>((group) {
                                          return DropdownMenuItem<String>(
                                            value: group['id'],
                                            child: Text(group['name']),
                                          );
                                        }).toList(),
                                        onChanged: (newGroup) {
                                          if (newGroup != null) {
                                            _onAssignGroup(user, newGroup);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete Button
                                    IconButton(
                                      onPressed: () => _onDeleteUser(user),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete User',
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