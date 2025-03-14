import 'package:flutter/material.dart';
import 'package:church_app/services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    final email = emailController.text;
    final password = passwordController.text;
    final response = await ApiService.login(email, password);

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      // Save role to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', response['role']);
      Navigator.pushNamed(context, '/adminDashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please check your credentials.')),
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
                  'Welcome to Church',
                  style: TextStyle(
                    fontSize: 45.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 100.0),
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Your Email Address',
                ),
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 40.0),
              isLoading
                  ? const Center(
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
                  onPressed: (){
                    Navigator.pushNamed(context, '/register');
                  }, 
                  child: Text('No account? Register')
              )
            ],
          ),
        ),
      ),
    );
  }
}



class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'user';
  bool isLoading = false;

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    final name = nameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final response = await ApiService.register(name, email, password, selectedRole);

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      Navigator.pushNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed. Please try again.')),
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
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 45.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 100.0),
              const Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Your Full Name',
                ),
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Your Email Address',
                ),
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30.0),
              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w100,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['super_admin', 'admin', 'user'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Role',
                ),
              ),
              const SizedBox(height: 40.0),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    )
                  : Center(
                      child: TextButton(
                        onPressed: _register,
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
              const SizedBox(height: 20.0),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
