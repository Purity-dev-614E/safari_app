import 'package:flutter/material.dart';
import '../services/userServices.dart';
import '../services/groupServices.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

class GroupAdminAssignment extends StatefulWidget {
  final UserService userService;
  final GroupService groupService;

  const GroupAdminAssignment({
    Key? key,
    required this.userService,
    required this.groupService,
  }) : super(key: key);

  @override
  _GroupAdminAssignmentState createState() => _GroupAdminAssignmentState();
}

class _GroupAdminAssignmentState extends State<GroupAdminAssignment> {
  List<dynamic> groups = [];
  bool isLoading = true;
  String? searchQuery;
  bool _isAssigningAdmin = false;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      setState(() => isLoading = true);
      final fetchedGroups = await widget.groupService.getAllGroups();
      setState(() {
        groups = fetchedGroups;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch groups: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _showAssignAdminDialog(String groupId, String groupName) async {
    final TextEditingController emailController = TextEditingController();
    bool isSearching = false;
    List<dynamic> searchResults = [];

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assign Admin to $groupName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Enter admin's Name",
                      labelText: "Admin's Name",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        setState(() => isSearching = true);
                        try {
                          final results = await widget.userService.searchUsersByName(value);
                          setState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        } catch (e) {
                          setState(() => isSearching = false);
                          NotificationOverlay.of(context).showNotification(
                            message: 'Failed to search users: $e',
                            type: NotificationType.error,
                          );
                        }
                      } else {
                        setState(() {
                          searchResults = [];
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                user['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user['name']),
                            subtitle: Text(user['email']),
                            onTap: () async {
                              if (_isAssigningAdmin) return;
                              
                              try {
                                setState(() => _isAssigningAdmin = true);
                                await widget.groupService.assignAdminToGroup(groupId, user['id']);
                                Navigator.of(context).pop();
                                NotificationOverlay.of(context).showNotification(
                                  message: 'Admin assigned successfully',
                                  type: NotificationType.success,
                                );
                                fetchGroups();
                              } catch (e) {
                                NotificationOverlay.of(context).showNotification(
                                  message: 'Failed to assign admin: $e',
                                  type: NotificationType.error,
                                );
                              } finally {
                                setState(() => _isAssigningAdmin = false);
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<dynamic> get filteredGroups {
    if (searchQuery == null || searchQuery!.isEmpty) return groups;
    return groups.where((group) {
      return group['name'].toLowerCase().contains(searchQuery!.toLowerCase()) ||
          (group['admin_name'] ?? '').toLowerCase().contains(searchQuery!.toLowerCase());
    }).toList();
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isAssigningAdmin ? null : () => _showAssignAdminDialog(group['id'], group['name']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Admin: ${group['admin_name'] ?? 'None'}',
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: _isAssigningAdmin ? Colors.grey : Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assign Admin',
                          style: TextStyle(
                            color: _isAssigningAdmin ? Colors.grey : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Group Admins'),
        elevation: 0,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isAssigningAdmin ? null : fetchGroups,
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
                    'Loading groups...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
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
                      hintText: 'Search groups or admins...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredGroups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery != null && searchQuery!.isNotEmpty
                                    ? 'No groups found matching your search'
                                    : 'No groups available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchGroups,
                          child: ListView.builder(
                            itemCount: filteredGroups.length,
                            itemBuilder: (context, index) {
                              final group = filteredGroups[index];
                              return _buildGroupCard(group);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
