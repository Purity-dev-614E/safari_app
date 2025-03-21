import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/attendanceService.dart';
import 'package:church_app/services/eventService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/widgets/notification_overlay.dart';
import 'package:church_app/widgets/custom_notification.dart';

import '../constants/api_constants.dart';

class GroupAnalytics extends StatefulWidget {
  const GroupAnalytics({super.key});

  @override
  State<GroupAnalytics> createState() => _GroupAnalyticsState();
}

class _GroupAnalyticsState extends State<GroupAnalytics> {
  String selectedTimeFilter = "Week";
  List<dynamic>? eventAttendance;
  List<dynamic>? periodicAttendance;
  String? adminUserId;
  String? groupId;
  bool isLoading = true;
  String? groupName;
  int totalMembers = 0;
  int totalEvents = 0;
  double averageAttendance = 0;
  bool _isRefreshing = false;

  final AttendanceService _attendanceService = AttendanceService(baseUrl: ApiConstants.baseUrl);
  final EventService _eventService = EventService(baseUrl: ApiConstants.baseUrl);
  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);
  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);

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
          title: const Text('Enter Group Name'),
          content: TextField(
            onChanged: (value) {
              groupName = value;
            },
            decoration: const InputDecoration(
              hintText: "Group Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
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
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch group ID by name: $e',
        type: NotificationType.error,
      );
      throw Exception('Failed to fetch group ID by name: $e');
    }
  }

  Future<void> _fetchAnalytics() async {
    if (groupId == null || groupId!.isEmpty) return;

    if (!await _isAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to view this page',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      isLoading = true;
      _isRefreshing = true;
    });

    try {
      // Fetch group details
      final groupDetails = await _groupService.getGroupById(groupId!);
      final members = await _groupService.getGroupMembers(groupId!);
      final events = await _eventService.getEventsByGroup(groupId!);

      // Fetch attendance data
      List<dynamic>? fetchedEventAttendance = await _eventService.getEventsByGroup(groupId!);
      List<dynamic>? fetchedPeriodicAttendance = await _attendanceService.getAttendanceByTimePeriod(
        groupId!,
        selectedTimeFilter,
      );

      // Calculate statistics
      double totalAttendance = 0;
      int attendanceCount = 0;
      for (var event in events) {
        if (event['attendance_count'] != null) {
          totalAttendance += event['attendance_count'];
          attendanceCount++;
        }
      }

      setState(() {
        eventAttendance = fetchedEventAttendance;
        periodicAttendance = fetchedPeriodicAttendance;
        groupName = groupDetails['name'];
        totalMembers = members.length;
        totalEvents = events.length;
        averageAttendance = attendanceCount > 0 ? totalAttendance / attendanceCount : 0;
        isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _isRefreshing = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch analytics data: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<bool> _isAdmin() async {
    if (adminUserId == null) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(adminUserId!);
      return userDetails['role'] == 'admin';
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch user details: $e',
        type: NotificationType.error,
      );
      return false;
    }
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Members',
              totalMembers.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Total Events',
              totalEvents.toString(),
              Icons.event,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Avg. Attendance',
              averageAttendance.toStringAsFixed(1),
              Icons.people_outline,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedTimeFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: ['Week', 'Month', 'Year'].map((filter) {
              return DropdownMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedTimeFilter = value;
                });
                _fetchAnalytics();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: eventAttendance != null && eventAttendance!.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: eventAttendance!.map((data) {
                            return FlSpot(
                              data['eventId'].toDouble(),
                              data['count'].toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No event attendance data available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodicAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Periodic Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: periodicAttendance != null && periodicAttendance!.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: periodicAttendance!.map((data) {
                            return FlSpot(
                              data['time'].toDouble(),
                              data['count'].toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No periodic attendance data available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
        title: Text(groupName != null ? "Analytics - $groupName" : "Group Analytics"),
        elevation: 0,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _fetchAnalytics,
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
                    'Loading analytics data...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildTimeFilter(),
                    const SizedBox(height: 16),
                    _buildEventAttendanceChart(),
                    const SizedBox(height: 16),
                    _buildPeriodicAttendanceChart(),
                  ],
                ),
              ),
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
}