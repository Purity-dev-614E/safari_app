import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/authServices.dart'; // Import the AuthService

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final AuthService authService = AuthService(baseUrl: 'https://yourapi.com');  // Initialize AuthService with your base URL

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

      if (response != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        await prefs.setString('user_role', response['role']);
        await prefs.setString('full_name', response['full_name']);
        await prefs.setString('email', response['email']);

        Map<String, dynamic> userInfo = {
          'loggedIn': true,
          'role': response['role'],
          'profileComplete': response['full_name'] != null && response['email'] != null,
        };

        // Navigate based on role
        if (!userInfo['profileComplete']) {
          Navigator.pushReplacementNamed(context, '/updateProfile');
        } else {
          switch (userInfo['role']) {
            case 'super_admin':
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
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      _showError('Login failed: ${e.toString()}');
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
              SizedBox(height: 40.0),
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