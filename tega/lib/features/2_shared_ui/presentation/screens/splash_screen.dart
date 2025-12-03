import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_screen.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Initialize the video controller from the asset.
    _videoController = VideoPlayerController.asset('assets/splash_video.mp4');

    // Store the initialization future to use with a FutureBuilder.
    _initializeVideoPlayerFuture = _videoController
        .initialize()
        .then((_) {
          // Ensure the video plays only once.
          _videoController.setLooping(false);
          // Start playback immediately.
          _videoController.play();
        })
        .catchError((error) {
          debugPrint("Video initialization failed: $error");
          if (mounted) {
            setState(() {
              _hasError = true;
            });
            // Fallback navigation if video fails
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _navigateBasedOnSession();
            });
          }
        });

    // Add a listener to navigate after the video completes.
    _videoController.addListener(() {
      // If we have an error, we rely on the timer above, not this listener.
      if (_hasError) return;

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
      } else if (_authService.hasRole(UserRole.principal)) {
        _navigateToCollegeDashboard();
      } else if (_authService.hasRole(UserRole.student)) {
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

      if (!mounted) {
        return; // Always check if the widget is mounted before async navigation.
      }

      if (colleges.isNotEmpty) {
        Navigator.of(
          context,
        ).pushReplacement(_createFadeRoute(DashboardScreen()));
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
            // If initialization is done (success or error handled in catchError)
            if (snapshot.connectionState == ConnectionState.done) {
              // Remove native splash once we are ready to show something
              FlutterNativeSplash.remove();

              if (_hasError || !_videoController.value.isInitialized) {
                // Fallback UI
                return Center(
                  child: Image.asset(
                    'assets/splash_logo.png',
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        size: 50,
                        color: Colors.red,
                      );
                    },
                  ),
                );
              }

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
