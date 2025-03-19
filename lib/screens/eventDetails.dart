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
  final AttendanceService _attendanceService = AttendanceService(baseUrl: ApiConstants.baseUrl);
  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);
  String? userId;
  bool isInGroup = false;
  bool _isLoading = false;

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
    if (userId == null) return;
    
    try {
      List<dynamic> members = await _groupService.getGroupMembers(widget.event['groupId']);
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
    
    DateTime eventDate = DateTime.parse(widget.event['date']);
    DateTime currentDate = DateTime.now();
    
    // Remove time component for date comparison
    eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
    currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
    
    return eventDate.isBefore(currentDate) || eventDate.isAtSameMomentAs(currentDate);
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
                if (topicController.text.trim().isEmpty) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Please enter the topic',
                    type: NotificationType.warning,
                  );
                  return;
                }

                try {
                  setState(() => _isLoading = true);
                  await _attendanceService.createAttendance(widget.event['id'], {
                    'userId': userId,
                    'attended': true,
                    'topic': topicController.text.trim(),
                    'aob': aobController.text.trim(),
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
                if (reasonController.text.trim().isEmpty) {
                  NotificationOverlay.of(context).showNotification(
                    message: 'Please enter a reason',
                    type: NotificationType.warning,
                  );
                  return;
                }

                try {
                  setState(() => _isLoading = true);
                  await _attendanceService.createAttendance(widget.event['id'], {
                    'userId': userId,
                    'attended': false,
                    'reason': reasonController.text.trim(),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event['description'],
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
                            "Date and Time: ${event['date']}",
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
                            "Location: ${event['location']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _markAttendance(true),
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
                      onPressed: _isLoading ? null : () => _markAttendance(false),
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