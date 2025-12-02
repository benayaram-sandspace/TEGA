import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tega/core/config/env_config.dart';
import 'package:tega/core/widgets/keyboard_dismisser.dart';
import 'package:tega/features/2_shared_ui/presentation/screens/splash_screen.dart';

/// Store available cameras globally so any page can use them
late final List<CameraDescription> cameras;

Future<void> main() async {
  // Ensure widgets are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await EnvConfig.initialize();

  if (EnvConfig.enableDebugLogs) {
    EnvConfig.printAll();
  }

  // Keep the native splash screen on screen until it is removed manually
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

      // Light theme only - consistent with app color palette
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF9C88FF),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C88FF),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          surfaceTintColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Roboto',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF9C88FF),
          unselectedItemColor: Colors.grey,
        ),
      ),

      // Force light theme only
      themeMode: ThemeMode.light,

      // Wrap with KeyboardDismisser to auto-dismiss keyboard on tap outside
      builder: (context, child) {
        return KeyboardDismisser(child: child ?? const SizedBox.shrink());
      },

      // Start with splash screen
      home: const SplashScreen(),
    );
  }
}
