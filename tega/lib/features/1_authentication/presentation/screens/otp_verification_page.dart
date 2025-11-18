import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/login_page.dart';
import 'package:tega/features/1_authentication/presentation/screens/reset_password_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? password;
  final String? college;
  final bool isRegistration; // true for registration, false for password reset

  const OTPVerificationPage({
    super.key,
    required this.email,
    this.firstName,
    this.lastName,
    this.password,
    this.college,
    this.isRegistration = false,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final AuthService _authService = AuthService();

  int _resendCountdown = 30;
  bool _canResend = false;
  Timer? _timer;
  String _selectedLanguage = 'EN';
  bool _isVerifying = false;

  // ✨ --- Language Translations --- ✨
  static final Map<String, Map<String, String>> _translations = {
    'EN': {
      'title': 'Verify Your OTP',
      'subtitle': "We've sent a 6-digit verification code to the email address",
      'resend_in': 'Resend in',
      'resend_now': "Didn't receive the code? Resend OTP",
      'verify_button': 'Verify & Continue',
      'back_to_login': 'Back to Login',
    },
    'TE': {
      'title': 'మీ OTPని ధృవీకరించండి',
      'subtitle': 'మేము 6-అంకెల ధృవీకరణ కోడ్‌ను ఇమెయిల్ చిరునామాకు పంపాము',
      'resend_in': 'లో మళ్ళీ పంపు',
      'resend_now': 'కోడ్ అందలేదా? OTPని మళ్లీ పంపండి',
      'verify_button': 'ధృవీకరించి కొనసాగించండి',
      'back_to_login': 'లాగిన్‌కు తిరిగి వెళ్ళు',
    },
  };

  String _tr(String key) {
    return _translations[_selectedLanguage]![key] ?? key;
  }
  // ✨ --- End of Translations --- ✨

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) {
          setState(() => _resendCountdown--);
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _canResend = true);
        }
      }
    });
  }

  void _onOTPChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  /// Verify OTP and complete registration/password reset
  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showErrorMessage('Please enter complete 6-digit code');
      return;
    }

    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      if (widget.isRegistration) {
        // Registration flow: Verify OTP then complete signup
        await _handleRegistrationVerification(otp);
      } else {
        // Password reset flow: Just verify OTP
        await _handlePasswordResetVerification(otp);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Handle registration OTP verification and account creation
  Future<void> _handleRegistrationVerification(String otp) async {
    // Verify OTP and create account in one step
    final verifyResult = await _authService.verifyRegistrationOTP(
      widget.email,
      otp,
    );

    if (!mounted) return;

    if (verifyResult['success'] == true && verifyResult['verified'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Account created successfully! Please login to continue 🎉',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to login page instead of dashboard
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      _showErrorMessage(
        verifyResult['message'] ??
            'Invalid verification code. Please try again.',
      );
      _clearOTPFields();
    }
  }

  /// Handle password reset OTP verification
  Future<void> _handlePasswordResetVerification(String otp) async {
    final result = await _authService.verifyOTP(widget.email, otp);

    if (!mounted) return;

    if (result['success'] == true && result['verified'] == true) {
      // Navigate to reset password page
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(email: widget.email, otp: otp),
        ),
      );
    } else {
      _showErrorMessage(
        result['message'] ?? 'Invalid verification code. Please try again.',
      );
      _clearOTPFields();
    }
  }

  /// Resend OTP
  Future<void> _resendOTP() async {
    if (!_canResend) return;

    try {
      final result = widget.isRegistration
          ? await _authService.sendRegistrationOTP(widget.email)
          : await _authService.forgotPassword(widget.email);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _resendCountdown = 30;
        });
        _startCountdown();

        _clearOTPFields();
        _focusNodes[0].requestFocus();

        _showSuccessMessage('Verification code sent to your email!');
      } else {
        _showErrorMessage(
          result['message'] ?? 'Failed to resend code. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(
          'Failed to resend code. Please check your connection.',
        );
      }
    }
  }

  /// Clear all OTP input fields
  void _clearOTPFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final atIndex = email.indexOf('@');
    if (atIndex < 3) return email;
    return '${email.substring(0, 3)}***${email.substring(atIndex)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoSection(),
                  const SizedBox(height: 40),
                  _buildTitle(),
                  const SizedBox(height: 30),
                  _buildSubtitle(),
                  const SizedBox(height: 40),
                  _buildOtpFields(),
                  const SizedBox(height: 30),
                  _buildResendTimer(),
                  const SizedBox(height: 40),
                  _buildVerifyButton(),
                  const SizedBox(height: 40),
                  _buildBackToLoginButton(),
                  const SizedBox(height: 20),
                  _buildLanguageSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 140,
      height: 140,
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
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.flutter_dash,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _tr('title'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        Text(
          _tr('subtitle'),
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            _maskEmail(widget.email),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.pureWhite,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _onOTPChanged(index, value),
          ),
        );
      }),
    );
  }

  Widget _buildResendTimer() {
    return GestureDetector(
      onTap: _resendOTP,
      child: _canResend
          ? Text(
              _tr('resend_now'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_tr('resend_in')} ${_resendCountdown.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: _isVerifying
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
                _tr('verify_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
      label: Text(
        _tr('back_to_login'),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        child: DropdownButton<String>(
          value: _selectedLanguage,
          underline: const SizedBox(),
          icon: const Icon(
            Icons.language_rounded,
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
      ),
    );
  }
}
