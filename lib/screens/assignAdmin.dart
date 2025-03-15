import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userServices.dart';
import '../services/groupServices.dart';

class AssignGroupAdminScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AssignGroupAdminScreen({required this.groupId, required this.groupName, super.key});

  @override
  _AssignGroupAdminScreenState createState() => _AssignGroupAdminScreenState();
}

class _AssignGroupAdminScreenState extends State<AssignGroupAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _userService.searchUsersByName(_searchController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search users: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignAdmin(String userId, String userName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? superAdminUserId = prefs.getString('user_id');

    if (superAdminUserId == null) return;

    try {
      // Check if user is already an admin
      Map<String, dynamic> userDetails = await _userService.getUserById(userId);
      if (userDetails['role'] != 'admin') {
        // Update user role to admin
        await _userService.updateUser(userId, {'role': 'admin'});
      }
      // Assign user as group admin
      await _groupService.assignAdminToGroup(widget.groupId, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName has been assigned as admin of ${widget.groupName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign admin: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Group Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users by Name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user['full_name']),
                    subtitle: Text(user['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () => _assignAdmin(user['id'], user['full_name']),
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