import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/userServices.dart';

import '../constants/api_constants.dart';
import '../widgets/custom_notification.dart';
import '../widgets/notification_overlay.dart';


class AttendanceDetails extends StatefulWidget {
  final String eventId;

  const AttendanceDetails({super.key, required this.eventId});

  @override
  _AttendanceDetailsState createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  final AttendanceService _attendanceService = AttendanceService(baseUrl: ApiConstants.baseUrl);
  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);
  List<dynamic> _attendedMembers = [];
  List<dynamic> _notAttendedMembers = [];
  bool isLoading = true;
  String? eventName;
  String? eventDate;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceDetails();
  }

  Future<void> _fetchAttendanceDetails() async {
    try {
      setState(() => isLoading = true);
      List<dynamic> attendanceList = await _attendanceService.getAttendanceByEvent(widget.eventId);
      List<dynamic> attended = [];
      List<dynamic> notAttended = [];

      for (var attendance in attendanceList) {
        if (attendance['user_id'] == null) continue;
        Map<String, dynamic> user = await _userService.getUserById(attendance['user_id']);
        String fullName = user['full_name'] ?? "Unknown";
        String topic = attendance['topic'] ?? "";
        String aob = attendance['aob'] ?? "";
        String apology = attendance['apology'] ?? "";

        if (attendance['present'] == true) {
          attended.add({
            'full_name': fullName,
            'topic': topic,
            'aob': aob,
          });
        } else {
          notAttended.add({
            'full_name': fullName,
            'apology': apology,
          });
        }
      }

      setState(() {
        _attendedMembers = attended;
        _notAttendedMembers = notAttended;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to fetch attendance details: $e');
    }
  }

  void _showError(String message) {
    NotificationOverlay.of(context).showNotification(
      message: message,
      type: NotificationType.error,
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isAttended) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAttended ? Colors.green.shade100 : Colors.red.shade100,
                  child: Text(
                    member['full_name'][0].toUpperCase(),
                    style: TextStyle(
                      color: isAttended ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member['full_name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAttended ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAttended ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: isAttended ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (isAttended) ...[
              const SizedBox(height: 8),
              if (member['topic'] != null && member['topic'].isNotEmpty)
                _buildInfoRow('Topic', member['topic']),
              if (member['aob'] != null && member['aob'].isNotEmpty)
                _buildInfoRow('AOB', member['aob']),
            ] else ...[
              const SizedBox(height: 8),
              if (member['apology'] != null && member['apology'].isNotEmpty)
                _buildInfoRow('Apology', member['apology']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Details"),
        elevation: 0,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAttendanceDetails,
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
                    'Loading attendance details...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchAttendanceDetails,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Present Members',
                      _attendedMembers.length,
                    ),
                    if (_attendedMembers.isEmpty)
                      _buildEmptyState('No members attended this event'),
                    ..._attendedMembers.map(
                      (member) => _buildMemberCard(member, true),
                    ),
                    _buildSectionHeader(
                      'Absent Members',
                      _notAttendedMembers.length,
                    ),
                    if (_notAttendedMembers.isEmpty)
                      _buildEmptyState('No members were absent'),
                    ..._notAttendedMembers.map(
                      (member) => _buildMemberCard(member, false),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}