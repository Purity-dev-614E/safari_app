import 'package:church_app/services/userServices.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';

import '../constants/api_constants.dart';

class AddMemberScreen extends StatefulWidget {
  final String groupId;

  const AddMemberScreen({required this.groupId, super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);
  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);
  List<dynamic> allMembers = [];
  List<dynamic> filteredMembers = [];
  List<dynamic> selectedMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllMembers();
  }

  Future<void> _fetchAllMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> members = await _userService.getAllUsers(); // Assuming this fetches all members
      setState(() {
        allMembers = members;
        filteredMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch members: $e',
        type: NotificationType.error,
      );
    }
  }

  void _filterMembers(String query) {
    setState(() {
      filteredMembers = allMembers.where((member) {
        final name = member['full_name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _selectMember(dynamic member) {
    setState(() {
      selectedMembers.add(member);
      filteredMembers.remove(member);
    });
  }

  void _removeSelectedMember(dynamic member) {
    setState(() {
      selectedMembers.remove(member);
      filteredMembers.add(member);
    });
  }

  Future<void> _addSelectedMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (var member in selectedMembers) {
        await _groupService.addGroupMember(widget.groupId, member['id']);
      }
      if (mounted) {
        Navigator.pop(context);
        NotificationOverlay.of(context).showNotification(
          message: 'Members added successfully',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to add members: $e',
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
        title: const Text("Add Members"),
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
                  const Text(
                    "Selected Members:",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: selectedMembers.map((member) {
                      return Chip(
                        label: Text(member['full_name'] ?? 'Unknown'),
                        onDeleted: () => _removeSelectedMember(member),
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: const TextStyle(color: Colors.blue),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Search by Name",
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    onChanged: _filterMembers,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue.shade200
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(member['full_name'] ?? 'Unknown'),
                            subtitle: Text(member['email'] ?? 'Unknown'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add, color: Colors.blue),
                              onPressed: () => _selectMember(member),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addSelectedMembers,
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
                            "Add Selected Members",
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
    _searchController.dispose();
    super.dispose();
  }
}