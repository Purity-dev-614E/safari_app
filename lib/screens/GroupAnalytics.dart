import 'package:church_app/services/userServices.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/eventService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupAnalytics extends StatefulWidget {
  final String groupId;

  const GroupAnalytics({super.key, required this.groupId});

  @override
  State<GroupAnalytics> createState() => _GroupAnalyticsState();
}

class _GroupAnalyticsState extends State<GroupAnalytics> {
  String selectedTimeFilter = "Week"; // Default filter
  List<dynamic>? eventAttendance;
  List<dynamic>? periodicAttendance;
  String? adminUserId;

  final AttendanceService _attendanceService = AttendanceService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  final EventService _eventService = EventService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  final UserService _userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');

  @override
  void initState() {
    super.initState();
    _fetchAdminUserId();
    _fetchAnalytics();
  }

  Future<void> _fetchAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminUserId = prefs.getString('user_id');
    });
  }

  Future<bool> _isAdmin() async {
    if (adminUserId == null) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(adminUserId!);
      return userDetails['role'] == 'admin';
    } catch (e) {
      print('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _fetchAnalytics() async {
    if (!await _isAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to view this page')),
      );
      return;
    }

    try {
      // Fetch event attendance data
      List<dynamic>? fetchedEventAttendance = await _eventService.getEventsByGroup(widget.groupId);

      // Fetch attendance data for the selected time period
      List<dynamic>? fetchedPeriodicAttendance = await _attendanceService.getAttendanceByTimePeriod(
          widget.groupId,
          selectedTimeFilter
      );

      setState(() {
        eventAttendance = fetchedEventAttendance;
        periodicAttendance = fetchedPeriodicAttendance;
      });
    } catch (e) {
      print('Failed to fetch analytics data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Analytics"),
      ),
      body: Column(
        children: [
          // Time filter dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedTimeFilter,
              onChanged: (newValue) {
                setState(() {
                  selectedTimeFilter = newValue!;
                  _fetchAnalytics();
                });
              },
              items: ['Week', 'Month', 'Year'].map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: "Select Time Filter",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          // Line Chart - Attendance per Event
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: eventAttendance != null
                  ? LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: eventAttendance!.map((data) {
                        return FlSpot(data['eventId'].toDouble(), data['count'].toDouble());
                      }).toList(),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                ),
              )
                  : Center(child: const Text('Loading...', style: TextStyle(color: Colors.grey))),
            ),
          ),
          // Line Chart - Periodic Attendance
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: periodicAttendance != null
                  ? LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: periodicAttendance!.map((data) {
                        return FlSpot(data['time'].toDouble(), data['count'].toDouble());
                      }).toList(),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                ),
              )
                  : Center(child: const Text('Loading...', style: TextStyle(color: Colors.grey))),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Group Members",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, "/GroupMembers", arguments: widget.groupId);
          } else if (index == 1) {
            Navigator.pushNamed(context, "/adminDashboard", arguments: widget.groupId);
          }
        },
      ),
    );
  }
}