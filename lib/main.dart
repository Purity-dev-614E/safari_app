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
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/screens/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:church_app/widgets/notification_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeSupabase();
  runApp(const MyApp());
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: "https://hubrwunvnuslutyykvli.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1YnJ3dW52bnVzbHV0eXlrdmxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3NjE4MzEsImV4cCI6MjA1NzMzNzgzMX0.GEUOfe5OKzBZY5zT-LlhagykiCMMznxCY5pqTwpLhas", // Use environment variables for security
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkLoginStatus()); // Ensures context is available
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('user_id');
    print('Retrieved user_id: $userId');

    if (userId == null) {
      _navigateTo('/login');
      return;
    }

    String? role = prefs.getString('user_role');
    print('User Role: $role');
    if (role == null) {
      _navigateTo('/login');
    } else {
      _setInitialRouteBasedOnRole(role);
    }
  }

  void _navigateTo(String route) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _setInitialRouteBasedOnRole(String role) {
    String route = switch (role) {
      'user' => '/userDashboard',
      'admin' => '/adminDashboard',
      'super_admin' => '/super_admin_dashboard',
      _ => '/updateProfile'
    };
    _navigateTo(route);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationOverlay(child: child!),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Login(),
        '/register': (context) => const Signup(),
        '/super_admin_dashboard': (context) => const SuperAdminDashboard(),
        '/UserManagement': (context) => const UserManagement(),
        '/SuperAnalytics': (context) => const SuperAnalytics(),
        '/SuperSettings': (context) => const SuperSettings(),
        '/userDashboard': (context) => const UserDashboard(),
        '/Profile': (context) => const UserProfileScreen(),
        '/updateProfile': (context) => const UpdateProfileScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/GroupMembers': (context) => const GroupMembers(),
        '/GroupAnalytics': (context) => const GroupAnalytics(),
        '/createEvent': (context) => const AddEventsScreen(),
      },
    );
  }
}