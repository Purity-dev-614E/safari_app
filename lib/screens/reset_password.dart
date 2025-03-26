import 'dart:convert';
import 'package:church_app/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': _emailController.text}),
    );

    setState(() {
      _isLoading = false;
      if (response.statusCode == 200) {
        _message = 'Password recovery email sent.';
      } else {
        _message = 'Failed to send password recovery email.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              child: Text('Send Password Reset Email'),
            ),
            if (_message != null) ...[
              SizedBox(height: 20),
              Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}