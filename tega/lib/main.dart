import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:tega/pages/home_screens/splash_screen.dart';
import 'package:tega/pages/providers/theme_provider.dart';


/// Store available cameras globally so any page can use them
late final List<CameraDescription> cameras;

Future<void> main() async {
  // Ensure widgets are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash screen on screen until it is removed manually
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Get list of device cameras
  cameras = await availableCameras();

  // UPDATED: Wrap the app with the ThemeProvider so the whole app can access it
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // UPDATED: Use a Consumer to listen for theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TEGA',

          // UPDATED: Define a clear and consistent light theme
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF6B5FFF),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6B5FFF),
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
                fontFamily: 'Roboto', // Example: Ensure consistent font
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF6B5FFF),
              unselectedItemColor: Colors.grey,
            ),
          ),

          // UPDATED: Define a clear and consistent dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF7D75FF),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7D75FF),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              elevation: 1,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1F1F1F),
              selectedItemColor: Color(0xFF7D75FF),
              unselectedItemColor: Colors.grey,
            ),
          ),

          // UPDATED: Set the themeMode based on the provider's state
          themeMode: themeProvider.themeMode,

          // Start with splash screen
          home: const SplashScreen(),
        );
      },
    );
  }
}
