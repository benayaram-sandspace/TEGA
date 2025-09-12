import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/pages/college_screens/college_dashboard_page.dart';
import 'package:tega/pages/home_screens/home_page.dart';
import 'package:tega/pages/admin_screens/admin_related_pages/admin_dashboard.dart';

import 'package:tega/pages/signup_screens/signup_page.dart';
import 'package:tega/pages/student_screens/student_home_page.dart';
import 'package:tega/services/auth_service.dart';
import 'package:tega/services/college_service.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String _selectedLanguage = 'EN'; // Default language

  // ✨ --- Language Translations --- ✨
  static final Map<String, Map<String, String>> _translations = {
    'EN': {
      'tagline': 'Your Path to Job-Ready Confidence',
      'email_label': 'Email or Phone',
      'email_hint': 'Enter email or phone number',
      'password_label': 'Password',
      'password_hint': 'Enter password',
      'remember_me': 'Remember Me',
      'forgot_password': 'Forget Password?',
      'login_button': 'Login',
      'or_divider': 'Or',
      'google_button': 'Continue with Google',
      'no_account': "Don't have an account? ",
      'signup': 'Sign Up',
      'validation_email': 'Please enter your email or phone',
      'validation_password': 'Please enter your password',
      'login_failed_title': 'Login Failed',
      'ok_button': 'OK',
      'demo_title': 'Demo Credentials:',
      'demo_admin': 'Admin: admin@tega.com / admin123',
      // ✨ --- UPDATED --- ✨
      'demo_moderator': 'Moderator: principal@tega.com / principal123',
      'demo_user': 'User: user@tega.com / user123',
    },
    'TE': {
      'tagline': 'ఉద్యోగానికి సిద్ధమవ్వడానికి మీ మార్గం',
      'email_label': 'ఇమెయిల్ లేదా ఫోన్',
      'email_hint': 'ఇమెయిల్ లేదా ఫోన్ నంబర్ నమోదు చేయండి',
      'password_label': 'పాస్‌వర్డ్',
      'password_hint': 'పాస్‌వర్డ్ నమోదు చేయండి',
      'remember_me': 'నన్ను గుర్తుంచుకో',
      'forgot_password': 'పాస్‌వర్డ్ మర్చిపోయారా?',
      'login_button': 'లాగిన్',
      'or_divider': 'లేదా',
      'google_button': 'Google తో కొనసాగించండి',
      'no_account': 'ఖాతా లేదా? ',
      'signup': 'సైన్ అప్',
      'validation_email': 'దయచేసి మీ ఇమెయిల్ లేదా ఫోన్‌ను నమోదు చేయండి',
      'validation_password': 'దయచేసి మీ పాస్‌వర్డ్‌ను నమోదు చేయండి',
      'login_failed_title': 'లాగిన్ విఫలమైంది',
      'ok_button': 'సరే',
      'demo_title': 'డెమో ఆధారాలు:',
      'demo_admin': 'అడ్మిన్: admin@tega.com / admin123',
      // ✨ --- UPDATED --- ✨
      'demo_moderator': 'మోడరేటర్: principal@tega.com / principal123',
      'demo_user': 'వినియోగదారు: user@tega.com / user123',
    },
  };

  String _tr(String key) {
    return _translations[_selectedLanguage]![key] ?? key;
  }
  // ✨ --- End of Translations --- ✨

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (result['success']) {
        if (_authService.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (_authService.hasRole(UserRole.moderator)) {
          _navigateToCollegeDashboard();
        } else if (_authService.hasRole(UserRole.user)) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage(title: 'TEGA')),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
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
      if (colleges.isNotEmpty) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => DashboardScreen()));
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
        title: Text(_tr('login_failed_title')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.primary.withOpacity(0.05)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // TEGA Logo and Tagline
                _buildLogoSection(),
                const SizedBox(height: 40),
                // Login Form Card
                _buildLoginFormCard(),
                const SizedBox(height: 24),
                // Demo Credentials
                _buildDemoCredentials(),
                const SizedBox(height: 24),
                // Sign Up Link
                _buildSignupLink(),
                const SizedBox(height: 20),
                // Language Selector
                _buildLanguageSelector(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight.withOpacity(0.7),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.flutter_dash,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _tr('tagline'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('email_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                _tr('email_hint'),
                Icons.email_outlined,
              ),
              validator: (v) => v!.isEmpty ? _tr('validation_email') : null,
            ),
            const SizedBox(height: 20),
            Text(
              _tr('password_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _inputDecoration(
                _tr('password_hint'),
                Icons.lock_outline,
                isPassword: true,
              ),
              validator: (v) => v!.isEmpty ? _tr('validation_password') : null,
            ),
            const SizedBox(height: 16),
            _buildRememberMeAndForgotPassword(),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCredentials() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('demo_creds'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _tr('admin :- admin@tega/com / admin123'),
              style: const TextStyle(fontSize: 11, color: AppColors.info),
            ),
            Text(
              _tr('mods :- principal@tega.com / principal123'),
              style: const TextStyle(fontSize: 11, color: AppColors.info),
            ),
            Text(
              _tr('users :- user@tega.com / user123'),
              style: const TextStyle(fontSize: 11, color: AppColors.info),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v!),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tr('remember_me'),
                style: const TextStyle(color: AppColors.textSecondary),
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
              color: AppColors.info,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                ),
              )
            : Text(
                _tr('login_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            _tr('or_divider'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderLight)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: Image.asset('assets/google_logo.png', height: 20, width: 20),
        label: Text(
          _tr('google_button'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        onPressed: () {
          // TODO: Implement Google Sign-In
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _tr('no_account'),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
          child: Text(
            _tr('signup'),
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButton<String>(
          value: _selectedLanguage,
          underline: const SizedBox(),
          icon: const Icon(Icons.language, size: 16, color: Colors.grey),
          items: const [
            DropdownMenuItem(value: 'EN', child: Text('  English')),
            DropdownMenuItem(value: 'TE', child: Text('  తెలుగు')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLanguage = value);
            }
          },
        ),
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
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
    );
  }
}
