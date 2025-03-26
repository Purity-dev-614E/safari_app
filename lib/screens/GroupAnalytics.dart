import 'package:church_app/services/eventService.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendanceService.dart';
import '../constants/api_constants.dart';
import '../widgets/custom_notification.dart';
import '../widgets/notification_overlay.dart';

class GroupAnalytics extends StatefulWidget {
  const GroupAnalytics({super.key});

  @override
  State<GroupAnalytics> createState() => _GroupAnalyticsState();
}

class _GroupAnalyticsState extends State<GroupAnalytics> {
  List<dynamic>? events;
  Map<String, List<dynamic>> attendedUsers = {};
  String? groupId;
  bool isLoading = true;

  final AttendanceService _attendanceService = AttendanceService(baseUrl: ApiConstants.baseUrl);
  final EventService _eventService = EventService(baseUrl: ApiConstants.baseUrl);

  @override
  void initState() {
    super.initState();
    _initializeGroupId();
  }

  Future<void> _initializeGroupId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGroupId = prefs.getString('group_id');

    if (savedGroupId != null) {
      setState(() {
        groupId = savedGroupId;
      });
      await _fetchEvents();
      await _fetchAttendedUsers();
    }
  }

  Future<void> _fetchEvents() async {
    if (groupId == null || groupId!.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<dynamic>? fetchedEvents = await _eventService.getEventsByGroup(groupId!);
      setState(() {
        events = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch attended Users: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _fetchAttendedUsers() async {
    if (events == null || events!.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      for (var event in events!) {
        List<dynamic> users = await _attendanceService.getByAttendedUsers(event['id']);
        setState(() {
          attendedUsers[event['id']] = users;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch attended users: $e')),
      );
    }
  }

  double _calculateAverageAttendance() {
    if (attendedUsers.isEmpty) return 0.0;
    int totalAttendance = attendedUsers.values.fold(0, (sum, users) => sum + users.length);
    return totalAttendance / attendedUsers.length;
  }

  Widget _buildAverageAttendanceCard() {
    double averageAttendance = _calculateAverageAttendance();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              averageAttendance.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildEventAttendanceBarChart() {
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
           child: events != null && events!.isNotEmpty
               ? BarChart(
                   BarChartData(
                     alignment: BarChartAlignment.spaceAround,
                     barGroups: events!.map((event) {
                       return BarChartGroupData(
                         x: events!.indexOf(event),
                         barRods: [
                           BarChartRodData(
                             toY: (attendedUsers[event['id']]?.length ?? 0).toDouble(),
                             color: Colors.blue, // Use color for a single color
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
                                 color: Colors.black,
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
                               events![value.toInt()]['title'] ?? "",
                               style: const TextStyle(
                                 color: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Analytics"),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAverageAttendanceCard(),
                  _buildEventAttendanceBarChart(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullReportScreen(events: events, attendedUsers: attendedUsers),
                        ),
                      );
                    },
                    child: const Text('Full Report'),
                  ),
                ],
              ),
            ),
    );
  }
}

class FullReportScreen extends StatelessWidget {
  final List<dynamic>? events;
  final Map<String, List<dynamic>> attendedUsers;

  const FullReportScreen({Key? key, this.events, required this.attendedUsers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Report'),
        backgroundColor: Colors.blue,
      ),
      body: events != null && events!.isNotEmpty
          ? ListView.builder(
              itemCount: events!.length,
              itemBuilder: (context, index) {
                final event = events![index];
                return ListTile(
                  title: Text(event['title']?? ""),
                  subtitle: Text('Attendance: ${attendedUsers[event['id']]?.length ?? 0}'),
                );
              },
            )
          : const Center(
              child: Text('No event attendance data available'),
            ),
    );
  }
}



