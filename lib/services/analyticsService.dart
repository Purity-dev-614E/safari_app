import 'dart:convert';
import 'package:church_app/services/authServices.dart';
import 'package:church_app/services/http_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http/intercepted_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late http.Client client;

  AnalyticsService({required this.baseUrl}){
    client = InterceptedClient.build(interceptors: [
      TokenInterceptor(authService: AuthService(baseUrl: baseUrl) )
    ]);
  }

  Future<List<dynamic>> getUserAttendance(String userId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user attendance: ${response.body}');
    }
  }

  Future<List<dynamic>> getEventAttendance(String eventId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/event/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch event attendance: ${response.body}');
    }
  }

  Future<List<dynamic>> getGroupMembers(String groupId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch group members: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllEventsByGroup(String groupId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/events/group/$groupId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch group events: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getAttendanceByTimePeriod(String timePeriod) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/attendance?timePeriod=$timePeriod'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch attendance data: ${response.body}');
    }
  }
  Future<Map<String, dynamic>> getGroupAttendanceByTimePeriod(String timePeriod, String groupId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/$groupId/attendance?timePeriod=$timePeriod'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch attendance data: ${response.body}');
    }
  }


  Future<List<dynamic>> getOverallAttendanceByPeriod(String period) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final url = Uri.parse('$baseUrl/groups/attendance/$period');
    final response = await http.get(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load overall attendance');
    }
  }
}