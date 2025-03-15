import 'package:flutter/material.dart';
import 'package:church_app/services/eventService.dart';
import 'attendanceDetails.dart';

class AdminEventList extends StatefulWidget {
  final String groupId;

  const AdminEventList({super.key, required this.groupId});

  @override
  _AdminEventListState createState() => _AdminEventListState();
}

class _AdminEventListState extends State<AdminEventList> {
  final EventService _eventService = EventService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      List<dynamic> events = await _eventService.getEventsByGroup(widget.groupId);
      setState(() {
        _events = events;
      });
    } catch (e) {
      print('Failed to fetch events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
      ),
      body: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_events[index]['name']),
            subtitle: Text(_events[index]['date']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceDetails(eventId: _events[index]['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}