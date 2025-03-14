import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/authServices.dart'; // Import the AuthService

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final AuthService authService = AuthService(baseUrl: 'https://yourapi.com');  // Initialize AuthService with your base URL

  Future<void> _signup() async {
    setState(() {
      isLoading = true;
    });

    final email = emailController.text;
    final password = passwordController.text;

    try {
      final response = await authService.signUp(email, password);

      setState(() {
        isLoading = false;
      });

      if (response != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        await prefs.setString('user_role', response['role']);
        await prefs.setString('full_name', response['full_name']);
        await prefs.setString('email', response['email']);

        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    }
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
                  'Sign Up to Church',
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
                  onPressed: _signup,
                  child: const Text(
                    'SIGN UP',
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
                  Navigator.pushReplacementNamed(context, "/login");
                },
                child: const Text('Already have an account? Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}