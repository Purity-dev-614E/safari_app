import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/authServices.dart';
import '../services/userServices.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/custom_notification.dart';
import '../constants/api_constants.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  final AuthService authService = AuthService(baseUrl: ApiConstants.baseUrl);
  final UserService userService = UserService(baseUrl: ApiConstants.usersUrl);
  final storage = const FlutterSecureStorage();

  Future<void> _login() async {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      NotificationOverlay.of(context).showNotification(
        message: 'Email and password cannot be empty',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await authService.logIn(email, password);

      // Add null checks and default values
      final accessToken = response['session']?['access_token'] ?? '';


      if (accessToken.isEmpty) {
        throw Exception('Access token is missing in the response');
      }

      await storage.write(key: 'auth_token', value: accessToken);


      setState(() {
        isLoading = false;
      });

      await extractAndStoreUserData(response);
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString('user_role') ?? 'guest'; // Default to 'guest'
      print('User  role retrieved: $role');

        switch (role) {
          case 'user':
            Navigator.pushReplacementNamed(context, "/userDashboard");
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, "/adminDashboard");
            break;
        case 'super admin':
            Navigator.pushReplacementNamed(context, "/super_admin_dashboard");
            break;
          default:
        Navigator.pushReplacementNamed(context, "/updateProfile");
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Login failed: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }

  Future<void> extractAndStoreUserData(Map<String, dynamic> response) async {
    // Add null checks and default values
    final String userId = response['user']?['id'] ?? '';
    if (userId.isEmpty) {
      throw Exception('User  ID is missing in the response');
    }

    final userData = await userService.getUserById(userId);
    final userRole = userData['role'] ?? ''; // Default to 'guest'
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', userRole);
  }

  Future<void> _resetPassword() async {
    final email = emailController.text;

    if (email.isEmpty) {
      NotificationOverlay.of(context).showNotification(
        message: 'Please enter your email address',
        type: NotificationType.warning,
      );
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

      if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Password Reset Email Sent'),
                ],
              ),
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
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      NotificationOverlay.of(context).showNotification(
        message: 'Failed to send reset email: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Icon(
                        Icons.church,
                        size: 80,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
              Center(
                child: Text(
                  'Welcome to Church',
                  style: TextStyle(
                        fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        letterSpacing: 1.5,
                  ),
                ),
              ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign in to continue',
                style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.blue.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              TextField(
                controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email, color: Colors.blue.shade700),
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
                              borderSide: BorderSide(color: Colors.blue.shade700),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                        ),
                        const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                  labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.blue.shade700,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
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
                              borderSide: BorderSide(color: Colors.blue.shade700),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                        ),
                        const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                            child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                                color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                    style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/register");
                },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}