import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GroupService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  GroupService({required this.baseUrl}) : assert(!baseUrl.endsWith('/'), 'baseUrl should not end with a slash');

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> groupData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(groupData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create group: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getGroupById(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch group: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllGroups() async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/groups'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch groups: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateGroup(String id, Map<String, dynamic> groupData) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/groups/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(groupData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update group: ${response.body}');
    }
  }

  Future<void> deleteGroup(String id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete group: ${response.body}');
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

  Future<Map<String, dynamic>> addGroupMember(String groupId, String userId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add group member: ${response.body}');
    }
  }


  Future<Map<String, dynamic>> addGroupMemberByEmail(String groupId, String email) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add group member by email: ${response.body}');
    }
  }


  Future<void> removeGroupMember(String groupId, String userId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to remove group member: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> assignAdminToGroup(String groupId, String userId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/groups/assign-admin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'groupId': groupId, 'userId': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to assign admin to group: ${response.body}');
    }
  }


 Future<Map<String, dynamic>> getGroupByName(String name) async {
   final token = await _secureStorage.read(key: 'auth_token');
   final response = await http.get(
     Uri.parse('$baseUrl/groups?name=$name'),
     headers: {
       'Content-Type': 'application/json',
       'Authorization': 'Bearer $token',
     },
   );

   if (response.statusCode == 200) {
     final List<dynamic> groups = jsonDecode(response.body);
     if (groups.isNotEmpty) {
       return groups.first as Map<String, dynamic>;
     } else {
       throw Exception('Group not found');
     }
   } else {
     throw Exception('Failed to fetch group by name: ${response.body}');
   }
 }
}

