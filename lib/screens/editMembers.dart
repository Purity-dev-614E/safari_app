import 'package:church_app/services/userServices.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class EditMemberScreen extends StatefulWidget {
  final String memberId;

  const EditMemberScreen({required this.memberId, super.key});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);
  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);
  bool _isLoading = false;
  String? _selectedRole;
  String _name = '';
  String _email = '';
  final List<String> _roles = ['admin', 'user'];

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final groupId = prefs.getString('group_id');
      Map<String, dynamic> memberDetails = await _groupService.getGroupById(groupId!);
      if (mounted) {
        setState(() {
          _name = memberDetails['full_name'] ?? "";
          _email = memberDetails['email'] ?? "";
          _selectedRole = memberDetails['role'] ?? "user";
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
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      NotificationOverlay.of(context).showNotification(
        message: 'Please select a role',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      await _userService.updateUserRole(userId!, _selectedRole!);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(_name),
            subtitle: Text(_email),
            trailing: DropdownButton<String>(
              value: _selectedRole,
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(
                color: _selectedRole == 'admin' ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
              ),
              underline: Container(
                height: 2,
                color: _selectedRole == 'admin' ? Colors.blue : Colors.green,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue;
                });
              },
              items: _roles.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
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
    );
  }
}
