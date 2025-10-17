import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/forgot_password_page.dart';
import 'package:tega/features/1_authentication/presentation/screens/signup_page.dart';
import 'package:tega/features/2_shared_ui/presentation/screens/home_page.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_screen.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String _selectedLanguage = 'EN';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1200;

  // Get responsive values
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // Responsive sizing
  double get maxFormWidth {
    if (isDesktop) return 450;
    if (isTablet) return 500;
    return double.infinity;
  }

  double get horizontalPadding {
    if (isDesktop) return 48;
    if (isTablet) return 32;
    return 24;
  }

  double get logoSize {
    if (isDesktop) return 160;
    if (isTablet) return 150;
    return 140;
  }

  double get titleFontSize {
    if (isDesktop) return 38;
    if (isTablet) return 36;
    return 32;
  }

  double get subtitleFontSize {
    if (isDesktop) return 18;
    if (isTablet) return 17;
    return 16;
  }

  static final Map<String, Map<String, String>> _translations = {
    'EN': {
      'tagline': 'Your Path to Job-Ready Confidence',
      'welcome_back': 'Welcome Back',
      'login_subtitle': 'Sign in to continue your journey',
      'email_label': 'Email',
      'email_hint': 'Enter email',
      'password_label': 'Password',
      'password_hint': 'Enter password',
      'remember_me': 'Remember Me',
      'forgot_password': 'Forgot Password?',
      'login_button': 'Sign In',
      'or_divider': 'Or',
      'google_button': 'Continue with Google',
      'no_account': "Don't have an account? ",
      'signup': 'Sign Up',
      'validation_email': 'Please enter your email',
      'validation_password': 'Please enter your password',
      'login_failed_title': 'Login Failed',
      'ok_button': 'OK',
      'demo_title': 'Demo Credentials (Tap to fill)',
      'demo_admin': 'Admin: admin@tega.com / admin123',
      'demo_principal': 'Principal: college@tega.com / college123',
      'demo_student': 'Student: user@tega.com / user123',
      'logging_in': 'Signing in...',
      'invalid_email': 'Please enter a valid email address',
    },
    'TE': {
      'tagline': 'ఉద్యోగానికి సిద్ధమవ్వడానికి మీ మార్గం',
      'welcome_back': 'తిరిగి స్వాగతం',
      'login_subtitle': 'మీ ప్రయాణాన్ని కొనసాగించడానికి సైన్ ఇన్ చేయండి',
      'email_label': 'ఇమెయిల్',
      'email_hint': 'ఇమెయిల్ నమోదు చేయండి',
      'password_label': 'పాస్‌వర్డ్',
      'password_hint': 'పాస్‌వర్డ్ నమోదు చేయండి',
      'remember_me': 'నన్ను గుర్తుంచుకో',
      'forgot_password': 'పాస్‌వర్డ్ మర్చిపోయారా?',
      'login_button': 'సైన్ ఇన్',
      'or_divider': 'లేదా',
      'google_button': 'Google తో కొనసాగించండి',
      'no_account': 'ఖాతా లేదా? ',
      'signup': 'సైన్ అప్',
      'validation_email': 'దయచేసి మీ ఇమెయిల్ నమోదు చేయండి',
      'validation_password': 'దయచేసి మీ పాస్‌వర్డ్‌ను నమోదు చేయండి',
      'login_failed_title': 'లాగిన్ విఫలమైంది',
      'ok_button': 'సరే',
      'demo_title': 'డెమో ఆధారాలు (నింపడానికి నొక్కండి)',
      'demo_admin': 'అడ్మిన్: admin@tega.com / admin123',
      'demo_principal': 'ప్రిన్సిపాల్: college@tega.com / college123',
      'demo_student': 'విద్యార్థి: user@tega.com / user123',
      'logging_in': 'సైన్ ఇన్ అవుతోంది...',
      'invalid_email':
          'దయచేసి చెల్లుబాటు అయ్యే ఇమెయిల్ చిరునామాను నమోదు చేయండి',
    },
  };

  String _tr(String key) {
    return _translations[_selectedLanguage]![key] ?? key;
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    // Load saved credentials if "Remember Me" was checked
    _loadSavedCredentials();
  }

  /// Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('remembered_email');
      final savedPassword = prefs.getString('remembered_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && savedEmail != null && savedPassword != null) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
        debugPrint('✅ Loaded saved credentials for: $savedEmail');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading saved credentials: $e');
    }
  }

  /// Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
        await prefs.setString('remembered_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
        debugPrint('💾 Saved credentials for: ${_emailController.text.trim()}');
      } else {
        await _clearSavedCredentials();
      }
    } catch (e) {
      debugPrint('⚠️ Error saving credentials: $e');
    }
  }

  /// Clear saved credentials from SharedPreferences
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('remember_me', false);
      debugPrint('🗑️ Cleared saved credentials');
    } catch (e) {
      debugPrint('⚠️ Error clearing credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Helper function to parse and fill demo credentials
  void _fillDemoCredentials(String credentialLine) {
    try {
      // Example: "Admin: admin@tega.com / admin123"
      final parts = credentialLine.split(' / ');
      if (parts.length != 2) return;

      final password = parts.last.trim();
      final emailPart = parts.first.split(': ');
      if (emailPart.length != 2) return;

      final email = emailPart.last.trim();

      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
        // Uncheck remember me for demo credentials (security best practice)
        _rememberMe = false;
      });

      debugPrint("✅ Demo credentials filled: $email");
    } catch (e) {
      debugPrint("❌ Error parsing demo credentials: $e");
    }
  }

  /// Handle remember me checkbox toggle
  void _handleRememberMeToggle(bool? value) {
    setState(() {
      _rememberMe = value ?? false;
    });

    // If unchecked, clear saved credentials immediately
    if (!_rememberMe) {
      _clearSavedCredentials();
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Handle login with improved error handling
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('🔐 Attempting login for: $email');

      final result = await _authService.login(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        debugPrint('✅ Login successful, navigating based on role...');

        // Save credentials if "Remember Me" is checked
        await _saveCredentials();

        // Navigate based on user role
        if (_authService.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (_authService.isPrincipal) {
          await _navigateToCollegeDashboard();
        } else if (_authService.isStudent) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else {
          // Fallback for unknown roles
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage(title: 'TEGA')),
          );
        }
      } else {
        debugPrint('❌ Login failed: ${result['message']}');
        _showErrorDialog(
          result['message'] ?? 'Login failed. Please try again.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ Auth error: ${e.message}');
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      debugPrint('❌ Unexpected error during login: $e');
      if (mounted) {
        _showErrorDialog(
          'An unexpected error occurred. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToCollegeDashboard() async {
    try {
      final collegeService = CollegeService();
      final colleges = await collegeService.loadColleges();
      if (!mounted) return;
      if (colleges.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        _showErrorDialog(
          'No colleges available. Please contact administrator.',
        );
      }
    } catch (e) {
      _showErrorDialog('Error loading college data: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _tr('login_failed_title'),
          style: const TextStyle(
            color: Color(0xFFE74C3C),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF2C3E50)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_tr('ok_button')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9C88FF), // Light Purple
              Color(0xFF8B7BFF), // Medium Light Purple
              Color(0xFF7A6BFF), // Medium Purple
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 20 : 40,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    child: isDesktop
                        ? _buildDesktopLayout()
                        : _buildMobileLayout(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile & Tablet Layout (Vertical)
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: isMobile ? 20 : 40),
        _buildLogoSection(),
        SizedBox(height: isMobile ? 30 : 40),
        _buildTitle(),
        SizedBox(height: isMobile ? 30 : 40),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxFormWidth),
          child: Form(key: _formKey, child: _buildLoginFormCard()),
        ),
        SizedBox(height: isMobile ? 20 : 24),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxFormWidth),
          child: _buildDemoCredentials(),
        ),
        SizedBox(height: isMobile ? 20 : 24),
        _buildSignupLink(),
        const SizedBox(height: 20),
        _buildLanguageSelector(),
        const SizedBox(height: 20),
      ],
    );
  }

  // Desktop Layout (Horizontal with split screen)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 40),
              _buildTitle(),
              const SizedBox(height: 40),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildDemoCredentials(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        // Right side - Form
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(key: _formKey, child: _buildLoginFormCard()),
              ),
              const SizedBox(height: 32),
              _buildSignupLink(),
              const SizedBox(height: 20),
              _buildLanguageSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF9F5)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(width: 3, color: Colors.white.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.flutter_dash,
                    size: logoSize * 0.4,
                    color: const Color(0xFF9C88FF),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF5E6)],
          ).createShader(bounds),
          child: Text(
            _tr('tagline'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              shadows: const [
                Shadow(
                  color: Color(0x40000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _tr('welcome_back'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: const [
              Shadow(
                color: Color(0x40000000),
                offset: Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          _tr('login_subtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                color: Color(0x30000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Container(
          width: isMobile ? 60 : 80,
          height: isMobile ? 4 : 5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700), // Yellow
                Color(0xFF27AE60), // Green
              ],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormCard() {
    final cardPadding = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final borderRadius = isMobile ? 20.0 : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFF9C88FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormLabel(_tr('email_label')),
          SizedBox(height: isMobile ? 8 : 10),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF2C3E50),
            ),
            decoration: _inputDecoration(
              _tr('email_hint'),
              Icons.email_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _tr('validation_email');
              }
              if (!_isValidEmail(value.trim())) {
                return _tr('invalid_email');
              }
              return null;
            },
          ),
          SizedBox(height: isMobile ? 20 : 24),
          _buildFormLabel(_tr('password_label')),
          SizedBox(height: isMobile ? 8 : 10),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF2C3E50),
            ),
            decoration: _inputDecoration(
              _tr('password_hint'),
              Icons.lock_rounded,
              isPassword: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _tr('validation_password');
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildRememberMeAndForgotPassword(),
          SizedBox(height: isMobile ? 24 : 32),
          _buildLoginButton(),
          SizedBox(height: isMobile ? 20 : 24),
          _buildDivider(),
          SizedBox(height: isMobile ? 20 : 24),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C3E50),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _handleRememberMeToggle(!_rememberMe),
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: _handleRememberMeToggle,
                  activeColor: const Color(0xFF27AE60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tr('remember_me'),
                style: const TextStyle(
                  color: Color(0xFF5D6D7E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ForgetPasswordPage())),
          child: Text(
            _tr('forgot_password'),
            style: const TextStyle(
              color: Color(0xFF9C88FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final buttonHeight = isMobile ? 50.0 : 56.0;
    final buttonFontSize = isMobile ? 16.0 : 17.0;

    return Container(
      width: double.infinity,
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9C88FF), // Light Purple
            Color(0xFF8B7BFF), // Medium Light Purple
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C88FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: isMobile ? 22 : 24,
                    height: isMobile ? 22 : 24,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tr('login_button'),
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: isMobile ? 18 : 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFE8E8E8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Text(
              _tr('or_divider'),
              style: const TextStyle(
                color: Color(0xFF5D6D7E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFE8E8E8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    final buttonHeight = isMobile ? 50.0 : 56.0;
    final iconSize = isMobile ? 22.0 : 24.0;
    final fontSize = isMobile ? 15.0 : 16.0;

    return Container(
      width: double.infinity,
      height: buttonHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle Google sign in
          },
          borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.asset(
                  'assets/google_logo.png',
                  width: iconSize,
                  height: iconSize,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.g_mobiledata,
                    size: iconSize,
                    color: const Color(0xFF4285F4),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Text(
                _tr('google_button'),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C3E50),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredentials() {
    final cardPadding = isMobile ? 14.0 : 16.0;
    final borderRadius = isMobile ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3498DB).withOpacity(0.1),
            const Color(0xFF2980B9).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFF3498DB).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 5 : 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: isMobile ? 14 : 16,
                  color: const Color(0xFF3498DB),
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Flexible(
                child: Text(
                  _tr('demo_title'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                    color: const Color(0xFF3498DB),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          // Admin credentials
          GestureDetector(
            onTap: () => _fillDemoCredentials(_tr('demo_admin')),
            child: _buildDemoCredentialItem(
              _tr('demo_admin'),
              Icons.admin_panel_settings_rounded,
              const Color(0xFFE74C3C),
            ),
          ),
          SizedBox(height: isMobile ? 5 : 6),
          // Principal credentials
          GestureDetector(
            onTap: () => _fillDemoCredentials(_tr('demo_principal')),
            child: _buildDemoCredentialItem(
              _tr('demo_principal'),
              Icons.school_rounded,
              const Color(0xFF9C88FF),
            ),
          ),
          SizedBox(height: isMobile ? 5 : 6),
          // Student credentials
          GestureDetector(
            onTap: () => _fillDemoCredentials(_tr('demo_student')),
            child: _buildDemoCredentialItem(
              _tr('demo_student'),
              Icons.person_rounded,
              const Color(0xFF3498DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCredentialItem(String text, IconData icon, Color color) {
    final itemPadding = isMobile ? 8.0 : 10.0;
    final iconSize = isMobile ? 14.0 : 16.0;
    final fontSize = isMobile ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: itemPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 5 : 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
          SizedBox(width: isMobile ? 8 : 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Icon(
            Icons.touch_app_rounded,
            size: isMobile ? 12 : 14,
            color: color.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _tr('no_account'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              _tr('signup'),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF9C88FF).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language_rounded,
            size: 18,
            color: Color(0xFF5D6D7E),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF5D6D7E),
            ),
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              DropdownMenuItem(value: 'EN', child: Text('English')),
              DropdownMenuItem(value: 'TE', child: Text('తెలుగు')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLanguage = value);
              }
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, color: const Color(0xFF9C88FF), size: 22),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF9C88FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
    );
  }
}
