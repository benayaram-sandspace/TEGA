import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/forgot_password_page.dart';
import 'package:tega/features/1_authentication/presentation/screens/signup_page.dart';
import 'package:tega/features/2_shared_ui/presentation/screens/home_page.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_screen.dart';
import 'package:tega/features/5_student_dashboard/presentation/1_home/student_home_page.dart';
import 'package:tega/core/services/simple_google_credential_manager.dart';
import 'package:tega/core/widgets/google_credential_picker_field.dart';
import 'package:tega/core/widgets/fingerprint_login_button.dart';
import 'package:tega/core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

  // Static reference to clear fields on logout
  static _LoginPageState? _currentInstance;

  /// Clear login fields when logging out
  static void clearFieldsOnLogout() {
    _currentInstance?.clearLoginFields();
  }
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _credentialManager = SimpleGoogleCredentialManager();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String _selectedLanguage = 'EN';
  String? _currentSelectedEmail; // Track currently selected account email

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
      'no_account': "Don't have an account? ",
      'signup': 'Sign Up',
      'validation_email': 'Please enter your email',
      'validation_password': 'Please enter your password',
      'login_failed_title': 'Login Failed',
      'ok_button': 'OK',
      'logging_in': 'Signing in...',
      'invalid_email': 'Please enter a valid email address',
      'remember_me_title': 'Save Credentials',
      'remember_me_message':
          'Do you want to save your login credentials to this device?',
      'save_credentials': 'Save to Device',
      'dont_save': 'Don\'t Save',
      'credentials_saved': 'Credentials saved successfully!',
      'credentials_cleared': 'Saved credentials cleared.',
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
      'no_account': 'ఖాతా లేదా? ',
      'signup': 'సైన్ అప్',
      'validation_email': 'దయచేసి మీ ఇమెయిల్ నమోదు చేయండి',
      'validation_password': 'దయచేసి మీ పాస్‌వర్డ్‌ను నమోదు చేయండి',
      'login_failed_title': 'లాగిన్ విఫలమైంది',
      'ok_button': 'సరే',
      'logging_in': 'సైన్ ఇన్ అవుతోంది...',
      'invalid_email':
          'దయచేసి చెల్లుబాటు అయ్యే ఇమెయిల్ చిరునామాను నమోదు చేయండి',
      'remember_me_title': 'ఆధారాలను సేవ్ చేయండి',
      'remember_me_message':
          'మీ లాగిన్ ఆధారాలను ఈ పరికరంలో సేవ్ చేయాలనుకుంటున్నారా?',
      'save_credentials': 'పరికరంలో సేవ్ చేయండి',
      'dont_save': 'సేవ్ చేయవద్దు',
      'credentials_saved': 'ఆధారాలు విజయవంతంగా సేవ్ చేయబడ్డాయి!',
      'credentials_cleared': 'సేవ్ చేయబడిన ఆధారాలు క్లియర్ చేయబడ్డాయి.',
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

    // Initialize credential manager and load saved credentials
    _initializeCredentialManager();

    // Set static reference for logout clearing
    LoginPage._currentInstance = this;
  }

  /// Initialize credential manager
  Future<void> _initializeCredentialManager() async {
    try {
      await _credentialManager.initialize();

      // Update state to refresh UI
      setState(() {});
    } catch (e) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    // Clear static reference
    LoginPage._currentInstance = null;
    super.dispose();
  }

  /// Handle remember me checkbox toggle
  void _handleRememberMeToggle(bool? value) async {
    if (value == true) {
      // Save credentials using Google Credential Manager
      final success = await _credentialManager.saveCredentials(
        domain: 'tega.app', // Your app domain
        username: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _emailController.text.split('@')[0],
      );

      if (success) {
        setState(() {
          _rememberMe = true;
        });
        _showSnackBar(_tr('credentials_saved'));
      } else {
        _showSnackBar('Failed to save credentials. Please try again.');
      }
    } else {
      setState(() {
        _rememberMe = false;
      });
    }
  }

  /// Show snackbar with message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Clear login form fields
  void clearLoginFields() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _rememberMe = false;
    });
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

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Check if this is a new account (not saved) and Remember Me is checked
    final isNewAccount = !(await _credentialManager.hasCredentials(email));

    if (isNewAccount && _rememberMe) {
      // Show save account dialog first
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              _tr('remember_me_title'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            content: Text(_tr('remember_me_message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_tr('dont_save')),
              ),
              TextButton(
                onPressed: () async {
                  final saved = await _credentialManager.saveCredentials(
                    domain: 'tega.app',
                    username: email,
                    password: password,
                    displayName: email.split('@').first,
                  );
                  Navigator.of(context).pop(saved);
                },
                child: Text(_tr('save_credentials')),
              ),
            ],
          );
        },
      );

      if (shouldSave == null || shouldSave == false) {
        // User cancelled saving, don't proceed with login
        return;
      }
    }

    // Proceed with actual login
    await _performLogin(email, password);
  }

  /// Perform the actual login
  Future<void> _performLogin(String email, String password) async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await _authService.login(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        // Update last used timestamp for saved account
        await _credentialManager.updateLastUsed(email);

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
        _showErrorDialog(
          result['message'] ?? 'Login failed. Please try again.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
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
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pureWhite,
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          decoration: const BoxDecoration(color: AppColors.background),
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
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: _buildLoginFormCard(),
          ),
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: _buildLoginFormCard(),
                ),
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
            color: AppColors.pureWhite,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(width: 2, color: AppColors.borderLight),
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
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          _tr('tagline'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
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
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          _tr('login_subtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Container(
          width: isMobile ? 60 : 80,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormCard() {
    final cardPadding = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final borderRadius = isMobile ? 20.0 : 24.0;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and remove focus when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormLabel(_tr('email_label')),
            SizedBox(height: isMobile ? 8 : 10),
            GoogleCredentialPickerField(
              controller: _emailController,
              hintText: _tr('email_hint'),
              isMobile: isMobile,
              decoration: _inputDecoration(
                _tr('email_hint'),
                Icons.email_rounded,
              ),
              validator: (value) {
                final trimmedValue = value?.trim() ?? '';
                if (trimmedValue.isEmpty) {
                  return _tr('validation_email');
                }
                if (!_isValidEmail(trimmedValue)) {
                  return _tr('invalid_email');
                }
                return null;
              },
              onCredentialSelected: (email, password) {
                // Auto-fill password when credential is selected
                _passwordController.text = password;
                // Trigger form validation after auto-fill
                _formKey.currentState?.validate();
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
                color: AppColors.textPrimary,
              ),
              decoration: _inputDecoration(
                _tr('password_hint'),
                Icons.lock_rounded,
                isPassword: true,
              ),
              validator: (value) {
                final trimmedValue = value?.trim() ?? '';
                if (trimmedValue.isEmpty) {
                  return _tr('validation_password');
                }
                if (trimmedValue.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),
            _buildRememberMeAndForgotPassword(),
            SizedBox(height: isMobile ? 24 : 32),
            _buildLoginButton(),
            SizedBox(height: isMobile ? 16 : 20),
            _buildFingerprintLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                // Only allow toggle if it's not a saved account
                if (_currentSelectedEmail == null) {
                  _handleRememberMeToggle(!_rememberMe);
                }
              },
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: _currentSelectedEmail == null
                          ? _handleRememberMeToggle
                          : null,
                      activeColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tr('remember_me'),
                    style: TextStyle(
                      color: _currentSelectedEmail == null
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgetPasswordPage()),
              ),
              child: Text(
                _tr('forgot_password'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        // Removed Manage Saved Accounts button as requested
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.pureWhite,
                      ),
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
                          color: AppColors.pureWhite,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.pureWhite,
                        size: isMobile ? 18 : 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintLoginButton() {
    return FingerprintLoginButton(
      isMobile: isMobile,
      onLoginSuccess: (email, password) {
        _emailController.text = email;
        _passwordController.text = password;
        _handleLogin();
      },
    );
  }

  Widget _buildSignupLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _tr('no_account'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
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
      hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textDisabled,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
    );
  }
}
