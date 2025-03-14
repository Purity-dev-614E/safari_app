import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userServices.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _image;
  final picker = ImagePicker();
  String? _full_name;
  String? _email;
  String? _gender;
  String? _role;
  String? _location;
  // String? _next_of_kin;
  // String? _next_of_kin_contact;

  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;

    try {
      final data = await _userService.getUserById(userId);
      setState(() {
        _full_name = data['full_name'];
        _email = data['email'];
        _role = data['role'];
        _location = data['location'];
        _gender = data['gender'];
        // _next_of_kin = data['next_of_kin'];
        // _next_of_kin_contact = data['next_of_kin_contact'];
        // Assuming the image URL is returned in the response
        _image = File(data['profile_picture']);
      });
    } catch (e) {
      print('Failed to fetch user info: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow("Name", _full_name),
            _buildInfoRow("Email", _email),
            _buildInfoRow("Role", _role),
            _buildInfoRow("Gender", _gender),
            _buildInfoRow("Location", _location),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Handle logout
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? "", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}