import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';

class GroupMembers extends StatefulWidget {
  const GroupMembers({super.key});

  @override
  State<GroupMembers> createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  List<dynamic> members = [];
  String searchQuery = "";

  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');

  @override
  void initState() {
    super.initState();
    _fetchGroupMembers();
  }

  Future<void> _fetchGroupMembers() async {
    try {
      List<dynamic> fetchedMembers = await _groupService.getGroupMembers('groupId'); // Replace 'groupId' with actual group ID
      setState(() {
        members = fetchedMembers;
      });
    } catch (e) {
      print('Failed to fetch group members: $e');
    }
  }

  Future<void> _deleteMember(String memberId) async {
    try {
      await _groupService.removeGroupMember('groupId', memberId); // Replace 'groupId' with actual group ID
      _fetchGroupMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete member')),
      );
    }
  }

  void _editMember(String memberId) {
    // Navigate to edit member screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditMemberScreen(memberId: memberId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Members"),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by Name or Email ...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Member List
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final name = member["name"]!;
                final email = member["email"]!;
                final role = member["role"]!;

                if (!name.toLowerCase().contains(searchQuery) &&
                    !email.toLowerCase().contains(searchQuery)) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          role,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => _editMember(member["id"]),
                          icon: const Icon(Icons.edit, color: Colors.orange),
                        ),
                        IconButton(
                          onPressed: () => _deleteMember(member["id"]),
                          icon: const Icon(Icons.delete),
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
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Member screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMemberScreen()),
          );
        },
        child: const Icon(Icons.person_add_alt),
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Group Analytics",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, "/adminDashboard");
          } else if (index == 1) {
            Navigator.pushNamed(context, "/GroupAnalytics");
          }
        },
      ),
    );
  }
}


class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _memberIdController = TextEditingController();
  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');

  Future<void> _addMember() async {
    try {
      String memberId = _memberIdController.text;

      await _groupService.addGroupMember('groupId', memberId); // Replace 'groupId' with actual group ID
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add member')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Member"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _memberIdController,
              decoration: const InputDecoration(
                labelText: "Member ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addMember,
              child: const Text("Add Member"),
            ),
          ],
        ),
      ),
    );
  }
}



class EditMemberScreen extends StatefulWidget {
  final String memberId;

  const EditMemberScreen({required this.memberId, super.key});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    try {
      // Fetch member details and populate the controllers
      Map<String, dynamic> memberDetails = await _groupService.getGroupById(widget.memberId);
      setState(() {
        _nameController.text = memberDetails['name'];
        _emailController.text = memberDetails['email'];
        _roleController.text = memberDetails['role'];
      });
    } catch (e) {
      print('Failed to fetch member details: $e');
    }
  }

  Future<void> _updateMember() async {
    try {
      // Update member details
      await _groupService.updateGroup(
        widget.memberId,
        {
          'name': _nameController.text,
          'email': _emailController.text,
          'role': _roleController.text,
        },
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update member')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Member"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateMember,
              child: const Text("Update Member"),
            ),
          ],
        ),
      ),
    );
  }
}