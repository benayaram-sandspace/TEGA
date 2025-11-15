import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/profile_cache_service.dart';
import 'package:intl/intl.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final AuthService _authService = AuthService();
  final ProfileCacheService _cacheService = ProfileCacheService();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _profileImageError = false;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _editedData;
  String? _errorMessage;

  // Text controllers for editable fields
  final Map<String, TextEditingController> _controllers = {};
  
  // Validation errors map
  final Map<String, String?> _fieldErrors = {};

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadProfileData();
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    if (_profileData == null) return;

    // Initialize controllers for all editable fields
    final fields = [
      'firstName', 'lastName', 'email', 'phone', 'contactNumber',
      'alternateNumber', 'personalEmail', 'studentId', 'institute', 'course',
      'major', 'yearOfStudy', 'address', 'landmark', 'city', 'district',
      'state', 'country', 'zipcode', 'permanentAddress', 'title', 'summary',
      'linkedin', 'website', 'github', 'portfolio', 'behance', 'dribbble',
      'fatherName', 'fatherOccupation', 'fatherPhone', 'motherName',
      'motherOccupation', 'motherPhone', 'guardianName', 'guardianRelation',
      'guardianPhone', 'emergencyContact', 'emergencyPhone', 'nationality',
      'interests', 'achievements', 'publications', 'patents', 'awards',
      'jobType', 'preferredLocation', 'workMode', 'salaryExpectation',
      'noticePeriod', 'availability'
    ];

    for (var field in fields) {
      final value = _profileData![field];
      String textValue = '';
      if (value != null) {
        if (value is num) {
          textValue = value.toString();
        } else {
          textValue = value.toString();
        }
      }
      _controllers[field] = TextEditingController(text: textValue);
    }
  }

  Future<void> _loadProfileData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getProfileData();
      if (cachedData != null && mounted) {
        setState(() {
          _profileData = cachedData;
          _editedData = Map<String, dynamic>.from(_profileData!);
          _isLoading = false;
          _profileImageError = false;
        });
        _initializeControllers();
        // Still fetch in background to update cache
        _fetchProfileDataInBackground();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchProfileDataInBackground();
  }

  Future<void> _fetchProfileDataInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Cache the data
          await _cacheService.setProfileData(data['data']);
          
          if (mounted) {
            setState(() {
              _profileData = data['data'];
              _editedData = Map<String, dynamic>.from(_profileData!);
              _isLoading = false;
              _profileImageError = false;
            });
            _initializeControllers();
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedData = await _cacheService.getProfileData();
          if (cachedData != null) {
            setState(() {
              _profileData = cachedData;
              _editedData = Map<String, dynamic>.from(_profileData!);
              _errorMessage = null; // Clear error since we have cached data
              _isLoading = false;
              _profileImageError = false;
            });
            _initializeControllers();
            return;
          }
          // No cache available, show error
          setState(() {
            _errorMessage = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Unable to load profile. Please try again.';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_editedData == null || _profileData == null) return;

    // Validate all fields before saving
    if (!_validateAllFields()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the validation errors before saving'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final headers = _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Prepare update data - only include fields that have changed
      final updateData = <String, dynamic>{};
      
      // Fields that should NOT be sent (disabled fields)
      final excludedFields = {'studentId', 'institute'};
      
      // Array fields that are complex objects (not simple strings) - should not be sent as text
      final arrayObjectFields = {
        'achievements', 'projects', 'education', 'experience', 'skills',
        'certifications', 'languages', 'hobbies', 'volunteerExperience',
        'extracurricularActivities'
      };
      
      // Process text fields from controllers
      for (var entry in _controllers.entries) {
        final key = entry.key;
        if (excludedFields.contains(key)) continue; // Skip disabled fields
        if (arrayObjectFields.contains(key)) continue; // Skip array object fields (they need special handling)
        
        final value = entry.value.text.trim();
        // Email should be lowercase (backend requirement)
        if (key == 'email') {
          updateData[key] = value.toLowerCase();
        } else {
          // Send empty strings as empty string (backend will normalize)
          updateData[key] = value;
        }
      }
      
      // Note: Array fields (achievements, projects, education, etc.) are complex objects
      // and should not be sent as simple text strings. They require a proper UI for editing.
      // For now, we exclude them from updates to avoid validation errors.
      // If needed, these fields can be edited through a separate interface that handles
      // the array structure properly.

      // Process non-text fields from _editedData
      // Date of birth - ensure it's in ISO format
      if (_editedData!['dob'] != null) {
        final dob = _editedData!['dob'];
        if (dob is String) {
          updateData['dob'] = dob; // Already ISO string
        } else if (dob is DateTime) {
          updateData['dob'] = dob.toIso8601String();
        }
      }
      
      // Gender - normalize to match backend enum values
      if (_editedData!['gender'] != null && _editedData!['gender'].toString().isNotEmpty) {
        final gender = _editedData!['gender'].toString().trim();
        // Normalize to match backend: 'Male', 'Female', 'Other'
        final normalizedGender = gender.toLowerCase();
        if (normalizedGender == 'male') {
          updateData['gender'] = 'Male';
        } else if (normalizedGender == 'female') {
          updateData['gender'] = 'Female';
        } else if (normalizedGender == 'other' || normalizedGender == 'prefer-not-to-say') {
          updateData['gender'] = 'Other';
        } else if (['Male', 'Female', 'Other'].contains(gender)) {
          updateData['gender'] = gender; // Already correct
        }
      }
      
      // Marital status - trim whitespace
      if (_editedData!['maritalStatus'] != null && _editedData!['maritalStatus'].toString().isNotEmpty) {
        updateData['maritalStatus'] = _editedData!['maritalStatus'].toString().trim();
      }
      
      // Year of study - ensure it's a number
      if (_editedData!['yearOfStudy'] != null) {
        final yearValue = _editedData!['yearOfStudy'];
        if (yearValue is num) {
          updateData['yearOfStudy'] = yearValue.toInt();
        } else if (yearValue is String && yearValue.trim().isNotEmpty) {
          final parsed = int.tryParse(yearValue.trim());
          if (parsed != null) {
            updateData['yearOfStudy'] = parsed;
          }
        }
      }

      // Remove undefined/null values to avoid sending them
      updateData.removeWhere((key, value) => value == null);

      final response = await http.put(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update cache with new data
          if (data['data'] != null) {
            await _cacheService.setProfileData(data['data']);
          }
          
          setState(() {
            _isEditing = false;
            _profileData = data['data'];
            _editedData = Map<String, dynamic>.from(_profileData!);
          });
          _initializeControllers();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to update profile');
        }
      } else {
        String errorMessage = 'Failed to update profile';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        // Remove "Exception: " prefix if present
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editedData = Map<String, dynamic>.from(_profileData!);
      _fieldErrors.clear(); // Clear validation errors
    });
    _initializeControllers();
  }
  
  // Validation methods
  String? _validateField(String key, String value) {
    if (value.trim().isEmpty) {
      return null; // Empty is allowed for optional fields
    }
    
    switch (key) {
      case 'email':
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Please enter a valid email address';
        }
        break;
      case 'phone':
      case 'contactNumber':
      case 'fatherPhone':
      case 'motherPhone':
      case 'guardianPhone':
      case 'emergencyPhone':
        final phoneRegex = RegExp(r'^[0-9]{10}$');
        if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
          return 'Phone number must be exactly 10 digits';
        }
        break;
      case 'alternateNumber':
        final phoneRegex = RegExp(r'^[0-9]{10}$');
        final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleaned.isNotEmpty && !phoneRegex.hasMatch(cleaned)) {
          return 'Phone number must be exactly 10 digits';
        }
        break;
      case 'zipcode':
        final zipRegex = RegExp(r'^[0-9]{6}$');
        if (!zipRegex.hasMatch(value.trim())) {
          return 'Zipcode must be exactly 6 digits';
        }
        break;
      case 'yearOfStudy':
        final year = int.tryParse(value.trim());
        if (year == null || year < 1 || year > 10) {
          return 'Year of study must be between 1 and 10';
        }
        break;
      case 'personalEmail':
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Please enter a valid email address';
        }
        break;
    }
    return null;
  }
  
  bool _validateAllFields() {
    _fieldErrors.clear();
    bool isValid = true;
    
    for (var entry in _controllers.entries) {
      final key = entry.key;
      final value = entry.value.text;
      final error = _validateField(key, value);
      if (error != null) {
        _fieldErrors[key] = error;
        isValid = false;
      }
    }
    
    setState(() {}); // Update UI to show errors
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 26
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 20
                  : 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Profile",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isLargeDesktop
                  ? 22
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 19
                  : isSmallScreen
                  ? 16
                  : 18,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF6B5FFF),
            strokeWidth: isLargeDesktop
                ? 4
                : isDesktop
                ? 3.5
                : isTablet
                ? 3
                : isSmallScreen
                ? 2.5
                : 3,
          ),
        ),
      );
    }

    // Show error state if there's an error and no profile data
    if (_errorMessage != null && _profileData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 26
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 20
                  : 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Profile",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isLargeDesktop
                  ? 22
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 19
                  : isSmallScreen
                  ? 16
                  : 18,
            ),
          ),
        ),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileInfo(),
                SizedBox(
                  height: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                _buildContactInfo(),
                SizedBox(
                  height: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                _buildAcademicDetails(),
                SizedBox(
                  height: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                _buildAddressInfo(),
                SizedBox(
                  height: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                _buildParentGuardianInfo(),
                SizedBox(
                  height: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                _buildProfessionalInfo(),
                SizedBox(
                  height: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                _buildAdditionalInfo(),
                SizedBox(
                  height: isLargeDesktop
                      ? 48
                      : isDesktop
                      ? 40
                      : isTablet
                      ? 32
                      : isSmallScreen
                      ? 24
                      : 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: isLargeDesktop
          ? 280
          : isDesktop
          ? 260
          : isTablet
          ? 240
          : isSmallScreen
          ? 200
          : 230,
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor: const Color(0xFF6B5FFF),
      automaticallyImplyLeading: false,
      actions: [
        if (!_isEditing) ...[
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white,
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 26
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 20
                  : 22,
            ),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            tooltip: 'Edit Profile',
          ),
        ] else ...[
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: isLargeDesktop
                  ? 28
                  : isDesktop
                  ? 26
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 20
                  : 22,
            ),
            onPressed: _isSaving ? null : _cancelEdit,
            tooltip: 'Cancel',
          ),
          IconButton(
            icon: _isSaving
                ? SizedBox(
                    width: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 19
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 16
                        : 18,
                    height: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 19
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 16
                        : 18,
                    child: CircularProgressIndicator(
                      strokeWidth: isLargeDesktop
                          ? 2.5
                          : isDesktop
                          ? 2.2
                          : isTablet
                          ? 2
                          : isSmallScreen
                          ? 1.8
                          : 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.check,
                    color: Colors.white,
                    size: isLargeDesktop
                        ? 28
                        : isDesktop
                        ? 26
                        : isTablet
                        ? 24
                        : isSmallScreen
                        ? 20
                        : 22,
                  ),
            onPressed: _isSaving ? null : _saveProfile,
            tooltip: 'Save',
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B5FFF), Color(0xFF4A47A3)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 8
                        : 12,
                  ),
                  _buildProfileAvatar(),
                  SizedBox(
                    height: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 10
                        : isTablet
                        ? 8
                        : isSmallScreen
                        ? 6
                        : 8,
                  ),
                  Text(
                    _getFullName(),
                    style: TextStyle(
                      fontSize: isLargeDesktop
                          ? 28
                          : isDesktop
                          ? 26
                          : isTablet
                          ? 24
                          : isSmallScreen
                          ? 20
                          : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 6
                        : isDesktop
                        ? 5
                        : isTablet
                        ? 4
                        : isSmallScreen
                        ? 3
                        : 4,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeDesktop
                          ? 32
                          : isDesktop
                          ? 28
                          : isTablet
                          ? 24
                          : isSmallScreen
                          ? 16
                          : 20,
                    ),
                    child: Text(
                      _getAcademicInfo(),
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 16
                            : isDesktop
                            ? 15
                            : isTablet
                            ? 14
                            : isSmallScreen
                            ? 12
                            : 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 8
                        : 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'firstName',
            Icons.person_outline,
            'First Name',
            _controllers['firstName'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'lastName',
            Icons.person_outline,
            'Last Name',
            _controllers['lastName'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'email',
            Icons.email,
            'Email',
            _controllers['email'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'studentId',
            Icons.badge,
            'Student ID',
            _controllers['studentId'] ?? TextEditingController(),
            enabled: false, // Student ID cannot be changed
          ),
          _buildDateField('dob', Icons.cake, 'Date of Birth'),
          _buildDropdownField(
            'gender',
            Icons.person_outline,
            'Gender',
            ['Male', 'Female', 'Other'],
          ),
          _buildDropdownField(
            'maritalStatus',
            Icons.favorite_outline,
            'Marital Status',
            ['Single', 'Married', 'Divorced', 'Widowed'],
            allowCustom: true,
          ),
          _buildEditableField(
            'nationality',
            Icons.flag,
            'Nationality',
            _controllers['nationality'] ?? TextEditingController(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.phone,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'phone',
            Icons.phone,
            'Phone',
            _controllers['phone'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'contactNumber',
            Icons.phone_android,
            'Contact Number',
            _controllers['contactNumber'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'alternateNumber',
            Icons.phone_iphone,
            'Alternate Number',
            _controllers['alternateNumber'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'personalEmail',
            Icons.alternate_email,
            'Personal Email',
            _controllers['personalEmail'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'emergencyContact',
            Icons.emergency,
            'Emergency Contact Name',
            _controllers['emergencyContact'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'emergencyPhone',
            Icons.phone_in_talk,
            'Emergency Phone',
            _controllers['emergencyPhone'] ?? TextEditingController(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicDetails() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.school,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Academic Details',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'institute',
            Icons.account_balance,
            'Institute',
            _controllers['institute'] ?? TextEditingController(),
            enabled: false, // Institute cannot be changed
          ),
          _buildEditableField(
            'course',
            Icons.menu_book,
            'Course',
            _controllers['course'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'major',
            Icons.trending_up,
            'Major',
            _controllers['major'] ?? TextEditingController(),
          ),
          _buildNumberField(
            'yearOfStudy',
            Icons.calendar_today,
            'Year of Study',
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.location_on,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Address Information',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'address',
            Icons.home,
            'Address',
            _controllers['address'] ?? TextEditingController(),
            maxLines: 2,
          ),
          _buildEditableField(
            'landmark',
            Icons.place,
            'Landmark',
            _controllers['landmark'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'city',
            Icons.location_city,
            'City',
            _controllers['city'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'district',
            Icons.map,
            'District',
            _controllers['district'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'state',
            Icons.public,
            'State',
            _controllers['state'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'country',
            Icons.language,
            'Country',
            _controllers['country'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'zipcode',
            Icons.pin_drop,
            'ZIP Code',
            _controllers['zipcode'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'permanentAddress',
            Icons.home_work,
            'Permanent Address',
            _controllers['permanentAddress'] ?? TextEditingController(),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildParentGuardianInfo() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.family_restroom,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Parent/Guardian Information',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'fatherName',
            Icons.person,
            'Father\'s Name',
            _controllers['fatherName'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'fatherOccupation',
            Icons.work_outline,
            'Father\'s Occupation',
            _controllers['fatherOccupation'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'fatherPhone',
            Icons.phone,
            'Father\'s Phone',
            _controllers['fatherPhone'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'motherName',
            Icons.person,
            'Mother\'s Name',
            _controllers['motherName'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'motherOccupation',
            Icons.work_outline,
            'Mother\'s Occupation',
            _controllers['motherOccupation'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'motherPhone',
            Icons.phone,
            'Mother\'s Phone',
            _controllers['motherPhone'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'guardianName',
            Icons.person,
            'Guardian\'s Name',
            _controllers['guardianName'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'guardianRelation',
            Icons.people_outline,
            'Guardian Relation',
            _controllers['guardianRelation'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'guardianPhone',
            Icons.phone,
            'Guardian\'s Phone',
            _controllers['guardianPhone'] ?? TextEditingController(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.work,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'title',
            Icons.title,
            'Title',
            _controllers['title'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'summary',
            Icons.description,
            'Summary',
            _controllers['summary'] ?? TextEditingController(),
            maxLines: 3,
          ),
          _buildEditableField(
            'linkedin',
            Icons.link,
            'LinkedIn',
            _controllers['linkedin'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'website',
            Icons.web,
            'Website',
            _controllers['website'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'github',
            Icons.code,
            'GitHub',
            _controllers['github'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'portfolio',
            Icons.business_center,
            'Portfolio',
            _controllers['portfolio'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'behance',
            Icons.palette,
            'Behance',
            _controllers['behance'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'dribbble',
            Icons.design_services,
            'Dribbble',
            _controllers['dribbble'] ?? TextEditingController(),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          Divider(
            thickness: isLargeDesktop || isDesktop ? 1.5 : 1,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          Text(
            'Job Preferences',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 17
                  : isSmallScreen
                  ? 14
                  : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 16,
          ),
          _buildEditableField(
            'jobType',
            Icons.business,
            'Job Type',
            _controllers['jobType'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'preferredLocation',
            Icons.location_city,
            'Preferred Location',
            _controllers['preferredLocation'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'workMode',
            Icons.work_outline,
            'Work Mode',
            _controllers['workMode'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'salaryExpectation',
            Icons.attach_money,
            'Salary Expectation',
            _controllers['salaryExpectation'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'noticePeriod',
            Icons.schedule,
            'Notice Period',
            _controllers['noticePeriod'] ?? TextEditingController(),
          ),
          _buildEditableField(
            'availability',
            Icons.event_available,
            'Availability',
            _controllers['availability'] ?? TextEditingController(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 12
            : 20,
      ),
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 28
            : isDesktop
            ? 24
            : isTablet
            ? 20
            : isSmallScreen
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: isLargeDesktop || isDesktop ? 1.5 : 1,
            blurRadius: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 8
                : isSmallScreen
                ? 6
                : 10,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 3
                  : isDesktop
                  ? 2.5
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1.5
                  : 2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 13
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: const Color(0xFF6B5FFF),
                  size: isLargeDesktop
                      ? 28
                      : isDesktop
                      ? 26
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 20
                      : 24,
                ),
              ),
              SizedBox(
                width: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Expanded(
                child: Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 22
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 19
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 16
                : 20,
          ),
          _buildEditableField(
            'interests',
            Icons.favorite,
            'Interests',
            _controllers['interests'] ?? TextEditingController(),
            maxLines: 2,
          ),
          _buildEditableField(
            'achievements',
            Icons.emoji_events,
            'Achievements',
            _controllers['achievements'] ?? TextEditingController(),
            maxLines: 3,
          ),
          _buildEditableField(
            'publications',
            Icons.article,
            'Publications',
            _controllers['publications'] ?? TextEditingController(),
            maxLines: 2,
          ),
          _buildEditableField(
            'patents',
            Icons.description,
            'Patents',
            _controllers['patents'] ?? TextEditingController(),
            maxLines: 2,
          ),
          _buildEditableField(
            'awards',
            Icons.stars,
            'Awards',
            _controllers['awards'] ?? TextEditingController(),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String key,
    IconData icon,
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    // Get input formatters based on field type
    List<TextInputFormatter>? inputFormatters;
    TextInputType? keyboardType;
    
    if (key == 'phone' || key == 'contactNumber' || key == 'alternateNumber' ||
        key == 'fatherPhone' || key == 'motherPhone' || key == 'guardianPhone' ||
        key == 'emergencyPhone') {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];
      keyboardType = TextInputType.phone;
    } else if (key == 'zipcode') {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ];
      keyboardType = TextInputType.number;
    } else if (key == 'email' || key == 'personalEmail') {
      keyboardType = TextInputType.emailAddress;
    } else if (key == 'yearOfStudy') {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ];
      keyboardType = TextInputType.number;
    }
    
    final errorText = _fieldErrors[key];
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
            color: Colors.grey[600],
          ),
          SizedBox(
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 11
                        : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                _isEditing && enabled
                    ? TextFormField(
                        controller: controller,
                        enabled: enabled,
                        maxLines: maxLines,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 13
                              : 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (value) {
                          if (value != null) {
                            final error = _validateField(key, value);
                            if (error != null) {
                              _fieldErrors[key] = error;
                              return error;
                            }
                          }
                          _fieldErrors[key] = null;
                          return null;
                        },
                        onChanged: (value) {
                          // Clear error when user starts typing
                          if (_fieldErrors.containsKey(key) && _fieldErrors[key] != null) {
                            final error = _validateField(key, value);
                            setState(() {
                              _fieldErrors[key] = error;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 14
                                : isTablet
                                ? 12
                                : isSmallScreen
                                ? 10
                                : 12,
                            vertical: isLargeDesktop
                                ? 12
                                : isDesktop
                                ? 10
                                : isTablet
                                ? 8
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          errorText: errorText,
                          errorMaxLines: 2,
                          errorStyle: TextStyle(
                            fontSize: isLargeDesktop
                                ? 13
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 10
                                : 11,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : const Color(0xFF6B5FFF),
                              width: isLargeDesktop || isDesktop ? 2.5 : 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: isLargeDesktop || isDesktop ? 2 : 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: isLargeDesktop || isDesktop ? 2.5 : 2,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not provided' : controller.text,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 13
                              : 14,
                          color: controller.text.isEmpty
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String key, IconData icon, String label) {
    final dob = _editedData?['dob'];
    String displayValue = 'Not provided';
    if (dob != null) {
      try {
        final date = dob is String ? DateTime.parse(dob) : dob as DateTime;
        displayValue = DateFormat('yyyy-MM-dd').format(date);
      } catch (_) {}
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
            color: Colors.grey[600],
          ),
          SizedBox(
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 11
                        : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                _isEditing
                    ? InkWell(
                        onTap: () async {
                          final initialDate = dob != null
                              ? (dob is String ? DateTime.parse(dob) : dob as DateTime)
                              : DateTime.now().subtract(const Duration(days: 365 * 18));
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _editedData![key] = picked.toIso8601String();
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 14
                                : isTablet
                                ? 12
                                : isSmallScreen
                                ? 10
                                : 12,
                            vertical: isLargeDesktop
                                ? 12
                                : isDesktop
                                ? 10
                                : isTablet
                                ? 8
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                displayValue,
                                style: TextStyle(
                                  fontSize: isLargeDesktop
                                      ? 16
                                      : isDesktop
                                      ? 15
                                      : isTablet
                                      ? 14
                                      : isSmallScreen
                                      ? 13
                                      : 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.calendar_today,
                                size: isLargeDesktop
                                    ? 20
                                    : isDesktop
                                    ? 18
                                    : isTablet
                                    ? 16
                                    : isSmallScreen
                                    ? 14
                                    : 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 13
                              : 14,
                          color: displayValue == 'Not provided'
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String key,
    IconData icon,
    String label,
    List<String> options, {
    bool allowCustom = false,
  }) {
    final currentValue = _editedData?[key]?.toString() ?? '';
    final selectedValue = options.contains(currentValue) ? currentValue : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
            color: Colors.grey[600],
          ),
          SizedBox(
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 11
                        : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                _isEditing
                    ? DropdownButtonFormField<String>(
                        value: selectedValue,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 14
                                : isTablet
                                ? 12
                                : isSmallScreen
                                ? 10
                                : 12,
                            vertical: isLargeDesktop
                                ? 12
                                : isDesktop
                                ? 10
                                : isTablet
                                ? 8
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: const Color(0xFF6B5FFF),
                              width: isLargeDesktop || isDesktop ? 2.5 : 2,
                            ),
                          ),
                        ),
                        items: [
                          if (allowCustom && currentValue.isNotEmpty && !options.contains(currentValue))
                            DropdownMenuItem(
                              value: currentValue,
                              child: Text(
                                currentValue,
                                style: TextStyle(
                                  fontSize: isLargeDesktop
                                      ? 16
                                      : isDesktop
                                      ? 15
                                      : isTablet
                                      ? 14
                                      : isSmallScreen
                                      ? 13
                                      : 14,
                                ),
                              ),
                            ),
                          ...options.map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: isLargeDesktop
                                        ? 16
                                        : isDesktop
                                        ? 15
                                        : isTablet
                                        ? 14
                                        : isSmallScreen
                                        ? 13
                                        : 14,
                                  ),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _editedData![key] = value;
                          });
                        },
                      )
                    : Text(
                        currentValue.isEmpty ? 'Not specified' : currentValue,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 13
                              : 14,
                          color: currentValue.isEmpty
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String key, IconData icon, String label) {
    final controller = _controllers[key] ?? TextEditingController();
    if (!_controllers.containsKey(key)) {
      _controllers[key] = controller;
    }
    
    final errorText = _fieldErrors[key];
    final inputFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      if (key == 'yearOfStudy') LengthLimitingTextInputFormatter(2),
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 24
                : isDesktop
                ? 22
                : isTablet
                ? 20
                : isSmallScreen
                ? 18
                : 20,
            color: Colors.grey[600],
          ),
          SizedBox(
            width: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 10
                : 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12
                        : isSmallScreen
                        ? 11
                        : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 6
                      : isDesktop
                      ? 5
                      : isTablet
                      ? 4
                      : isSmallScreen
                      ? 3
                      : 4,
                ),
                _isEditing
                    ? TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: inputFormatters,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 13
                              : 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final error = _validateField(key, value);
                            if (error != null) {
                              _fieldErrors[key] = error;
                              return error;
                            }
                          }
                          _fieldErrors[key] = null;
                          return null;
                        },
                        onChanged: (value) {
                          final numValue = int.tryParse(value);
                          if (numValue != null) {
                            _editedData![key] = numValue;
                          }
                          // Clear error when user starts typing
                          if (_fieldErrors.containsKey(key) && _fieldErrors[key] != null) {
                            final error = _validateField(key, value);
                            setState(() {
                              _fieldErrors[key] = error;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 14
                                : isTablet
                                ? 12
                                : isSmallScreen
                                ? 10
                                : 12,
                            vertical: isLargeDesktop
                                ? 12
                                : isDesktop
                                ? 10
                                : isTablet
                                ? 8
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          errorText: errorText,
                          errorMaxLines: 2,
                          errorStyle: TextStyle(
                            fontSize: isLargeDesktop
                                ? 13
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 10
                                : 11,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                              width: isLargeDesktop || isDesktop ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : const Color(0xFF6B5FFF),
                              width: isLargeDesktop || isDesktop ? 2.5 : 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: isLargeDesktop || isDesktop ? 2 : 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 9
                                  : isTablet
                                  ? 8
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: isLargeDesktop || isDesktop ? 2.5 : 2,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty
                            ? 'Not specified'
                            : controller.text,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 13
                              : 14,
                          color: controller.text.isEmpty
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFullName() {
    final firstName = _profileData?['firstName'] ?? '';
    final lastName = _profileData?['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return _profileData?['studentName'] ?? 'Student';
    }
  }

  String _getAcademicInfo() {
    final course = _profileData?['course'] ?? '';
    final year = _profileData?['yearOfStudy']?.toString() ?? '';
    final institute = _profileData?['institute'] ?? '';

    List<String> info = [];
    if (course.isNotEmpty) info.add(course);
    if (year.isNotEmpty) info.add('Year $year');
    if (institute.isNotEmpty) info.add(institute);

    return info.isNotEmpty
        ? info.join(' • ')
        : 'Academic information not provided';
  }

  Widget _buildProfileAvatar() {
    final profilePhoto = _profileData?['profilePhoto'] ??
        _profileData?['profilePicture']?['url'];
    final username = _profileData?['username'] ?? _profileData?['email'] ?? 'U';
    final initials = _getInitials(username);
    final hasPhoto = profilePhoto != null && 
        profilePhoto.toString().isNotEmpty && 
        !_profileImageError;

    return Stack(
      children: [
        CircleAvatar(
          radius: isLargeDesktop
              ? 55
              : isDesktop
              ? 50
              : isTablet
              ? 45
              : isSmallScreen
              ? 35
              : 45,
          backgroundColor: const Color(0xFF6B5FFF),
          backgroundImage: hasPhoto
              ? CachedNetworkImageProvider(profilePhoto.toString())
              : null,
          // Only set onBackgroundImageError when backgroundImage is not null
          onBackgroundImageError: hasPhoto
              ? (exception, stackTrace) {
                  // Handle image loading errors (404, network errors, etc.)
                  if (mounted) {
                    setState(() {
                      _profileImageError = true;
                    });
                  }
                }
              : null,
          child: !hasPhoto
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 34
                        : isDesktop
                        ? 32
                        : isTablet
                        ? 28
                        : isSmallScreen
                        ? 22
                        : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : _isUploadingPhoto
                  ? CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: isLargeDesktop || isDesktop ? 3 : 2.5,
                    )
                  : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(),
              child: Container(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6B5FFF),
                    width: isLargeDesktop || isDesktop ? 2.5 : 2,
                  ),
                ),
                child: _isUploadingPhoto
                    ? SizedBox(
                        width: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 16
                            : isSmallScreen
                            ? 12
                            : 16,
                        height: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 16
                            : isSmallScreen
                            ? 12
                            : 16,
                        child: CircularProgressIndicator(
                          strokeWidth: isLargeDesktop || isDesktop ? 2.5 : 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
                        ),
                      )
                    : Icon(
                        Icons.camera_alt,
                        size: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 16
                            : isSmallScreen
                            ? 12
                            : 16,
                        color: const Color(0xFF6B5FFF),
                      ),
              ),
            ),
          ),
      ],
    );
  }
  
  void _showPhotoOptions() {
    final hasPhoto = (_profileData?['profilePhoto'] ??
            _profileData?['profilePicture']?['url']) != null &&
        (_profileData?['profilePhoto'] ??
                _profileData?['profilePicture']?['url'])
            .toString()
            .isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6B5FFF)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePhoto();
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickAndUploadImage() async {
    try {
      // Using file_picker for cross-platform compatibility
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        
        // Handle both path and bytes (for web/Android compatibility)
        File? file;
        List<int>? fileBytes;
        
        // Prefer bytes if available (more reliable on Android)
        if (pickedFile.bytes != null) {
          fileBytes = pickedFile.bytes;
        } else if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
          file = File(pickedFile.path!);
          // Check if file exists
          if (!await file.exists()) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected file not found. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          // Read bytes from file for more reliable upload
          try {
            fileBytes = await file.readAsBytes();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error reading file: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to access selected file. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Check file size (5MB limit)
        if (fileBytes == null || fileBytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected file is empty. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        final fileSize = fileBytes.length;
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Use bytes-based upload (more reliable)
        await _uploadProfilePhotoFromBytes(fileBytes, pickedFile.name);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: ${e.message ?? e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _uploadProfilePhotoFromBytes(List<int> bytes, String fileName) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final headers = _authService.getAuthHeaders();
      
      // Determine content type from file extension
      String contentType = 'image/jpeg';
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          contentType = 'image/jpeg';
      }
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.r2ProfilePictureUpload),
      );
      
      // Add headers (don't set Content-Type, let multipart set it)
      request.headers.addAll(headers);
      request.headers.remove('Content-Type'); // Remove if present, let multipart set it
      
      // Add file from bytes with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'profilePicture',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout. Please check your connection and try again.');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update profile picture using the R2 data
          await _updateProfilePictureWithR2Data(data['data']);
        } else {
          // Try legacy upload endpoint
          await _legacyUploadProfilePhoto(bytes, fileName, contentType);
        }
      } else if (response.statusCode == 500) {
        // Server error - try to get error message
        String errorMessage = 'Server error occurred';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        
        // Try legacy upload as fallback
        try {
          await _legacyUploadProfilePhoto(bytes, fileName, contentType);
        } catch (legacyError) {
          // If legacy also fails, show the original error
          throw Exception('R2 Upload failed: $errorMessage. Legacy upload also failed: ${legacyError.toString()}');
        }
      } else {
        // Other errors - try legacy upload
        String errorMessage = 'Upload failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        
        try {
          await _legacyUploadProfilePhoto(bytes, fileName, contentType);
        } catch (legacyError) {
          throw Exception('$errorMessage (Status: ${response.statusCode})');
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload timeout. Please check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _legacyUploadProfilePhoto(List<int> bytes, String fileName, String contentType) async {
    // Try legacy student endpoint: POST /api/student/profile/photo with field 'profilePhoto'
    try {
      final headers = _authService.getAuthHeaders();
      var legacyRequest = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.studentUploadPhoto),
      );
      legacyRequest.headers.addAll(headers);
      legacyRequest.headers.remove('Content-Type');
      legacyRequest.files.add(
        http.MultipartFile.fromBytes(
          'profilePhoto',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );

      final streamed = await legacyRequest.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Legacy upload timeout');
        },
      );
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Reload profile data to reflect new photo
        await _loadProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to upload photo';
        try {
          final errorData = json.decode(resp.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Server error: ${resp.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw to be caught by caller
      throw Exception('Legacy upload failed: ${e.toString()}');
    }
  }
  
  Future<void> _updateProfilePictureWithR2Data(Map<String, dynamic> r2Data) async {
    try {
      final headers = _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.put(
        Uri.parse(ApiEndpoints.studentUpdateProfilePicture),
        headers: headers,
        body: json.encode(r2Data),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Reload profile data to get updated photo
          await _loadProfileData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile photo updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to update profile picture');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile picture');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteProfilePhoto() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final headers = _authService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse(ApiEndpoints.studentRemovePhoto),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Reload profile data
        await _loadProfileData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to remove photo');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  String _getInitials(String username) {
    if (username.isEmpty) return 'U';

    String name = username;
    if (username.contains('@')) {
      name = username.split('@')[0];
    }

    final words = name
        .split(RegExp(r'[._\s]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }

  Widget _buildErrorState() {
    final isNoInternet = _errorMessage == 'No internet connection';
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 48
              : isDesktop
              ? 40
              : isTablet
              ? 36
              : isSmallScreen
              ? 24
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isLargeDesktop
                  ? 80
                  : isDesktop
                  ? 72
                  : isTablet
                  ? 64
                  : isSmallScreen
                  ? 48
                  : 56,
              color: Colors.grey[400],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            Text(
              isNoInternet
                  ? 'No internet connection'
                  : 'Failed to Load Profile',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 16
                    : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (isNoInternet) ...[
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
              ),
            ] else ...[
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
              ),
            ],
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 24,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadProfileData(forceRefresh: true);
              },
              icon: Icon(
                Icons.refresh,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
                color: Colors.white,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 13
                      : 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 28
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 16
                      : 20,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 11
                        : isTablet
                        ? 10
                        : isSmallScreen
                        ? 8
                        : 9,
                  ),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
