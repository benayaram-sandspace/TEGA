import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/pages/admin_screens/admin_related_pages/admin_dashboard.dart';
import 'package:tega/pages/login_screens/login_page.dart';
import 'package:tega/pages/student_screens/student_home_page.dart';
import 'package:tega/pages/college_dashboard/college_dashboard_main.dart';
import 'package:tega/services/college_service.dart';
import 'package:tega/services/auth_service.dart';
import 'package:video_player/video_player.dart';

/// A splash screen that plays a video and then navigates to the appropriate screen
/// with a smooth fade transition.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Initialize the video controller from the asset.
    _videoController = VideoPlayerController.asset('assets/splash_video.mp4');

    // Store the initialization future to use with a FutureBuilder.
    _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
      // Ensure the video plays only once.
      _videoController.setLooping(false);
      // Start playback immediately.
      _videoController.play();
    });

    // Add a listener to navigate after the video completes.
    _videoController.addListener(() {
      final isInitialized = _videoController.value.isInitialized;
      final isFinished =
          _videoController.value.duration == _videoController.value.position;

      if (isInitialized && isFinished) {
        // Use a small delay to ensure the last frame is shown briefly before navigating.
        Future.delayed(const Duration(milliseconds: 500), () {
          // Check if the widget is still in the tree before navigating.
          if (!mounted) return;
          _navigateBasedOnSession();
        });
      }
    });

    // Initialize the user session.
    _authService.initializeSession();
  }

  /// Creates a custom page route with a smooth fade-in animation.
  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      // Set the duration of the transition.
      transitionDuration: const Duration(milliseconds: 750),
    );
  }

  /// Checks the user's session and navigates to the appropriate screen.
  void _navigateBasedOnSession() {
    if (_authService.isSessionValid()) {
      if (_authService.isAdmin) {
        Navigator.of(
          context,
        ).pushReplacement(_createFadeRoute(const AdminDashboard()));
      } else if (_authService.hasRole(UserRole.moderator)) {
        _navigateToCollegeDashboard();
      } else if (_authService.hasRole(UserRole.user)) {
        Navigator.of(
          context,
        ).pushReplacement(_createFadeRoute(const StudentHomePage()));
      } else {
        // Fallback for unrecognized roles.
        Navigator.of(
          context,
        ).pushReplacement(_createFadeRoute(const LoginPage()));
      }
    } else {
      // Navigate to login if the session is not valid.
      Navigator.of(
        context,
      ).pushReplacement(_createFadeRoute(const LoginPage()));
    }
  }

  /// Fetches college data and navigates to the college dashboard.
  Future<void> _navigateToCollegeDashboard() async {
    try {
      final collegeService = CollegeService();
      final colleges = await collegeService.loadColleges();

      if (!mounted)
        return; // Always check if the widget is mounted before async navigation.

      if (colleges.isNotEmpty) {
        final college = colleges.first;
        Navigator.of(context).pushReplacement(
          _createFadeRoute(CollegeDashboardMain(college: college)),
        );
      } else {
        Navigator.of(
          context,
        ).pushReplacement(_createFadeRoute(const LoginPage()));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(_createFadeRoute(const LoginPage()));
    }
  }

  @override
  void dispose() {
    // Free up resources by disposing of the controller.
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A black background is often best for video splash screens.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // Once the video is ready, remove the native splash screen.
              FlutterNativeSplash.remove();

              // This structure ensures the video is centered and not cropped.
              return Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              );
            } else {
              // The native splash is visible, so we return an empty container.
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
