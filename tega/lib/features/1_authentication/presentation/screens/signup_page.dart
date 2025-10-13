import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/1_authentication/presentation/screens/otp_verification_page.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _collegeSearchController = TextEditingController();

  final AuthService _authService = AuthService();
  final CollegeService _collegeService = CollegeService();

  List<CollegeInfo> _collegeList = [];
  List<CollegeInfo> _filteredCollegeList = [];
  CollegeInfo? _selectedCollege;
  bool _isCollegesLoading = true;
  String? _collegeError;
  bool _showCollegeDropdown = false;
  final _collegeFieldFocusNode = FocusNode();
  final _dropdownLayerLink = LayerLink();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _fetchColleges();

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

    _collegeSearchController.addListener(_filterColleges);
    _collegeFieldFocusNode.addListener(() {
      if (_collegeFieldFocusNode.hasFocus) {
        _showDropdown();
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          _hideDropdown();
        });
      }
    });
  }

  void _filterColleges() {
    final query = _collegeSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCollegeList = List.from(_collegeList);
      } else {
        _filteredCollegeList = _collegeList.where((college) {
          return college.name.toLowerCase().contains(query);
        }).toList();
      }
    });
    _updateOverlay();
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showCollegeDropdown = true;
    });
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showCollegeDropdown = false;
    });
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _dropdownLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isCollegesLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                      )
                    : _filteredCollegeList.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No colleges found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different search term',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredCollegeList.length,
                        separatorBuilder: (context, index) => Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final college = _filteredCollegeList[index];
                          final isSelected = _selectedCollege == college;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCollege = college;
                                _collegeSearchController.text = college.name;
                              });
                              _hideDropdown();
                              FocusScope.of(context).unfocus();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFF6B35).withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isSelected
                                            ? [
                                                const Color(0xFFFF6B35),
                                                const Color(0xFFFBB040),
                                              ]
                                            : [
                                                const Color(0xFFF5F5F5),
                                                const Color(0xFFEEEEEE),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        college.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFFFF6B35),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          college.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFFFF6B35)
                                                : const Color(0xFF2C3E50),
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (college.location != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              college.location!,
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF27AE60),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchColleges() async {
    try {
      final colleges = await _collegeService.fetchCollegeList();
      if (mounted) {
        setState(() {
          _collegeList = colleges;
          _filteredCollegeList = List.from(colleges);
          _isCollegesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _collegeError = e.toString();
          _isCollegesLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _collegeSearchController.dispose();
    _collegeFieldFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  /// Handle signup - Step 1: Send OTP to email
  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // No policies gating; proceed directly

    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    debugPrint('🔐 [SIGNUP] Starting registration process...');
    final email = _emailController.text.trim();
    debugPrint('📧 Sending OTP to: $email');

    try {
      // Step 1: Send OTP to email
      final result = await _authService.sendRegistrationOTP(
        email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        college: _selectedCollege?.name,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        debugPrint('✅ [SIGNUP] OTP sent successfully');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Verification code sent to your email!',
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to OTP verification page with user data
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                email: email,
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                password: _passwordController.text,
                college: _selectedCollege?.name,
                isRegistration: true,
              ),
            ),
          );
        }
      } else {
        debugPrint('❌ [SIGNUP] Failed to send OTP: ${result['message']}');
        _showErrorMessage(
          result['message'] ??
              'Failed to send verification code. Please try again.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ [SIGNUP] Auth error: ${e.message}');
      if (mounted) {
        _showErrorMessage(e.message);
      }
    } catch (e) {
      debugPrint('❌ [SIGNUP] Unexpected error: $e');
      if (mounted) {
        _showErrorMessage(
          'An unexpected error occurred. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show error message as snackbar
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
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
              Color(0xFFFF6B35), // Orange
              Color(0xFFF7931E), // Deep Orange
              Color(0xFFFBB040), // Yellow-Orange
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    _buildLogoSection(),
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 40),
                    Form(key: _formKey, child: _buildSignUpFormCard()),
                    const SizedBox(height: 30),
                    _buildLoginLink(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
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
          width: 140,
          height: 140,
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
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.flutter_dash,
                    size: 60,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF5E6)],
          ).createShader(bounds),
          child: const Text(
            'Your Path to Job-Ready Confidence',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              shadows: [
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
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Color(0x40000000),
                offset: Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: 5,
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

  Widget _buildSignUpFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('First Name'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _firstNameController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2C3E50),
                      ),
                      decoration: _inputDecoration(
                        'First name',
                        Icons.person_outline_rounded,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Last Name'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _lastNameController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2C3E50),
                      ),
                      decoration: _inputDecoration(
                        'Last name',
                        Icons.person_outline_rounded,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormLabel('College Name'),
          const SizedBox(height: 10),
          CompositedTransformTarget(
            link: _dropdownLayerLink,
            child: TextFormField(
              controller: _collegeSearchController,
              focusNode: _collegeFieldFocusNode,
              style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
              decoration: InputDecoration(
                hintText: _isCollegesLoading
                    ? 'Loading colleges...'
                    : 'Search and select your college',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.school_rounded,
                    color: _isCollegesLoading
                        ? Colors.grey.shade400
                        : const Color(0xFFFF6B35),
                    size: 22,
                  ),
                ),
                suffixIcon: _showCollegeDropdown
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_drop_up_rounded,
                          color: Color(0xFFFF6B35),
                          size: 28,
                        ),
                        onPressed: () {
                          _collegeFieldFocusNode.unfocus();
                        },
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: _isCollegesLoading
                              ? Colors.grey.shade400
                              : const Color(0xFFFF6B35),
                          size: 28,
                        ),
                        onPressed: _isCollegesLoading
                            ? null
                            : () {
                                _collegeFieldFocusNode.requestFocus();
                              },
                      ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFFFF6B35),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE74C3C),
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE74C3C),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                errorStyle: const TextStyle(fontSize: 12, height: 0.8),
              ),
              validator: (v) {
                if (_selectedCollege == null) {
                  return 'Please select your college';
                }
                return null;
              },
              enabled: !_isCollegesLoading,
            ),
          ),
          if (_collegeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _collegeError!,
                style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          _buildFormLabel('Email Address'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
            decoration: _inputDecoration(
              'example@gmail.com',
              Icons.email_rounded,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              final emailRegex = RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
              );
              if (!emailRegex.hasMatch(v)) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildFormLabel('Password'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
            decoration: _inputDecoration(
              'Enter strong password',
              Icons.lock_rounded,
              isPassword: true,
              isConfirm: false,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildFormLabel('Confirm Password'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
            decoration: _inputDecoration(
              'Re-enter password',
              Icons.lock_rounded,
              isPassword: true,
              isConfirm: true,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          const SizedBox(height: 12),
          _buildSignUpButton(),
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

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: !_isLoading
              ? const [
                  Color(0xFF27AE60), // Green
                  Color(0xFF2ECC71), // Light Green
                ]
              : const [Color(0xFFBDC3C7), Color(0xFF95A5A6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: !_isLoading
            ? [
                BoxShadow(
                  color: const Color(0xFF27AE60).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !_isLoading ? _handleSignUp : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
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
          const Text(
            "Already have an account?",
            style: TextStyle(
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
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
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

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isConfirm
                    ? (_isConfirmPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded)
                    : (_isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                color: Colors.grey.shade500,
                size: 20,
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
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
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

// Extension to add optional location property to CollegeInfo
extension on CollegeInfo {
  String? get location =>
      null; // Override this if CollegeInfo has location data
}
