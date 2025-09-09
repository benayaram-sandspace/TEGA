import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  // debug to confirm app start
  // ignore: avoid_print
  print('main(): starting app');
  
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TEGA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.light,
        ),
      ),
      // Start the app with the splash screen
      home: const SplashScreen(),
    );
  }
}
