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
  bool _isLoading = true;
  String? selectedGroupId;

  final GroupService _groupService = GroupService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final AnalyticsService _analyticsService = AnalyticsService(baseUrl: 'https://safari-backend.on.shiper.app/api');
  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');

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
      _showError('Failed to fetch user details: $e');
      return false;
    }
  }

  Future<void> _fetchAnalytics() async {
    if (!await _isSuperAdmin()) {
      _showError('You do not have permission to view this page');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch groups
      List<dynamic> fetchedGroups = await _groupService.getAllGroups();

      // If no group is selected and groups are available, select the first one
      if (selectedGroupId == null && fetchedGroups.isNotEmpty) {
        selectedGroupId = fetchedGroups[0]['id'];
      }

      // Fetch attendance data for the selected time period
      Map<String, dynamic>? fetchedAttendanceData = await _analyticsService.getAttendanceByTimePeriod(selectedTimePeriod);

      // Fetch group demographics for the selected group
      List<dynamic>? fetchedGroupDemographics = [];
      if (selectedGroupId != null) {
        fetchedGroupDemographics = await _analyticsService.getGroupDemographics(selectedGroupId!);
      }

      setState(() {
        groups = fetchedGroups;
        attendanceData = fetchedAttendanceData;
        groupDemographics = fetchedGroupDemographics;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
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
            value: selectedTimePeriod,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: [
              DropdownMenuItem(value: 'week', child: const Text('Last Week')),
              DropdownMenuItem(value: 'month', child: const Text('Last Month')),
              DropdownMenuItem(value: 'year', child: const Text('Last Year')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedTimePeriod = value;
                });
                _fetchAnalytics();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
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
            'Select Group',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedGroupId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: groups != null && groups!.isNotEmpty
                ? groups!.map<DropdownMenuItem<String>>((group) {
              return DropdownMenuItem<String>(
                value: group['id'],
                child: Text(group['name']),
              );
            }).toList()
                : [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No groups available'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedGroupId = value;
                });
                _fetchAnalytics();
              }
            },
          ),
        ],
      ),
    );
  }


  Widget _buildAttendanceChart() {
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
            'Attendance Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: attendanceData != null && attendanceData!['attendance_trends'] != null
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
                    spots: (attendanceData!['attendance_trends'] as List<dynamic>)
                        .map((data) => FlSpot(
                      (data['time'] as num).toDouble(),
                      (data['count'] as num).toDouble(),
                    ))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            )
                : const Center(
              child: Text(
                'No attendance data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsChart() {
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
            'Group Demographics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: groupDemographics != null && groupDemographics!.isNotEmpty
                ? PieChart(
              PieChartData(
                sections: groupDemographics!.map<PieChartSectionData>((data) {
                  return PieChartSectionData(
                    value: (data['count'] as num).toDouble(),
                    color: Colors.primaries[groupDemographics!.indexOf(data) % Colors.primaries.length],
                    title: data['group_name'],
                    radius: 50,
                  );
                }).toList(),
              ),
            )
                : const Center(
              child: Text(
                'No demographics data available',
                style: TextStyle(color: Colors.grey),
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
        title: const Text('Super Admin Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimePeriodSelector(),
            const SizedBox(height: 16),
            _buildGroupSelector(),
            const SizedBox(height: 16),
            _buildAttendanceChart(),
            const SizedBox(height: 16),
            _buildDemographicsChart(),
          ],
        ),
      ),
    );
  }
}
