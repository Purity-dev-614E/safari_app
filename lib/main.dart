import 'package:church_app/screens/GroupAnalytics.dart';
import 'package:church_app/screens/GroupMembers.dart';
import 'package:church_app/screens/Profile.dart';
import 'package:church_app/screens/SuperAnalytics.dart';
import 'package:church_app/screens/SuperSettings.dart';
import 'package:church_app/screens/Updatescreen.dart';
import 'package:church_app/screens/UserManagement.dart';
import 'package:church_app/screens/adminDashboard.dart';
import 'package:church_app/screens/register.dart';
import 'package:church_app/screens/super_admin_dashoard.dart';
import 'package:church_app/screens/userDashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> userInfo = await getUserInfo();
  runApp(MyApp(userInfo: userInfo));
}

Future<Map<String, dynamic>> getUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  String? role = prefs.getString('user_role');
  String? fullName = prefs.getString('full_name');
  String? email = prefs.getString('email');
  return {
    'loggedIn': token != null,
    'role': role,
    'profileComplete': fullName != null && email != null,
  };
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> userInfo;
  MyApp({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!userInfo['loggedIn']) {
      home = Login();
    } else if (!userInfo['profileComplete']) {
      home = UpdateProfileScreen();
    } else {
      home = _getHomeScreen(userInfo['role']);
    }

    return MaterialApp(
      home: home,
      onGenerateRoute: (settings) {
        if (settings.name == '/adminDashboard') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => AdminDashboard(groupId: groupId),
          );
        } else if (settings.name == '/GroupAnalytics') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => GroupAnalytics(groupId: groupId),
          );
        } else if (settings.name == '/GroupMembers') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => GroupMembers(groupId: groupId),
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => Login(),
        '/register': (context) => Signup(),
        '/super_admin_dashboard': (context) => SuperAdminDashboard(),
        '/UserManagement': (context) => UserManagement(),
        '/SuperAnalytics': (context) => SuperAnalytics(),
        '/SuperSettings': (context) => SuperSettings(),
        '/userDashboard': (context) => UserDashboard(),
        '/Profile': (context) => UserProfileScreen(),
      },
    );
  }

  Widget _getHomeScreen(String role) {
    switch (role) {
      case 'super_admin':
        return SuperAdminDashboard();
      case 'admin':
        return AdminDashboard(groupId: 'defaultGroupId'); // Provide a default or initial group ID
      case 'user':
        return UserDashboard();
      default:
        return Login();
    }
  }
}

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => Login()),
        (route) => false,
  );
}