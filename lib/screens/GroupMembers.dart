import 'package:church_app/screens/AddMembers.dart';
import 'package:church_app/screens/editMembers.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';

import '../constants/api_constants.dart';

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

  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);

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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => EditMemberScreen(memberId: memberId),
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
                              final name = member["full_name"] ?? "Unknown";
                              final email = member["email"] ?? "Unknown";
                              final role = member["role"] ?? "Member";

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
          if (groupId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: groupId!)),
            );
          } else {
            NotificationOverlay.of(context).showNotification(
              message: 'Group ID is not available',
              type: NotificationType.error,
            );
          }
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