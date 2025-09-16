import 'package:flutter/material.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_screen.dart';
import 'package:tega/pages/college_screens/dashboard/dashboard_styles.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: DashboardStyles.background,
        fontFamily: 'Inter',
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
