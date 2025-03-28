import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';

import '../constants/api_constants.dart';

class EventDetails extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetails({super.key, required this.event});

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  final AttendanceService _attendanceService = AttendanceService(
      baseUrl: ApiConstants.baseUrl);
  final GroupService _groupService = GroupService(
      baseUrl: ApiConstants.baseUrl);
  String? userId;
  bool isInGroup = false;
  bool _isLoading = false;
  bool? _attendanceStatus; // null: not marked, true: attended, false: not attended

  @override
  void initState() {
    super.initState();
    _getUserId();
    _checkGroupMembership();
  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _checkGroupMembership() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final groupId = widget.event['group_id'];
    final userId = prefs.getString('user_id');

    if (groupId == null || userId == null) {
      NotificationOverlay.of(context).showNotification(
        message: 'Group ID or User ID is missing',
        type: NotificationType.error,
      );
      return;
    }

    try {
      List<dynamic> members = await _groupService.getGroupMembers(groupId);
      setState(() {
        isInGroup = members.any((member) => member['id'] == userId);
      });
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Error checking group membership: $e',
        type: NotificationType.error,
      );
    }
  }

  bool _canMarkAttendance() {
    if (!isInGroup) return false;

    DateTime eventDate = DateTime.tryParse(widget.event['date'] ?? '') ??
        DateTime.now();
    DateTime currentDate = DateTime.now();

    eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
    currentDate =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    return eventDate.isBefore(currentDate) ||
        eventDate.isAtSameMomentAs(currentDate);
  }

  Future<void> _markAttendance(bool attended) async {
    if (!_canMarkAttendance()) {
      String message = !isInGroup
          ? 'You are not a member of this group'
          : 'You can only mark attendance for past or current events';

      NotificationOverlay.of(context).showNotification(
        message: message,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      if (attended) {
        await _showAttendedDialog();
      } else {
        await _showNotAttendedDialog();
      }
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to mark attendance: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _showAttendedDialog() async {
    TextEditingController topicController = TextEditingController();
    TextEditingController aobController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Event Feedback'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: topicController,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: aobController,
                  decoration: const InputDecoration(
                    labelText: 'AOB',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                if (topicController.text
                    .trim()
                    .isEmpty) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Please enter the topic',
                    type: NotificationType.warning,
                  );
                  return;
                }

                try {
                  setState(() => _isLoading = true);
                  await _attendanceService.createAttendance(
                      widget.event['id'], {
                    'user_id': userId,
                    'present': true,
                    'topic': topicController.text.trim(),
                    'aob': aobController.text.trim(),
                  });

                  setState(() {
                    _attendanceStatus = true;
                  });

                  Navigator.of(context).pop(true);
                  NotificationOverlay.of(context).showNotification(
                    message: 'Attendance marked successfully',
                    type: NotificationType.success,
                  );
                } catch (e) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Failed to mark attendance: ${e.toString()}',
                    type: NotificationType.error,
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNotAttendedDialog() async {
    TextEditingController reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reason for Not Attending'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                if (reasonController.text
                    .trim()
                    .isEmpty) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Please enter a reason',
                    type: NotificationType.warning,
                  );
                  return;
                }

                try {
                  setState(() => _isLoading = true);
                  await _attendanceService.createAttendance(
                      widget.event['id'], {
                    'user_id': userId,
                    'present': false,
                    'apology': reasonController.text.trim(),
                  });

                  setState(() {
                    _attendanceStatus = false;
                  });

                  Navigator.of(context).pop();
                  NotificationOverlay.of(context).showNotification(
                    message: 'Attendance marked successfully',
                    type: NotificationType.success,
                  );
                } catch (e) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Failed to mark attendance: ${e.toString()}',
                    type: NotificationType.error,
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          event['description'] ?? 'No Description',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Date and Time: ${event['date'] ?? 'No Date'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Location: ${event['location'] ??
                                    'No Location'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_attendanceStatus != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _attendanceStatus! ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _attendanceStatus! ? 'Attended' : 'Not Attended',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isInGroup)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You need to be a member of this group to mark attendance',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_attendanceStatus == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () =>
                            _markAttendance(true),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Mark as Attended"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () =>
                            _markAttendance(false),
                        icon: const Icon(Icons.cancel),
                        label: const Text("Mark as Not Attended"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
