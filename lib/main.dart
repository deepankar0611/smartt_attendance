import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartt_attendance/bottom_navigation_bar.dart';
import 'package:smartt_attendance/screen/attendance-screen.dart';
import 'package:smartt_attendance/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartt_attendance/screen/profile%20page.dart';

import 'firebase_options.dart';
import 'models/bottom_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
     const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return  LocationBottomSheet();
          } else {
            return  HomeScreen();
          }
        },
      ),
    );
  }
}
