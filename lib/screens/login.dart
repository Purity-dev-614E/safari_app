import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/authServices.dart';
import '../services/userServices.dart'; // Import the AuthService

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final AuthService authService = AuthService(baseUrl: 'https://safari-backend.on.shiper.app/api');// Initialize AuthService with your base URL
  final UserService userService = UserService(baseUrl: 'https://safari-backend.on.shiper.app/api/users');
  final storage = const FlutterSecureStorage();
  Future<void> _login() async {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email and password cannot be empty');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await authService.logIn(email, password);

      setState(() {
        isLoading = false;
      });

      // Extract and store the user ID and role
      await extractAndStoreUserData(response);
      
      // Store tokens in secure storage
      final String accessToken = response['session']['access_token']!;
      final String refreshToken = response['session']['refresh_token']!;
      
      await storage.write(key: 'auth_token', value: accessToken);
      await storage.write(key: 'refresh_token', value: refreshToken);

      // Get user role from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString('user_role');

      // Navigate based on role
      if (role != null) {
        switch (role) {
          case 'user':
            Navigator.pushReplacementNamed(context, "/userDashboard");
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, "/adminDashboard");
            break;
          case 'super_admin':
            Navigator.pushReplacementNamed(context, "/super_admin_dashboard");
            break;
          default:
            Navigator.pushReplacementNamed(context, "/updateProfile");
        }
      } else {
        Navigator.pushReplacementNamed(context, "/updateProfile");
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
      _showError('Login failed: ${e.toString()}');
    }
  }

  Future<void> extractAndStoreUserData(Map<String, dynamic> response) async {
    final String userId = response['session']['user']['id']!;
    final String role = response['session']['user']['role'] ?? '';
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', role);
  }

  Future<void> _resetPassword() async {
    final email = emailController.text;

    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await authService.resetPassword(email);
      
      setState(() {
        isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Password Reset Email Sent'),
            content: const Text(
              'Please check your email for instructions to reset your password. '
              'If you don\'t see the email, please check your spam folder.'
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Failed to send reset email: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 100, 30, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Welcome to Church',
                  style: TextStyle(
                    fontSize: 45.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              SizedBox(height: 100.0),
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Your Email Address',
                ),
              ),
              SizedBox(height: 30.0),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
                  : Center(
                child: TextButton(
                  onPressed: _login,
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/register");
                },
                child: const Text('No account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}