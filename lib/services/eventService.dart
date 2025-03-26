import 'dart:convert';
import 'package:church_app/services/authServices.dart';
import 'package:church_app/services/http_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http/intercepted_client.dart';

class EventService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late http.Client client;

  EventService({required this.baseUrl}){
    client = InterceptedClient.build(interceptors: [
      TokenInterceptor(authService: AuthService(baseUrl: baseUrl))
    ]);
  }

  Future<Map<String, dynamic>> createEvent(String groupId, Map<String, dynamic> eventData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/events/group/$groupId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create event: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getEventById(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch event: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllEvents() async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch events: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateEvent(String id, Map<String, dynamic> eventData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/events/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update event: ${response.body}');
    }
  }

  Future<void> deleteEvent(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete event: ${response.body}');
    }
  }

  Future<List<dynamic>> getEventsByGroup(String groupId) async {
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