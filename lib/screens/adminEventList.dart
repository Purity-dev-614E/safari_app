import 'package:flutter/material.dart';
import 'package:church_app/services/eventService.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class AddEventsScreen extends StatefulWidget {
  const AddEventsScreen({super.key});

  @override
  State<AddEventsScreen> createState() => _AddEventsScreenState();
}

class _AddEventsScreenState extends State<AddEventsScreen> {

  final EventService _eventService = EventService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Future<void> _addEvent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? groupId = prefs.getString('group_id');    if (_formKey.currentState!.validate()) {
      try {
       final response = await _eventService.createEvent(groupId!, {
         'groupId': groupId,
         'title': _titleController.text,
         'description': _descriptionController.text,
         'date': _dateController.text,
         'location': _locationController.text,
       });

       if (response.containsKey('title') && response.containsKey('date') && response.containsKey('location')) {
         Navigator.pop(context);
       } else {
         throw Exception('Failed to add event');
       }
      } catch (e) {
        print('Error adding event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2050),
                  );

                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        _dateController.text = '${pickedDate.toLocal()} ${pickedTime.format(context)}';
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addEvent,
                child: const Text('Add Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }


}


