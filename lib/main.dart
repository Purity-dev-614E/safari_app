import 'package:church_app/screens/GroupAnalytics.dart';
import 'package:church_app/screens/GroupMembers.dart';
import 'package:church_app/screens/Profile.dart';
import 'package:church_app/screens/SuperAnalytics.dart';
import 'package:church_app/screens/SuperSettings.dart';
import 'package:church_app/screens/Updatescreen.dart';
import 'package:church_app/screens/UserManagement.dart';
import 'package:church_app/screens/adminDashboard.dart';
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
      switch (userInfo['role']) {
        case 'super_admin':
          home = SuperAdminDashboard();
          break;
        case 'admin':
          home = AdminDashboard();
          break;
        case 'user':
          home = UserDashboard();
          break;
        default:
          home = Login();
      }
    }

    return MaterialApp(
      home: home,
      routes: {
        '/login': (context) => Login(),
        '/register': (context) => Register(),
        '/super_admin_dashboard': (context) => SuperAdminDashboard(),
        '/adminDashboard': (context) => AdminDashboard(),
        '/UserManagement': (context) => UserManagement(),
        '/SuperAnalytics': (context) => Superanalytics(),
        '/SuperSettings': (context) => Supersettings(),
        '/GroupMembers': (context) => GroupMembers(),
        '/GroupAnalytics': (context) => Groupanalytics(),
        '/userDashboard': (context) => UserDashboard(),
        '/Profile': (context) => UserProfileScreen(),
        '/CreateGroup': (context) => CreateGroupScreen()
      },
    );
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