import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/data/colleges_data.dart';

class CreateStudentPage extends StatefulWidget {
  final VoidCallback onStudentCreated;

  const CreateStudentPage({super.key, required this.onStudentCreated});

  @override
  State<CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends State<CreateStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instituteController = TextEditingController();
  final _courseController = TextEditingController();
  final _majorController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _passwordController = TextEditingController();
  final _yearOfStudyController = TextEditingController();

  String? _selectedGender;
  String? _selectedInstitute;
  DateTime? _selectedDateOfBirth;

  List<String> _institutes = List.from(collegesData);
  final List<String> _genders = ['Male', 'Female', 'Other'];
  List<String> _filteredInstitutes = [];
  final TextEditingController _instituteSearchController =
      TextEditingController();
  bool _showInstituteDropdown = false;
  final FocusNode _instituteFocusNode = FocusNode();

  bool _isLoading = false;
  int _currentStep = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _filteredInstitutes = List.from(_institutes);
    _instituteSearchController.addListener(_filterInstitutes);
    _instituteFocusNode.addListener(_onInstituteFocusChange);
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    // Initialize cache service (for consistency with other pages)
    await _cacheService.initialize();

    // Try to load institutes from cache if available
    final cachedInstitutes = await _cacheService.getAvailableInstitutes();
    if (cachedInstitutes != null && cachedInstitutes.isNotEmpty) {
      setState(() {
        _institutes = List.from(cachedInstitutes);
        _filteredInstitutes = List.from(_institutes);
      });
    } else {
      // Cache the static colleges data
      await _cacheService.setAvailableInstitutes(_institutes);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _studentNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _instituteController.dispose();
    _courseController.dispose();
    _majorController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _zipcodeController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _passwordController.dispose();
    _yearOfStudyController.dispose();
    _instituteSearchController.dispose();
    _instituteFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _filterInstitutes() {
    setState(() {
      _filteredInstitutes = _institutes
          .where(
            (institute) => institute.toLowerCase().contains(
              _instituteSearchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  void _onInstituteFocusChange() {
    setState(() {
      _showInstituteDropdown = _instituteFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 16
                    : isTablet
                    ? 20
                    : 24,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: const Color(0xFF2D3748),
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Create New Student',
                      style: TextStyle(
                        fontSize: isMobile
                            ? 18
                            : isTablet
                            ? 20
                            : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 48 : 56,
                  ), // Balance the back button
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Progress Indicator
                    _buildProgressIndicator(isMobile, isTablet, isDesktop),
                    // Form Content
                    Expanded(
                      child: _buildStepperForm(isMobile, isTablet, isDesktop),
                    ),
                    // Action Buttons
                    _buildFloatingActions(isMobile, isTablet, isDesktop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
        vertical: isMobile ? 12 : 16,
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: isMobile
                      ? 28
                      : isTablet
                      ? 30
                      : 32,
                  height: isMobile
                      ? 28
                      : isTablet
                      ? 30
                      : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              AdminDashboardStyles.primary,
                              AdminDashboardStyles.primary.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: isActive ? null : const Color(0xFFE2E8F0),
                    border: Border.all(
                      color: isActive
                          ? AdminDashboardStyles.primary
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: isMobile ? 16 : 18,
                        )
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF718096),
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  AdminDashboardStyles.primary,
                                  AdminDashboardStyles.primary.withOpacity(0.5),
                                ],
                              )
                            : null,
                        color: isCompleted ? null : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepperForm(bool isMobile, bool isTablet, bool isDesktop) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentStep = index;
        });
      },
      children: [
        _buildStep1PersonalInfo(isMobile, isTablet, isDesktop),
        _buildStep2AcademicInfo(isMobile, isTablet, isDesktop),
        _buildStep3AddressInfo(isMobile, isTablet, isDesktop),
      ],
    );
  }

  Widget _buildStep1PersonalInfo(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Personal Information',
            'Tell us about the student',
            isMobile,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          _buildFloatingCard(
            [
              _buildHolographicField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.badge_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.family_restroom_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.person_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _studentNameController,
                label: 'Student Name',
                icon: Icons.badge_outlined,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicDateField(isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_rounded,
                isPassword: true,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
            ],
            isMobile,
            isTablet,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2AcademicInfo(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Academic Information',
            'Educational background details',
            isMobile,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          _buildFloatingCard(
            [
              _buildSearchableInstituteField(isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _courseController,
                label: 'Course',
                icon: Icons.school_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _majorController,
                label: 'Major',
                icon: Icons.engineering_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _yearOfStudyController,
                label: 'Year of Study',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicDropdownField(
                label: 'Gender',
                icon: Icons.person_rounded,
                value: _selectedGender,
                items: _genders,
                onChanged: (value) => setState(() => _selectedGender = value),
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
            ],
            isMobile,
            isTablet,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3AddressInfo(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Address Information',
            'Student location details',
            isMobile,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          _buildFloatingCard(
            [
              _buildHolographicField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home_rounded,
                maxLines: 3,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _landmarkController,
                label: 'Landmark',
                icon: Icons.location_on_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              isMobile
                  ? Column(
                      children: [
                        _buildHolographicField(
                          controller: _zipcodeController,
                          label: 'Zipcode',
                          icon: Icons.pin_drop_rounded,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildHolographicField(
                          controller: _cityController,
                          label: 'City',
                          icon: Icons.location_city_rounded,
                          isRequired: true,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildHolographicField(
                            controller: _zipcodeController,
                            label: 'Zipcode',
                            icon: Icons.pin_drop_rounded,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),
                        Expanded(
                          child: _buildHolographicField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_rounded,
                            isRequired: true,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildHolographicField(
                controller: _districtController,
                label: 'District',
                icon: Icons.map_rounded,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 11
                        : 12,
                  ),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFF4299E1),
                      size: isMobile ? 18 : 20,
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Text(
                        'Student ID will be automatically generated. All information will be securely stored.',
                        style: TextStyle(
                          fontSize: isMobile
                              ? 12
                              : isTablet
                              ? 13
                              : 14,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            isMobile,
            isTablet,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 18
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AdminDashboardStyles.primary,
                        AdminDashboardStyles.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                    boxShadow: [
                      BoxShadow(
                        color: AdminDashboardStyles.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNextOrSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: isMobile ? 16 : 18,
                              height: isMobile ? 16 : 18,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentStep == 2 ? 'Create Student' : 'Next',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 5 : 6),
                                Icon(
                                  _currentStep == 2
                                      ? Icons.person_add_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: isMobile ? 16 : 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  SizedBox(height: isMobile ? 12 : 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: isMobile ? 16 : 18,
                            ),
                            SizedBox(width: isMobile ? 5 : 6),
                            Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isTablet ? 12 : 14,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: isTablet ? 16 : 18,
                            ),
                            SizedBox(width: isTablet ? 5 : 6),
                            Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: isTablet ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: isTablet ? 10 : 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AdminDashboardStyles.primary,
                          AdminDashboardStyles.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 14),
                      boxShadow: [
                        BoxShadow(
                          color: AdminDashboardStyles.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNextOrSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isTablet ? 12 : 14,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: isTablet ? 16 : 18,
                              height: isTablet ? 16 : 18,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentStep == 2 ? 'Create Student' : 'Next',
                                  style: TextStyle(
                                    fontSize: isTablet ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 5 : 6),
                                Icon(
                                  _currentStep == 2
                                      ? Icons.person_add_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: isTablet ? 16 : 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepTitle(
    String title,
    String subtitle,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile
                ? 22
                : isTablet
                ? 24
                : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isMobile
                ? 14
                : isTablet
                ? 15
                : 16,
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFloatingCard(
    List<Widget> children,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 20
            : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isMobile
              ? 16
              : isTablet
              ? 18
              : 20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AdminDashboardStyles.primary.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildHolographicField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              isMobile
                  ? 12
                  : isTablet
                  ? 14
                  : 16,
            ),
            gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFFAFAFA)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: label == 'Phone Number' ? 10 : null,
            inputFormatters: label == 'Phone Number'
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: EdgeInsets.all(isMobile ? 10 : 12),
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AdminDashboardStyles.primary.withOpacity(0.1),
                      AdminDashboardStyles.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  border: Border.all(
                    color: AdminDashboardStyles.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AdminDashboardStyles.primary,
                  size: isMobile ? 18 : 20,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 16
                    : isTablet
                    ? 18
                    : 20,
                vertical: isMobile
                    ? 14
                    : isTablet
                    ? 16
                    : 18,
              ),
              hintText: 'Enter ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: const Color(0xFFA0AEC0),
                fontSize: isMobile
                    ? 13
                    : isTablet
                    ? 13.5
                    : 14,
                fontWeight: FontWeight.w400,
              ),
              counterText: label == 'Phone Number' ? '' : null,
            ),
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return '${label} is required';
              }

              // Email validation
              if (label == 'Email Address' &&
                  value != null &&
                  value.isNotEmpty) {
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
              }

              // Phone number validation
              if (label == 'Phone Number' &&
                  value != null &&
                  value.isNotEmpty) {
                if (value.length != 10) {
                  return 'Phone number must be exactly 10 digits';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                  return 'Phone number must contain only digits';
                }
                // Check if it starts with valid digits (6-9 for Indian numbers)
                if (!RegExp(r'^[6-9]').hasMatch(value)) {
                  return 'Phone number must start with 6, 7, 8, or 9';
                }
              }

              // Password validation
              if (label == 'Password' && value != null && value.isNotEmpty) {
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(
                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                ).hasMatch(value)) {
                  return 'Password must contain uppercase, lowercase, and number';
                }
              }

              // Name validation
              if ((label == 'First Name' || label == 'Last Name') &&
                  value != null &&
                  value.isNotEmpty) {
                if (value.length < 2) {
                  return '${label} must be at least 2 characters';
                }
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                  return '${label} can only contain letters and spaces';
                }
              }

              // Year of study validation
              if (label == 'Year of Study' &&
                  value != null &&
                  value.isNotEmpty) {
                final year = int.tryParse(value);
                if (year == null) {
                  return 'Please enter a valid year';
                }
                if (year < 1 || year > 10) {
                  return 'Year must be between 1 and 10';
                }
              }

              // Zipcode validation
              if (label == 'Zipcode' && value != null && value.isNotEmpty) {
                if (value.length != 6) {
                  return 'Zipcode must be exactly 6 digits';
                }
                if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                  return 'Zipcode must contain only digits';
                }
              }

              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHolographicDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + ' *',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              isMobile
                  ? 12
                  : isTablet
                  ? 14
                  : 16,
            ),
            gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFFAFAFA)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: isMobile
                        ? 13
                        : isTablet
                        ? 13.5
                        : 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: EdgeInsets.all(isMobile ? 10 : 12),
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AdminDashboardStyles.primary.withOpacity(0.1),
                      AdminDashboardStyles.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  border: Border.all(
                    color: AdminDashboardStyles.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AdminDashboardStyles.primary,
                  size: isMobile ? 18 : 20,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 16
                    : isTablet
                    ? 18
                    : 20,
                vertical: isMobile
                    ? 14
                    : isTablet
                    ? 16
                    : 18,
              ),
              hintText: 'Select ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: const Color(0xFFA0AEC0),
                fontSize: isMobile
                    ? 13
                    : isTablet
                    ? 13.5
                    : 14,
                fontWeight: FontWeight.w400,
              ),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF718096),
                size: isMobile
                    ? 20
                    : isTablet
                    ? 22
                    : 24,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${label} is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHolographicDateField(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth *',
          style: TextStyle(
            fontSize: isMobile
                ? 13
                : isTablet
                ? 13.5
                : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              isMobile
                  ? 12
                  : isTablet
                  ? 14
                  : 16,
            ),
            gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFFAFAFA)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _selectedDateOfBirth ??
                    DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(
                  const Duration(days: 365 * 13),
                ), // Minimum age 13
              );
              if (date != null) {
                setState(() => _selectedDateOfBirth = date);
              }
            },
            borderRadius: BorderRadius.circular(
              isMobile
                  ? 12
                  : isTablet
                  ? 14
                  : 16,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 16
                    : isTablet
                    ? 18
                    : 20,
                vertical: isMobile
                    ? 14
                    : isTablet
                    ? 16
                    : 18,
              ),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: isMobile ? 10 : 12),
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AdminDashboardStyles.primary.withOpacity(0.1),
                          AdminDashboardStyles.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      border: Border.all(
                        color: AdminDashboardStyles.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.cake_rounded,
                      color: AdminDashboardStyles.primary,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _selectedDateOfBirth != null
                          ? '${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.year}'
                          : 'Select date of birth',
                      style: TextStyle(
                        color: _selectedDateOfBirth != null
                            ? const Color(0xFF2D3748)
                            : const Color(0xFFA0AEC0),
                        fontSize: isMobile
                            ? 13
                            : isTablet
                            ? 13.5
                            : 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: isMobile ? 18 : 20,
                    color: const Color(0xFF718096),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add validation message for date of birth
        if (_selectedDateOfBirth == null && _currentStep == 0)
          Padding(
            padding: EdgeInsets.only(top: isMobile ? 3 : 4),
            child: Text(
              'Date of birth is required',
              style: TextStyle(color: Colors.red, fontSize: isMobile ? 11 : 12),
            ),
          ),
      ],
    );
  }

  void _handleNextOrSubmit() {
    // Validate current step before proceeding
    bool isValid = true;

    if (_currentStep == 0) {
      // Validate Step 1: Personal Information
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _usernameController.text.trim().isEmpty ||
          _studentNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _passwordController.text.isEmpty ||
          _selectedDateOfBirth == null) {
        isValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_currentStep == 1) {
      // Validate Step 2: Academic Information
      if (_selectedInstitute == null ||
          _courseController.text.trim().isEmpty ||
          _majorController.text.trim().isEmpty ||
          _yearOfStudyController.text.trim().isEmpty ||
          _selectedGender == null) {
        isValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_currentStep == 2) {
      // Validate Step 3: Address Information
      if (_addressController.text.trim().isEmpty ||
          _landmarkController.text.trim().isEmpty ||
          _zipcodeController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _districtController.text.trim().isEmpty) {
        isValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (isValid) {
      if (_currentStep < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _createStudent();
      }
    }
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final studentData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'studentName': _studentNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'institute': _selectedInstitute ?? '',
        'course': _courseController.text.trim(),
        'major': _majorController.text.trim(),
        'yearOfStudy': _yearOfStudyController.text.trim(),
        'address': _addressController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'zipcode': _zipcodeController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'password': _passwordController.text,
        'gender': _selectedGender,
        'dob': _selectedDateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
            : null,
      };

      final result = await _dashboardService.createStudent(studentData);

      if (result['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Student created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onStudentCreated();
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to create student');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSearchableInstituteField(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return GestureDetector(
      onTap: () {
        // This will be handled by the inner GestureDetector
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            isMobile
                ? 12
                : isTablet
                ? 14
                : 16,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AdminDashboardStyles.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AdminDashboardStyles.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showInstituteDropdown = true;
                  _instituteFocusNode.requestFocus();
                });
              },
              child: TextFormField(
                controller: _instituteSearchController,
                focusNode: _instituteFocusNode,
                onTap: () {
                  setState(() {
                    _showInstituteDropdown = true;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Container(
                    margin: EdgeInsets.all(isMobile ? 10 : 12),
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AdminDashboardStyles.primary.withOpacity(0.1),
                          AdminDashboardStyles.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      border: Border.all(
                        color: AdminDashboardStyles.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: AdminDashboardStyles.primary,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      isMobile
                          ? 12
                          : isTablet
                          ? 14
                          : 16,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 16
                        : isTablet
                        ? 18
                        : 20,
                    vertical: isMobile
                        ? 14
                        : isTablet
                        ? 16
                        : 18,
                  ),
                  hintText: _selectedInstitute ?? 'Search and select institute',
                  hintStyle: TextStyle(
                    color: const Color(0xFFA0AEC0),
                    fontSize: isMobile
                        ? 13
                        : isTablet
                        ? 13.5
                        : 14,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: _selectedInstitute != null
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: const Color(0xFF718096),
                            size: isMobile ? 18 : 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedInstitute = null;
                              _instituteSearchController.clear();
                              _filteredInstitutes = List.from(_institutes);
                            });
                          },
                        )
                      : Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF718096),
                          size: isMobile ? 18 : 20,
                        ),
                ),
                validator: (value) {
                  if (_selectedInstitute == null) {
                    return 'Please select an institute';
                  }
                  return null;
                },
              ),
            ),
            if (_showInstituteDropdown)
              Container(
                margin: EdgeInsets.only(top: isMobile ? 3 : 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 11
                        : 12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AdminDashboardStyles.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                constraints: BoxConstraints(maxHeight: isMobile ? 180 : 200),
                child: _filteredInstitutes.isEmpty
                    ? Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        child: Text(
                          'No institutes found',
                          style: TextStyle(
                            color: const Color(0xFF718096),
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredInstitutes.length,
                        itemBuilder: (context, index) {
                          final institute = _filteredInstitutes[index];
                          final isSelected = _selectedInstitute == institute;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedInstitute = institute;
                                _instituteSearchController.text = institute;
                                _showInstituteDropdown = false;
                                _instituteFocusNode.unfocus();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 10 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AdminDashboardStyles.primary.withOpacity(
                                        0.1,
                                      )
                                    : Colors.transparent,
                                border: index < _filteredInstitutes.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      institute,
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? AdminDashboardStyles.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AdminDashboardStyles.primary,
                                      size: isMobile ? 16 : 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
