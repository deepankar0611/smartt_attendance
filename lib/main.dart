// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartt_attendance/admin%20screen/admin_bottom_nav.dart';
import 'package:smartt_attendance/student%20screen/bottom_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartt_attendance/student%20screen/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartt_attendance/providers/attendance_screen_provider.dart';
import 'package:smartt_attendance/providers/profile_screen_provider.dart';
import 'package:smartt_attendance/providers/attendance_history_provider.dart';
import 'package:smartt_attendance/providers/leave_provider.dart';
import 'package:smartt_attendance/providers/leave_history_provider.dart';
import 'package:smartt_attendance/providers/admin_dashboard_provider.dart';
import 'package:smartt_attendance/providers/employee_list_provider.dart';
import 'package:smartt_attendance/providers/admin_profile_provider.dart';
import 'firebase_options.dart';
import 'Splashscreen.dart';
import 'welcome.dart'; // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await sp.Supabase.initialize(
    url: 'https://xzoyevujxvqaumrdskhd.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6b3lldnVqeHZxYXVtcmRza2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyMTE1MjMsImV4cCI6MjA1NDc4NzUyM30.mbV_Scy2fXbMalxVRGHNKOxYx0o6t-nUPmDLlH5Mr_U',
  );
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialHomePage() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    try {
      // Check if user has seen welcome screen
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      bool hasSeenWelcome = userDoc.exists && userDoc['hasSeenWelcome'] == true;

      if (!hasSeenWelcome) {
        return WelcomeScreen();
      }

      // Check student role
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (studentDoc.exists) {
        return const HomeScreen();
      }

      // Check teacher role
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .get();

      if (teacherDoc.exists) {
        return const AdminBottomNav();
      }

      return const LoginScreen();
    } catch (e) {
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceScreenProvider()),
        ChangeNotifierProvider(create: (_) => ProfileScreenProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceHistoryProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => LeaveHistoryProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeListProvider()),
        ChangeNotifierProvider(create: (_) => AdminProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FutureBuilder<Widget>(
          future: _getInitialHomePage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return snapshot.data!;
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}