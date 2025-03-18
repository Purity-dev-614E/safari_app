import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userServices.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _role;
  String? _gender;
  String? _location;
  String? _nextOfKin;
  String? _nextOfKinContact;
  String? _phoneNumber;
  bool _isLoading = false;

  final UserService _userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/users');

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _userService.updateUser({
          'full_name': _fullName?.toLowerCase(),
          'role': _role?.toLowerCase(),
          'gender': _gender?.toLowerCase(),
          'location': _location?.toLowerCase(),
          'next_of_kin_name': _nextOfKin?.toLowerCase(),
          'next_of_kin_contact': _nextOfKinContact?.toLowerCase(),
          'phone_number': _phoneNumber,
        });

        if (response.containsKey('id') && response['role'] != null) {
          await prefs.setString('full_name', _fullName!);
          await prefs.setString('user_role', _role!);

          if (mounted) {
            NotificationOverlay.of(context).showNotification(
              message: 'Profile updated successfully',
              type: NotificationType.success,
            );

            // Navigate based on role
            switch (response['role']) {
              case 'super admin':
                Navigator.pushReplacementNamed(context, '/super_admin_dashboard');
                break;
              case 'admin':
                Navigator.pushReplacementNamed(context, '/adminDashboard');
                break;
              case 'user':
                Navigator.pushReplacementNamed(context, '/userDashboard');
                break;
              default:
                Navigator.pushReplacementNamed(context, '/login');
            }
          }
        } else {
          if (mounted) {
            NotificationOverlay.of(context).showNotification(
              message: 'Failed to update profile: ${response['message']}',
              type: NotificationType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          NotificationOverlay.of(context).showNotification(
            message: 'Failed to update profile: $e',
            type: NotificationType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Update Profile",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personal Information Section
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Full Name",
                          (value) => _fullName = value,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          'Role',
                          (value) => _role = value,
                          icon: Icons.work,
                        ),
                        _buildTextField(
                          "Gender",
                          (value) => _gender = value,
                          icon: Icons.person_outline,
                        ),
                        _buildTextField(
                          "Location",
                          (value) => _location = value,
                          icon: Icons.location_on,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact Information Section
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.contact_phone,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPhoneNumberField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Emergency Contact Section
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emergency,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Emergency Contact',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Next of Kin",
                          (value) => _nextOfKin = value,
                          icon: Icons.contact_phone,
                        ),
                        _buildNextOfKinNumberField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onSave, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue.shade700) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.blue.shade50,
          labelStyle: TextStyle(color: Colors.blue.shade700),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onSaved: (value) => onSave(value!),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Phone Number',
          prefixIcon: Icon(Icons.phone, color: Colors.blue.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.blue.shade50,
          labelStyle: TextStyle(color: Colors.blue.shade700),
        ),
        validator: (value) {
          if (value == null || !value.startsWith('+254')) {
            return 'Phone number must start with +254';
          }
          return null;
        },
        onSaved: (value) => _phoneNumber = value,
      ),
    );
  }

  Widget _buildNextOfKinNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Next of Kin Phone Number',
          prefixIcon: Icon(Icons.phone, color: Colors.blue.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.blue.shade50,
          labelStyle: TextStyle(color: Colors.blue.shade700),
        ),
        validator: (value) {
          if (value == null || !value.startsWith('+254')) {
            return 'Phone number must start with +254';
          }
          return null;
        },
        onSaved: (value) => _nextOfKinContact = value,
      ),
    );
  }
}