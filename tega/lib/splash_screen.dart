import 'dart:async';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/admin_dashboard.dart';
import 'home_page.dart';
import 'services/auth_service.dart';
import 'constants/app_colors.dart';

/// A splash screen that matches the original TEGA design with circular logo,
/// yellow ring, red text, green icon, and magnifying glass
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  // late Animation<double> _rotationAnimation; // Unused for now
  int _countdown = 3;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // _rotationAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(CurvedAnimation(
    //   parent: _rotationController,
    //   curve: Curves.linear,
    // ));
    
    // Start animations
    _animationController.forward();
    _rotationController.repeat();
    
    // Start countdown timer
    _startCountdown();
    
    // Initialize session immediately (non-blocking)
    _authService.initializeSession();
    
    // Navigate after exactly 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _navigateBasedOnSession();
    });
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdown--;
      });
      
      if (_countdown <= 0) {
        timer.cancel();
      }
    });
  }

  void _navigateBasedOnSession() {
    // Check if user is already logged in
    if (_authService.isSessionValid()) {
      // User is logged in, navigate to appropriate dashboard
      if (_authService.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage(title: 'TEGA')),
        );
      }
    } else {
      // User is not logged in, go to login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Logo Container with Yellow Ring
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: screenWidth * 0.7,
                      height: screenWidth * 0.7,
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        maxHeight: 300,
                        minWidth: 250,
                        minHeight: 250,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary, // Yellow ring
                          width: 8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.pureWhite,
                              shape: BoxShape.circle,
                            ),
                          ),
                          
                          // Main splash logo image
                          Container(
                            width: screenWidth * 0.6,
                            height: screenWidth * 0.6,
                            constraints: const BoxConstraints(
                              maxWidth: 250,
                              maxHeight: 250,
                              minWidth: 200,
                              minHeight: 200,
                            ),
                            child: Image.asset(
                              'assets/splash_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.pureWhite,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.school,
                                    size: 80,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // TEGA Title with Red Text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'TEGA',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline
                  Text(
                    'Your Path to Job-Ready Confidence',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary, // Orange color like in the image
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Countdown display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Launching in $_countdown...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Progress indicator
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.deepBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.deepBlue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepBlue),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
