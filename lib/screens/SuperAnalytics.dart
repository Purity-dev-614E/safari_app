import 'package:church_app/services/groupServices.dart';
import 'package:church_app/services/userServices.dart';
import 'package:flutter/material.dart';
import 'package:church_app/services/analyticsService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/api_constants.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

class SuperAnalytics extends StatefulWidget {
  const SuperAnalytics({super.key});

  @override
  State<SuperAnalytics> createState() => _SuperAnalyticsState();
}

class _SuperAnalyticsState extends State<SuperAnalytics> {
  String selectedTimePeriod = 'week';
  List<dynamic>? attendanceData = [];
  List<dynamic>? groups = [];
  String? superAdminUserId;
  bool _isLoading = true;
  bool _isRefreshing = false;

  final AnalyticsService _analyticsService = AnalyticsService(baseUrl: ApiConstants.baseUrl);
  final UserService _userService = UserService(baseUrl: ApiConstants.usersUrl);
  final GroupService _groupService = GroupService(baseUrl: ApiConstants.baseUrl);

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUserId();
  }

  Future<void> _fetchSuperAdminUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      superAdminUserId = prefs.getString('user_id') ?? '';
    });
    _fetchAnalytics();
  }

  Future<bool> _isSuperAdmin() async {
    if (superAdminUserId == null || superAdminUserId!.isEmpty) return false;
    try {
      Map<String, dynamic> userDetails = await _userService.getUserById(superAdminUserId!);
      return userDetails['role'] == 'super admin';
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch user details: $e',
        type: NotificationType.error,
      );
      return false;
    }
  }

  Future<void> _fetchAnalytics() async {
    if (!await _isSuperAdmin()) {
      NotificationOverlay.of(context).showNotification(
        message: 'You do not have permission to view this page',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Fetch attendance data for the selected time period
      List<dynamic>? fetchedAttendanceData = await _analyticsService.getOverallAttendanceByPeriod(selectedTimePeriod) ?? [];

      // Fetch all groups
      List<dynamic> fetchedGroups = await _groupService.getAllGroups() ?? [];

      // Fetch number of members for each group
      for (var group in fetchedGroups) {
        group['members_count'] = (await _groupService.getGroupMembers(group['id'])).length;
      }

      setState(() {
        attendanceData = fetchedAttendanceData ?? [];
        groups = fetchedGroups ?? [];
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch analytics data: $e',
        type: NotificationType.error,
      );
    }
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Time Period',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedTimePeriod,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
              filled: true,
              fillColor: Colors.blue.shade50,
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

  Widget _buildAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Trends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: attendanceData != null && attendanceData!.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.blue.shade100,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: attendanceData!
                              .map((data) => FlSpot(
                                    (data['time'] as num?)?.toDouble() ?? 0.0,
                                    (data['count'] as num?)?.toDouble() ?? 0.0,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: Colors.blue.shade700,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: Colors.blue.shade700,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No attendance data available',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMembersChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Group Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: groups != null && groups!.isNotEmpty
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: groups!.map((group) {
                        return BarChartGroupData(
                          x: groups!.indexOf(group),
                          barRods: [
                            BarChartRodData(
                              toY: (group['members_count'] as num?)?.toDouble() ?? 0.0,
                              color: Colors.blue,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.lightBlueAccent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                groups![value.toInt()]['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'No group members data available',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 16,
                      ),
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
        title: Text(
          'Analytics Dashboard',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _fetchAnalytics,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: Colors.blue.shade700,
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimePeriodSelector(),
                      const SizedBox(height: 16),
                      _buildAttendanceChart(),
                      const SizedBox(height: 16),
                      _buildGroupMembersChart(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}