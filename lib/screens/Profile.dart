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
  String? _full_name = '';
  String? _email = '';
  String? _gender = '';
  String? _location = '';

  final UserService _userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api/users');

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      try {
        final imageUrl = await _userService.uploadProfilePicture(_image!);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('user_id');
        if (userId != null) {
          await _userService.updateUserProfile(userId, {'profile_picture': imageUrl});
          setState(() {
            _image = File(imageUrl);
          });
        }
      } catch (e) {
        print('Failed to upload image: $e');
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;

    try {
      final data = await _userService.getUserById(userId);
      setState(() {
        _full_name = data['full_name'] ?? '';
        _email = data['email'] ?? '';
        _location = data['location'] ?? '';
        _gender = data['gender'] ?? '';
        _image = data['profile_picture'] != null ? File(data['profile_picture']) : null;
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