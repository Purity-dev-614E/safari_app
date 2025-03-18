import 'package:church_app/services/tokenService.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userServices.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _image;
  String? _imageUrl;
  final picker = ImagePicker();
  String? _full_name = '';
  String? _email = '';
  String? _gender = '';
  String? _location = '';
  bool _isLoading = false;

  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true;
        });

        try {
          final imageUrl = await _userService.uploadProfilePicture(_image!);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? userId = prefs.getString('user_id');
          
          if (userId != null) {
            await _userService.updateUserProfile(userId, {'profile_picture': imageUrl});
            setState(() {
              _imageUrl = imageUrl;
              _isLoading = false;
            });
            
            NotificationOverlay.of(context).showNotification(
              message: 'Profile picture updated successfully',
              type: NotificationType.success,
            );
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          NotificationOverlay.of(context).showNotification(
            message: 'Failed to upload image: $e',
            type: NotificationType.error,
          );
        }
      }
    } catch (e) {
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to pick image: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
    });

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
        _imageUrl = data['profile_picture'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to fetch user info: $e',
        type: NotificationType.error,
      );
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
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchUserInfo,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _image != null 
                                          ? Image.file(
                                              _image!,
                                              fit: BoxFit.cover,
                                            )
                                          : (_imageUrl != null && _imageUrl!.isNotEmpty
                                              ? Image.network(
                                                  _imageUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.blue.shade50,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: Colors.blue.shade300,
                                                  ),
                                                )),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade700,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _full_name ?? 'Not set',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _email ?? 'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.person_outline,
                              "Gender",
                              _gender ?? 'Not set',
                            ),
                            const Divider(height: 30),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              "Location",
                              _location ?? 'Not set',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () async {
                            await SecureStorageService().deleteToken('auth_token');
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}