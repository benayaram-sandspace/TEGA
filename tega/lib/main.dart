import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tega/pages/home_screens/splash_screen.dart';

/// Store available cameras globally so any page can use them
late final List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get list of device cameras
  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      // Start with splash screen
      home: const SplashScreen(),
    );
  }
}
