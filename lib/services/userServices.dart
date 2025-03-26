import 'dart:convert';
import 'dart:io';
import 'package:church_app/constants/api_constants.dart';
import 'package:church_app/services/authServices.dart';
import 'package:church_app/services/http_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http/intercepted_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late http.Client client;

  UserService({required this.baseUrl}){
    client = InterceptedClient.build(interceptors: [
      TokenInterceptor(authService: AuthService(baseUrl: baseUrl))
    ]);
  }

  Future<String> uploadImage(String base64Image, String fileName) async {
    final token = await _secureStorage.read(key: 'auth_token');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');

    final response = await http.put(
      Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/users/$id/uploadimage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "image": base64Image, // Ensure this matches the backend field name
        "filename": fileName,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['url']; // Assuming server returns the URL
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }


  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch users: ${response.body}');
    }
  }

  Future<List<dynamic>> searchUsersByName(String name) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/search?name=$name'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search users: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      throw Exception('User ID not found in SharedPreferences');
    }

    final url = Uri.parse('$baseUrl/$userId');
    print('PUT URL: $url');
    print('User Data: $userData');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> deleteUser(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  Future<void> writeToken(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readToken(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteToken(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<Map<String, dynamic>> assignAdminToGroup(String groupId, String userId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/groups/assign-admin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'groupId': groupId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to assign admin to group: ${response.body}');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'role': newRole,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user role: ${response.body}');
    }
  }
}