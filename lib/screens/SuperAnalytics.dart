import 'package:flutter/material.dart';
import 'package:church_app/services/super_services.dart';

class Superanalytics extends StatefulWidget {
  const Superanalytics({super.key});

  @override
  State<Superanalytics> createState() => _SuperanalyticsState();
}

class _SuperanalyticsState extends State<Superanalytics> {
  String selectedWeek = 'Week 1';
  String selectedMonth = 'January';
  String selectedYear = "2025";
  Map<String, dynamic>? analyticsData;

  final List<String> weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> years = ['2024', '2025'];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    Map<String, dynamic>? data = await AdminServices.getAnalytics();
    setState(() {
      analyticsData = data;
    });
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
              'Filtered by Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedWeek,
                    decoration: InputDecoration(
                      labelText: 'Week',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: weeks.map((String week) {
                      return DropdownMenuItem<String>(
                        value: week,
                        child: Text(week),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedWeek = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      labelText: "Month",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: "Year",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: years.map((String year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                ),
              ],
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
              child: Center(
                child: Text(
                  analyticsData != null
                      ? 'Line Chart for Attendance Trends: ${analyticsData!['attendance_trends']}'
                      : 'Loading...',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Group Comparison",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(
                child: Text(
                  analyticsData != null
                      ? 'Bar Chart for Group Comparison: ${analyticsData!['group_comparison']}'
                      : 'Loading...',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}