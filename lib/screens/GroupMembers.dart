import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';

class GroupMembers extends StatefulWidget {
  const GroupMembers({super.key});

  @override
  State<GroupMembers> createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  List<dynamic> members = [];
  String searchQuery = "";
  String? groupId;
  bool isLoading = true;
  bool _isRefreshing = false;

  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');

  @override
  void initState() {
    super.initState();
    _initializeGroupId();
  }

  Future<void> _initializeGroupId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGroupId = prefs.getString('group_id');

    if (savedGroupId == null) {
      String groupName = await _promptForGroupName();
      String fetchedGroupId = await _fetchGroupIdByName(groupName);
      await prefs.setString('group_id', fetchedGroupId);
      setState(() {
        groupId = fetchedGroupId;
      });
    } else {
      setState(() {
        groupId = savedGroupId;
      });
    }

    _fetchGroupMembers();
  }

  Future<String> _promptForGroupName() async {
    String groupName = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Group Name'),
          content: TextField(
            onChanged: (value) {
              groupName = value;
            },
            decoration: const InputDecoration(
              hintText: "Group Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return groupName;
  }

  Future<String> _fetchGroupIdByName(String groupName) async {
    try {
      final group = await _groupService.getGroupByName(groupName);
      return group['id'];
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch group ID by name: $e',
        type: NotificationType.error,
      );
      throw Exception('Failed to fetch group ID by name: $e');
    }
  }

  Future<void> _fetchGroupMembers() async {
    if (groupId == null || groupId!.isEmpty) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      List<dynamic> fetchedMembers = await _groupService.getGroupMembers(groupId!);
      setState(() {
        members = fetchedMembers;
        isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _isRefreshing = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch group members: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _deleteMember(String memberId) async {
    try {
      await _groupService.removeGroupMember(groupId!, memberId);
      await _fetchGroupMembers();
      NotificationOverlay.of(context).showNotification(
        message: 'Member deleted successfully',
        type: NotificationType.success,
      );
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to delete member: $e',
        type: NotificationType.error,
      );
    }
  }

  void _editMember(String memberId) {
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
        elevation: 0,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _fetchGroupMembers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading group members...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchGroupMembers,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  Expanded(
                    child: members.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No members found',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(email),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          role,
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _editMember(member["id"]),
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteMember(member["id"]),
                                        icon: const Icon(Icons.delete, color: Colors.red),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: groupId!)),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add_alt),
      ),
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
  final String groupId;

  const AddMemberScreen({required this.groupId, super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  bool _isLoading = false;

  Future<void> _addMember() async {
    if (_emailController.text.isEmpty) {
      NotificationOverlay.of(context).showNotification(
        message: 'Please enter an email address',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.addGroupMemberByEmail(widget.groupId, _emailController.text);
      if (mounted) {
        Navigator.pop(context);
        NotificationOverlay.of(context).showNotification(
          message: 'Member added successfully',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to add member: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Member"),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                helperText: "Enter the email address of the member to add",
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addMember,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Add Member",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> memberDetails = await _groupService.getGroupById(widget.memberId);
      if (mounted) {
        setState(() {
          _nameController.text = memberDetails['name'];
          _emailController.text = memberDetails['email'];
          _roleController.text = memberDetails['role'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationOverlay.of(context).showNotification(
          message: 'Failed to fetch member details: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _updateMember() async {
    if (_roleController.text.isEmpty) {
      NotificationOverlay.of(context).showNotification(
        message: 'Please enter a role',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.updateGroup(
        widget.memberId,
        {
          'role': _roleController.text,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        NotificationOverlay.of(context).showNotification(
          message: 'Member role updated successfully',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to update member role: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Member Role"),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: false,
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
                      helperText: "You can only modify the member's role",
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateMember,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Update Role",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }
}