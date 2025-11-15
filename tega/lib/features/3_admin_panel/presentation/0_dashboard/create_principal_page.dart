import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/data/colleges_data.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePrincipalPage extends StatefulWidget {
  final VoidCallback onPrincipalCreated;

  const CreatePrincipalPage({super.key, required this.onPrincipalCreated});

  @override
  State<CreatePrincipalPage> createState() => _CreatePrincipalPageState();
}

class _CreatePrincipalPageState extends State<CreatePrincipalPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  // Form controllers
  final _principalNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGender;
  String? _selectedUniversity;
  bool _isLoading = false;

  List<String> _universities = List.from(collegesData);
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    // Initialize cache service (for consistency with other pages)
    await _cacheService.initialize();
    
    // Try to load universities from cache if available
    final cachedUniversities = await _cacheService.getAvailableInstitutes();
    if (cachedUniversities != null && cachedUniversities.isNotEmpty) {
      setState(() {
        _universities = List.from(cachedUniversities);
      });
    } else {
      // Cache the static colleges data
      await _cacheService.setAvailableInstitutes(_universities);
    }
  }

  @override
  void dispose() {
    _principalNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createPrincipal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final principalData = {
        'principalName': _principalNameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'university': _universityController.text.trim(),
        'password': _passwordController.text,
        'gender': _selectedGender,
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.adminRegisterPrincipal),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(principalData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Principal created successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          widget.onPrincipalCreated();
          Navigator.of(context).pop();
        }
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(
          responseData['message'] ?? 'Failed to create principal',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside input fields
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.opaque,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Modern App Bar
                  _buildModernAppBar(isMobile, isTablet, isDesktop),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : isTablet ? 18 : 20,
                        0,
                        isMobile ? 16 : isTablet ? 18 : 20,
                        isMobile ? 16 : isTablet ? 18 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),

                          // Basic Information Section
                          _buildBasicInfoSection(isMobile, isTablet, isDesktop),
                          SizedBox(height: isMobile ? 20 : isTablet ? 22 : 24),

                          // University Information Section
                          _buildUniversitySection(isMobile, isTablet, isDesktop),
                          SizedBox(height: isMobile ? 20 : isTablet ? 22 : 24),

                          // Account Information Section
                          _buildAccountSection(isMobile, isTablet, isDesktop),
                          SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),

                          // Action Buttons
                          _buildActionButtons(isMobile, isTablet, isDesktop),
                          SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
                        ],
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

  Widget _buildModernAppBar(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : isTablet ? 18 : 20,
        isMobile ? 12 : isTablet ? 14 : 16,
        isMobile ? 16 : isTablet ? 18 : 20,
        isMobile ? 12 : isTablet ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AdminDashboardStyles.primary,
                size: isMobile ? 18 : isTablet ? 19 : 20,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : isTablet ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Principal',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : isTablet ? 19 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Add a new principal to the system',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminDashboardStyles.primary,
                  AdminDashboardStyles.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: isMobile ? 20 : isTablet ? 22 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isMobile, bool isTablet, bool isDesktop) {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.person_rounded,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      children: [
        isMobile
            ? Column(
                children: [
                  _buildModernTextField(
                    controller: _firstNameController,
                    labelText: 'First Name',
                    prefixIcon: Icons.person_outline,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                  _buildModernTextField(
                    controller: _lastNameController,
                    labelText: 'Last Name',
                    prefixIcon: Icons.person_outline,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      prefixIcon: Icons.person_outline,
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      prefixIcon: Icons.person_outline,
                      isMobile: isMobile,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
        _buildModernTextField(
          controller: _principalNameController,
          labelText: 'Principal Name (Full Name)',
          prefixIcon: Icons.badge_rounded,
          helperText: 'This will be the display name for the principal',
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter principal name';
            }
            return null;
          },
        ),
        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
        _buildModernDropdown(
          value: _selectedGender,
          labelText: 'Gender',
          prefixIcon: Icons.wc_rounded,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          items: _genders.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(
                gender,
                style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 16),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select gender';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUniversitySection(bool isMobile, bool isTablet, bool isDesktop) {
    return _buildSection(
      title: 'University Information',
      icon: Icons.school_rounded,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      children: [
        _buildModernDropdown(
          value: _selectedUniversity,
          labelText: 'University/College',
          prefixIcon: Icons.school_rounded,
          isExpanded: true,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          items: _universities.map((university) {
            return DropdownMenuItem(
              value: university,
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? 250 : isTablet ? 280 : 300),
                child: Text(
                  university,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 16),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUniversity = value;
              _universityController.text = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select university';
            }
            return null;
          },
        ),
        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
        _buildModernTextField(
          controller: _universityController,
          labelText: 'University Name (Custom)',
          prefixIcon: Icons.edit_rounded,
          helperText: 'Enter custom university name if not in the list',
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        ),
      ],
    );
  }

  Widget _buildAccountSection(bool isMobile, bool isTablet, bool isDesktop) {
    return _buildSection(
      title: 'Account Information',
      icon: Icons.lock_rounded,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      children: [
        _buildModernTextField(
          controller: _emailController,
          labelText: 'Email Address',
          prefixIcon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          helperText: 'This will be used for login',
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
        _buildModernTextField(
          controller: _passwordController,
          labelText: 'Password',
          prefixIcon: Icons.lock_rounded,
          obscureText: true,
          helperText: 'Minimum 6 characters',
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? helperText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onTapOutside: (event) {
          // Dismiss keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: isMobile ? 14 : isTablet ? 15 : 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          helperText: helperText,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
          ),
          helperStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 11 : isTablet ? 11.5 : 12,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
            padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
            ),
            child: Icon(
              prefixIcon,
              color: AdminDashboardStyles.primary,
              size: isMobile ? 16 : isTablet ? 17 : 18,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(
              color: AdminDashboardStyles.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : isTablet ? 15 : 16,
            vertical: isMobile ? 14 : isTablet ? 15 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String labelText,
    required IconData prefixIcon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isExpanded = false,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: isExpanded,
        validator: validator,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: isMobile ? 14 : isTablet ? 15 : 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
            padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
            ),
            child: Icon(
              prefixIcon,
              color: AdminDashboardStyles.primary,
              size: isMobile ? 16 : isTablet ? 17 : 18,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(
              color: AdminDashboardStyles.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : isTablet ? 15 : 16,
            vertical: isMobile ? 14 : isTablet ? 15 : 16,
          ),
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AdminDashboardStyles.primary,
          size: isMobile ? 20 : isTablet ? 22 : 24,
        ),
        menuMaxHeight: isMobile ? 300 : isTablet ? 350 : 400,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : isTablet ? 18 : 20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminDashboardStyles.primary.withOpacity(0.1),
                  AdminDashboardStyles.primaryLight.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
              border: Border.all(
                color: AdminDashboardStyles.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : isTablet ? 9 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AdminDashboardStyles.primary,
                        AdminDashboardStyles.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: AdminDashboardStyles.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isMobile ? 18 : isTablet ? 19 : 20,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : isTablet ? 14 : 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) {
      // Stack vertically on mobile
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
                border: Border.all(
                  color: AdminDashboardStyles.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AdminDashboardStyles.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : isTablet ? 15 : 16),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                    color: AdminDashboardStyles.primary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 10 : isTablet ? 12 : 12),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AdminDashboardStyles.primary,
                    AdminDashboardStyles.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
                boxShadow: [
                  BoxShadow(
                    color: AdminDashboardStyles.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPrincipal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : isTablet ? 15 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: isMobile ? 18 : isTablet ? 19 : 20,
                        height: isMobile ? 18 : isTablet ? 19 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Create Principal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Side by side on tablet/desktop
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 14 : 16),
                border: Border.all(
                  color: AdminDashboardStyles.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AdminDashboardStyles.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 15 : 16),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 16),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 15 : 16,
                    color: AdminDashboardStyles.primary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 12 : 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AdminDashboardStyles.primary,
                    AdminDashboardStyles.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 14 : 16),
                boxShadow: [
                  BoxShadow(
                    color: AdminDashboardStyles.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPrincipal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 15 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: isTablet ? 19 : 20,
                        height: isTablet ? 19 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Create Principal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
