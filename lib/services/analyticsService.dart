import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AnalyticsService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AnalyticsService({required this.baseUrl});

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
}