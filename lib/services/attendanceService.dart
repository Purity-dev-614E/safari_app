import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AttendanceService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AttendanceService({required this.baseUrl});

  Future<Map<String, dynamic>> createAttendance(String eventId, Map<String, dynamic> attendanceData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/event/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(attendanceData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create attendance: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getAttendanceById(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch attendance: ${response.body}');
    }
  }

  Future<List<dynamic>> getAttendanceByEvent(String eventId) async {
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

  Future<List<dynamic>> getAttendanceByUser(String userId) async {
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

  Future<Map<String, dynamic>> updateAttendance(String id, Map<String, dynamic> attendanceData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/attendance/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(attendanceData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update attendance: ${response.body}');
    }
  }

  Future<void> deleteAttendance(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/attendance/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete attendance: ${response.body}');
    }
  }
}