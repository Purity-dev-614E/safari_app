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
  String? _role;
  String? _gender;
  String? _location;
  String? _nextOfKin;
  String? _nextOfKinContact;
  String? _phoneNumber;

  final UserService _userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api/users');

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      SharedPreferences prefs = await SharedPreferences.getInstance();

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

        print('Response from updateUser: $response');

        if (response.containsKey('id') && response['role'] != null) {
          await prefs.setString('full_name', _fullName!);
          await prefs.setString('user_role', _role!);

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
        } else {
          print('Failed to update profile because: ${response['message']}');
        }
      } catch (e) {
        print('Failed to update profile why?: $e');
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
              _buildTextField('Role', (value) => _role = value),
              _buildTextField("Gender", (value) => _gender = value),
              _buildTextField("Location", (value) => _location = value),
              _buildTextField("Next of Kin", (value) => _nextOfKin = value),
              _buildTextField("Next of Kin Contact", (value) => _nextOfKinContact = value),
              _buildPhoneNumberField(),
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

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Phone Number',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
          labelText: 'Phone Number',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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