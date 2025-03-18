import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventDetails extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetails({super.key, required this.event});

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  final AttendanceService _attendanceService = AttendanceService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  String? userId;
  bool isInGroup = false;

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
      print('Error checking group membership: $e');
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark attendance: ${e.toString()}')),
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
                  decoration: const InputDecoration(labelText: 'Topic'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: aobController,
                  decoration: const InputDecoration(labelText: 'AOB'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the topic')),
                  );
                  return;
                }

                try {
                  await _attendanceService.createAttendance(widget.event['id'], {
                    'userId': userId,
                    'attended': true,
                    'topic': topicController.text.trim(),
                    'aob': aobController.text.trim(),
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance marked successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to mark attendance: ${e.toString()}')),
                  );
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
                  decoration: const InputDecoration(labelText: 'Reason'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }

                try {
                  await _attendanceService.createAttendance(widget.event['id'], {
                    'userId': userId,
                    'attended': false,
                    'reason': reasonController.text.trim(),
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance marked successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to mark attendance: ${e.toString()}')),
                  );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(event['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Date and Time: ${event['date']}"),
            const SizedBox(height: 10),
            Text("Location: ${event['location']}"),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _markAttendance(true),
                  child: const Text("Mark as Attended"),
                ),
                ElevatedButton(
                  onPressed: () => _markAttendance(false),
                  child: const Text("Mark as Not Attended"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}