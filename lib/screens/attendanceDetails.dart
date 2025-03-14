import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/userServices.dart';

class AttendanceDetails extends StatefulWidget {
  final String eventId;

  const AttendanceDetails({Key? key, required this.eventId}) : super(key: key);

  @override
  _AttendanceDetailsState createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  final AttendanceService _attendanceService = AttendanceService(baseUrl: 'http://your-backend-url.com/api');
  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');
  List<dynamic> _attendedMembers = [];
  List<dynamic> _notAttendedMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceDetails();
  }

  Future<void> _fetchAttendanceDetails() async {
    try {
      List<dynamic> attendanceList = await _attendanceService.getAttendanceByEvent(widget.eventId);
      List<dynamic> attended = [];
      List<dynamic> notAttended = [];

      for (var attendance in attendanceList) {
        Map<String, dynamic> user = await _userService.getUserById(attendance['userId']);
        if (attendance['attended'] == true) {
          attended.add({
            'name': user['name'],
            'topic': attendance['topic'],
            'aob': attendance['aob'],
          });
        } else {
          notAttended.add({
            'name': user['name'],
            'apology': attendance['reason'],
          });
        }
      }

      setState(() {
        _attendedMembers = attended;
        _notAttendedMembers = notAttended;
      });
    } catch (e) {
      print('Failed to fetch attendance details: $e');
    }
  }

  Widget _buildTable(List<dynamic> data, List<String> columns) {
    return DataTable(
      columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
      rows: data.map((row) {
        return DataRow(
          cells: columns.map((column) {
            return DataCell(Text(row[column.toLowerCase()] ?? ''));
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Attended Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTable(_attendedMembers, ['Name', 'Topic', 'AOB']),
              const SizedBox(height: 20),
              const Text("Not Attended Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTable(_notAttendedMembers, ['Name', 'Apology']),
            ],
          ),
        ),
      ),
    );
  }
}