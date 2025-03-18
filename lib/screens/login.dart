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

      // print(response['session']['user']['id']);

      // Extract and store the user ID
      extractAndStoreUserId(response);
      final String token = response['session']['access_token']!;

      await storage.write(
          key: 'auth_token',
          value: token
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      final userData = await userService.getUserById(userId!);
      print(userData['full_name']);
      print(userData['role']);

      if (userData['role'] != null ){

       if(userData['role'] == 'user'){
           Navigator.pushReplacementNamed(context, "/userDashboard");
       }else if(userData['role'] == 'admin'){
           Navigator.pushReplacementNamed(context, "/adminDashboard");
       }else if(userData['role'] == 'super_admin'){
           Navigator.pushReplacementNamed(context, "/super_admin_dashboard");
       }
      }else {
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
  void extractAndStoreUserId(Map<String, dynamic> response) async {
    final String userId = response['session']['user']['id']!;
    // print('Extracted User ID: $userId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
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