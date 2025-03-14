import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/userServices.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _email;
  String? _role;
  String? _gender;
  String? _location;
  String? _nextOfKin;
  String? _nextOfKinContact;

  final UserService _userService = UserService(baseUrl: 'http://your-backend-url.com/api');

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      if (userId == null) return;

      try {
        final response = await _userService.updateUser(userId, {
          'full_name': _fullName,
          'email': _email,
          'role': _role,
          'gender': _gender,
          'location': _location,
          'next_of_kin': _nextOfKin,
          'next_of_kin_contact': _nextOfKinContact,
        });

        await prefs.setString('full_name', _fullName!);
        await prefs.setString('email', _email!);
        await prefs.setString('user_role', _role!);
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        print('Failed to update profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Full Name", (value) => _fullName = value),
              _buildTextField("Email", (value) => _email = value),
              _buildTextField('Role', (value) => _role = value),
              _buildTextField("Gender", (value) => _gender = value),
              _buildTextField("Location", (value) => _location = value),
              _buildTextField("Next of Kin", (value) => _nextOfKin = value),
              _buildTextField("Next of Kin Contact", (value) => _nextOfKinContact = value),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
}