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

  final UserService _userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  bool _isLoading = true;

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
          id: data['id'],
          name: data['name'],
          email: data['email'],
          role: data['role'],
          group: data['group'] ?? '',
        )).toList();
        groups = groupData;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch data: $e');
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
    try {
      await _userService.deleteUser(user.id);
      setState(() {
        users.remove(user);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ${user.name} deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete user ${user.name}")),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.name} assigned to $newGroup")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to assign ${user.name} to $newGroup")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by Name or Email",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
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
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(user.name),
                    subtitle: Text("${user.email} • ${user.role} • ${user.group}"),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        // Delete Button
                        IconButton(
                          onPressed: () => _onDeleteUser(user),
                          icon: Icon(Icons.delete, color: Colors.red),
                        ),
                        // Assign Group Dropdown
                        DropdownButton<String>(
                          underline: const SizedBox(),
                          icon: const Icon(Icons.group, color: Colors.green),
                          onChanged: (newGroup) {
                            if (newGroup != null) _onAssignGroup(user, newGroup);
                          },
                          items: groups.map<DropdownMenuItem<String>>((dynamic group) {
                            return DropdownMenuItem<String>(
                              value: group['id'],
                              child: Text(group['name']),
                            );
                          }).toList(),
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

    );
  }
}