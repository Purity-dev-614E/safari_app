import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventDetails extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetails({super.key, required this.event});

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  final AttendanceService _attendanceService = AttendanceService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _markAttendance(bool attended) async {
    if (!_canMarkAttendance()) return;

    if (attended) {
      await _showAttendedDialog();
    } else {
      await _showNotAttendedDialog();
    }
  }

  bool _canMarkAttendance() {
    // Check if the user belongs to the group and if the event date has passed or is the same day
    bool isInGroup = widget.event['groupId'] == userId; // Simplified for example purposes
    DateTime eventDate = DateTime.parse(widget.event['date']);
    DateTime currentDate = DateTime.now();
    return isInGroup && (eventDate.isBefore(currentDate) || eventDate.isAtSameMomentAs(currentDate));
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
                ),
                TextField(
                  controller: aobController,
                  decoration: const InputDecoration(labelText: 'AOB'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                // Save attendance data here
                await _attendanceService.createAttendance(widget.event['id'], {
                  'userId': userId,
                  'attended': true,
                  'topic': topicController.text,
                  'aob': aobController.text,
                });

                Navigator.of(context).pop();
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
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                // Save non-attendance data here
                await _attendanceService.createAttendance(widget.event['id'], {
                  'userId': userId,
                  'attended': false,
                  'reason': reasonController.text,
                });

                Navigator.of(context).pop();
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