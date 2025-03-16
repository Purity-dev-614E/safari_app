import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/eventService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupAnalytics extends StatefulWidget {
  const GroupAnalytics({super.key});

  @override
  State<GroupAnalytics> createState() => _GroupAnalyticsState();
}

class _GroupAnalyticsState extends State<GroupAnalytics> {
  String selectedTimeFilter = "Week"; // Default filter
  List<dynamic>? eventAttendance;
  List<dynamic>? periodicAttendance;
  String? adminUserId;
  String? groupId;

  final AttendanceService _attendanceService = AttendanceService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  final EventService _eventService = EventService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');
  final UserService _userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api/users');
  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api');

  @override
  void initState() {
    super.initState();
    _fetchAdminUserId();
    _initializeGroupId();
  }

  Future<void> _fetchAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminUserId = prefs.getString('user_id');
    });
  }

  Future<void> _initializeGroupId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGroupId = prefs.getString('group_id');

    if (savedGroupId == null) {
      String groupName = await _promptForGroupName();
      String fetchedGroupId = await _fetchGroupIdByName(groupName);
      await prefs.setString('group_id', fetchedGroupId);
      setState(() {
        groupId = fetchedGroupId;
      });
    } else {
      setState(() {
        groupId = savedGroupId;
      });
    }

    _fetchAnalytics();
  }

  Future<String> _promptForGroupName() async {
    String groupName = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Group Name'),
          content: TextField(
            onChanged: (value) {
              groupName = value;
            },
            decoration: InputDecoration(hintText: "Group Name"),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return groupName;
  }

  Future<String> _fetchGroupIdByName(String groupName) async {
    try {
      final group = await _groupService.getGroupByName(groupName);
      return group['id'];
    } catch (e) {
      throw Exception('Failed to fetch group ID by name: $e');
    }
  }

  Future<void> _fetchAnalytics() async {
    if (groupId == null || groupId!.isEmpty) return;

    if (!await _isAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to view this page')),
      );
      return;
    }

    try {
      // Fetch event attendance data
      List<dynamic>? fetchedEventAttendance = await _eventService.getEventsByGroup(groupId!);

      // Fetch attendance data for the selected time period
      List<dynamic>? fetchedPeriodicAttendance = await _attendanceService.getAttendanceByTimePeriod(
          groupId!,
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeGroupId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
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
                  Navigator.pushNamed(context, "/GroupMembers", arguments: groupId);
                } else if (index == 1) {
                  Navigator.pushNamed(context, "/adminDashboard", arguments: groupId);
                }
              },
            ),
          );
        }
      },
    );
  }
}