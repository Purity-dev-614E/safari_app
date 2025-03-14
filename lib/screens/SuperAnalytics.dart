import 'package:church_app/services/userServices.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/analyticsService.dart';
import 'package:church_app/services/groupServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class SuperAnalytics extends StatefulWidget {
  const SuperAnalytics({super.key});

  @override
  State<SuperAnalytics> createState() => _SuperAnalyticsState();
}

class _SuperAnalyticsState extends State<SuperAnalytics> {
  String selectedTimePeriod = 'week';
  Map<String, dynamic>? attendanceData;
  List<dynamic>? groupDemographics;
  List<dynamic>? groups;
  String? superAdminUserId;

  final GroupService _groupService = GroupService(baseUrl: 'http://your-backend-url.com/api');
  final AnalyticsService _analyticsService = AnalyticsService(baseUrl: 'http://your-backend-url.com/api');
  final UserService _userService = UserService(baseUrl: 'http://your-back');
  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUserId();
  }

  Future<void> _fetchSuperAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      superAdminUserId = prefs.getString('user_id');
    });
    _fetchAnalytics();
  }

  Future<bool> _isSuperAdmin() async {
    if (superAdminUserId == null) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(superAdminUserId!);
      return userDetails['role'] == 'super_admin';
    } catch (e) {
      print('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _fetchAnalytics() async {
    if (!await _isSuperAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to view this page')),
      );
      return;
    }

    try {
      // Fetch groups
      List<dynamic> fetchedGroups = await _groupService.getAllGroups();

      // Fetch attendance data for the selected time period
      Map<String, dynamic>? fetchedAttendanceData = await _analyticsService.getAttendanceByTimePeriod(selectedTimePeriod);

      // Fetch group demographics
      List<dynamic>? fetchedGroupDemographics = await _analyticsService.getGroupDemographics();

      setState(() {
        groups = fetchedGroups;
        attendanceData = fetchedAttendanceData;
        groupDemographics = fetchedGroupDemographics;
      });
    } catch (e) {
      print('Failed to fetch analytics data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: selectedTimePeriod,
              decoration: InputDecoration(
                labelText: 'Time Period',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['week', 'month', 'year'].map((String period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedTimePeriod = value;
                    _fetchAnalytics();
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              "Attendance Trends",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: attendanceData != null
                  ? LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: (attendanceData!['attendance_trends'] as List<dynamic>)
                        .map((data) => FlSpot(data['time'].toDouble(), data['count'].toDouble()))
                        .toList(),
                  ),
                ],
              ))
                  : Center(child: const Text('Loading...', style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: 8),
            const Text(
              "Group Demographics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: groupDemographics != null
                  ? PieChart(PieChartData(
                sections: groupDemographics!.map<PieChartSectionData>((data) {
                  return PieChartSectionData(
                    value: data['value'],
                    color: Color(int.parse(data['color'])),
                    title: '${data['value']}%',
                  );
                }).toList(),
              ))
                  : Center(child: const Text('Loading...', style: TextStyle(color: Colors.grey))),
            ),
          ],
        ),
      ),
    );
  }
}