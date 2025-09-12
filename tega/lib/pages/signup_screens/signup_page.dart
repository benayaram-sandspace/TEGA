import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tega/constants/app_colors.dart';
import 'package:tega/pages/student_screens/student_onboarding_screens/on_boarding_page_1.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String _selectedLanguage = 'EN';

  // ✨ --- Language Translations --- ✨
  static final Map<String, Map<String, String>> _translations = {
    'EN': {
      'tagline': 'Your Path to Job-Ready Confidence',
      'create_account_title': 'Create Account',
      'full_name_label': 'Full Name',
      'full_name_hint': 'Enter your full name',
      'email_label': 'Email',
      'email_hint': 'Enter your email',
      'phone_label': 'Phone Number',
      'phone_hint': 'Enter your phone number',
      'password_label': 'Password',
      'password_hint': 'Enter password',
      'confirm_password_label': 'Confirm Password',
      'confirm_password_hint': 'Confirm password',
      'terms_agree': 'I agree to the ',
      'terms_and_conditions': 'Terms and Conditions',
      'terms_and': ' and ',
      'privacy_policy': 'Privacy Policy',
      'signup_button': 'Sign Up',
      'already_account': 'Already have an account? ',
      'login_link': 'Login',
      'validation_name': 'Please enter your full name',
      'validation_email_empty': 'Please enter your email',
      'validation_email_invalid': 'Please enter a valid email',
      'validation_phone': 'Please enter your phone number',
      'validation_password_empty': 'Please enter your password',
      'validation_password_length': 'Password must be at least 6 characters',
      'validation_confirm_password_empty': 'Please confirm your password',
      'validation_passwords_mismatch': 'Passwords do not match',
      'signup_success_message': 'Account created successfully! Please login.',
    },
    'TE': {
      'tagline': 'ఉద్యోగానికి సిద్ధమవ్వడానికి మీ మార్గం',
      'create_account_title': 'ఖాతాను సృష్టించండి',
      'full_name_label': 'పూర్తి పేరు',
      'full_name_hint': 'మీ పూర్తి పేరును నమోదు చేయండి',
      'email_label': 'ఇమెయిల్',
      'email_hint': 'మీ ఇమెయిల్‌ను నమోదు చేయండి',
      'phone_label': 'ఫోన్ నంబర్',
      'phone_hint': 'మీ ఫోన్ నంబర్‌ను నమోదు చేయండి',
      'password_label': 'పాస్‌వర్డ్',
      'password_hint': 'పాస్‌వర్డ్ నమోదు చేయండి',
      'confirm_password_label': 'పాస్‌వర్డ్‌ను నిర్ధారించండి',
      'confirm_password_hint': 'పాస్‌వర్డ్‌ను నిర్ధారించండి',
      'terms_agree': 'నేను అంగీకరిస్తున్నాను ',
      'terms_and_conditions': 'నిబంధనలు మరియు షరతులు',
      'terms_and': ' మరియు ',
      'privacy_policy': 'గోప్యతా విధానం',
      'signup_button': 'సైన్ అప్',
      'already_account': 'ఇప్పటికే ఖాతా ఉందా? ',
      'login_link': 'లాగిన్',
      'validation_name': 'దయచేసి మీ పూర్తి పేరును నమోదు చేయండి',
      'validation_email_empty': 'దయచేసి మీ ఇమెయిల్‌ను నమోదు చేయండి',
      'validation_email_invalid': 'దయచేసి సరైన ఇమెయిల్‌ను నమోదు చేయండి',
      'validation_phone': 'దయచేసి మీ ఫోన్ నంబర్‌ను నమోదు చేయండి',
      'validation_password_empty': 'దయచేసి మీ పాస్‌వర్డ్‌ను నమోదు చేయండి',
      'validation_password_length': 'పాస్‌వర్డ్ కనీసం 6 అక్షరాలు ఉండాలి',
      'validation_confirm_password_empty':
          'దయచేసి మీ పాస్‌వర్డ్‌ను నిర్ధారించండి',
      'validation_passwords_mismatch': 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు',
      'signup_success_message':
          'ఖాతా విజయవంతంగా సృష్టించబడింది! దయచేసి లాగిన్ చేయండి.',
    },
  };

  String _tr(String key) {
    return _translations[_selectedLanguage]![key] ?? key;
  }
  // ✨ --- End of Translations --- ✨

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    // Basic frontend validation for now
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() => _isLoading = true);

      // Simulate a network call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const CareerDiscoveryWelcome(),
          ),
          (Route<dynamic> route) => false,
        );
      });
    }
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
                const SizedBox(height: 20),
                _buildLogoSection(),
                const SizedBox(height: 30),
                _buildTitle(),
                const SizedBox(height: 30),
                _buildSignUpFormCard(),
                const SizedBox(height: 24),
                _buildLoginLink(),
                const SizedBox(height: 20),
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
          width: 160,
          height: 160,
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
                  size: 50,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _tr('tagline'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
          _tr('create_account_title'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpFormCard() {
    return Container(
      width: double.infinity,
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
            // Full Name
            _buildFormLabel(_tr('full_name_label')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                _tr('full_name_hint'),
                Icons.person_outline,
              ),
              validator: (v) => v!.isEmpty ? _tr('validation_name') : null,
            ),
            const SizedBox(height: 20),

            // Email
            _buildFormLabel(_tr('email_label')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                _tr('email_hint'),
                Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return _tr('validation_email_empty');
                if (!v.contains('@')) return _tr('validation_email_invalid');
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Phone
            _buildFormLabel(_tr('phone_label')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                _tr('phone_hint'),
                Icons.phone_outlined,
              ),
              validator: (v) => v!.isEmpty ? _tr('validation_phone') : null,
            ),
            const SizedBox(height: 20),

            // Password
            _buildFormLabel(_tr('password_label')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _inputDecoration(
                _tr('password_hint'),
                Icons.lock_outline,
                isPassword: true,
                isConfirm: false,
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return _tr('validation_password_empty');
                if (v.length < 6) return _tr('validation_password_length');
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirm Password
            _buildFormLabel(_tr('confirm_password_label')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: _inputDecoration(
                _tr('confirm_password_hint'),
                Icons.lock_outline,
                isPassword: true,
                isConfirm: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return _tr('validation_confirm_password_empty');
                if (v != _passwordController.text)
                  return _tr('validation_passwords_mismatch');
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildTermsAndConditions(),
            const SizedBox(height: 30),

            _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) =>
                setState(() => _agreeToTerms = value ?? false),
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              children: [
                TextSpan(text: _tr('terms_agree')),
                TextSpan(
                  text: _tr('terms_and_conditions'),
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Navigate to Terms and Conditions page
                    },
                ),
                TextSpan(text: _tr('terms_and')),
                TextSpan(
                  text: _tr('privacy_policy'),
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Navigate to Privacy Policy page
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _agreeToTerms && !_isLoading ? _handleSignUp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.pureWhite,
          disabledBackgroundColor: Colors.grey,
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
                _tr('signup_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _tr('already_account'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            _tr('login_link'),
            style: const TextStyle(
              color: AppColors.info,
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
    bool isConfirm = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isConfirm
                    ? (_isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off)
                    : (_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  if (isConfirm) {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  } else {
                    _isPasswordVisible = !_isPasswordVisible;
                  }
                });
              },
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
