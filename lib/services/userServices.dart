import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserService({required this.baseUrl});

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

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> userData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final url =   Uri.parse('$baseUrl/$id');
    print(url);


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
}