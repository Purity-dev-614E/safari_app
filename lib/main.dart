import 'package:church_app/screens/GroupAnalytics.dart';
import 'package:church_app/screens/GroupMembers.dart';
import 'package:church_app/screens/Profile.dart';
import 'package:church_app/screens/SuperAnalytics.dart';
import 'package:church_app/screens/SuperSettings.dart';
import 'package:church_app/screens/Updatescreen.dart';
import 'package:church_app/screens/UserManagement.dart';
import 'package:church_app/screens/adminDashboard.dart';
import 'package:church_app/screens/adminEventList.dart';
import 'package:church_app/screens/register.dart';
import 'package:church_app/screens/super_admin_dashoard.dart';
import 'package:church_app/screens/userDashboard.dart';
import 'package:church_app/services/userServices.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/screens/login.dart';
import 'package:church_app/screens/userDashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: "https://hubrwunvnuslutyykvli.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1YnJ3dW52bnVzbHV0eXlrdmxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3NjE4MzEsImV4cCI6MjA1NzMzNzgzMX0.GEUOfe5OKzBZY5zT-LlhagykiCMMznxCY5pqTwpLhas"
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _checkLoginStatus(BuildContext context) async {
    final UserService userService = UserService(baseUrl: 'https://safari-backend-3dj1.onrender.com/api/users');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    print('The users_id is: $userId');

    if (userId == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } else {
      final userData = await userService.getUserById(userId);

      if (userData['role'] != null) {
        if (userData['role'] == 'user') {
          Navigator.pushReplacementNamed(context, "/userDashboard");
        } else if (userData['role'] == 'admin') {
          Navigator.pushReplacementNamed(context, "/adminDashboard");
        } else if (userData['role'] == 'super admin') {
          Navigator.pushReplacementNamed(context, "/super_admin_dashboard");
        }
      } else {
        Navigator.pushReplacementNamed(context, "/updateProfile");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          _checkLoginStatus(context);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      routes: {
        '/login': (context) => const Login(),
        '/register': (context) => const Signup(),
        '/super_admin_dashboard': (context) => const SuperAdminDashboard(),
        '/UserManagement': (context) => const UserManagement(),
        '/SuperAnalytics': (context) => const SuperAnalytics(),
        '/SuperSettings': (context) => const SuperSettings(),
        '/userDashboard': (context) => const UserDashboard(),
        '/Profile': (context) => const UserProfileScreen(),
        '/updateProfile': (context) => const UserProfileScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/GroupMembers': (context) => const GroupMembers(),
        '/GroupAnalytics': (context) => const GroupAnalytics(),
        '/createEvent': (context) => const AddEventsScreen(),

      },


    );
  }
}