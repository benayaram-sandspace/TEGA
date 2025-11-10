import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:intl/intl.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _editedData;

  // Text controllers for editable fields
  final Map<String, TextEditingController> _controllers = {};
  
  // Validation errors map
  final Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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

  Future<void> _loadProfileData() async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _profileData = data['data'];
            _editedData = Map<String, dynamic>.from(_profileData!);
            _isLoading = false;
          });
          _initializeControllers();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
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
                const SizedBox(height: 16),
                _buildContactInfo(),
                const SizedBox(height: 16),
                _buildAcademicDetails(),
                const SizedBox(height: 16),
                _buildAddressInfo(),
                const SizedBox(height: 16),
                _buildParentGuardianInfo(),
                const SizedBox(height: 16),
                _buildProfessionalInfo(),
                const SizedBox(height: 16),
                _buildAdditionalInfo(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 230,
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor: const Color(0xFF6B5FFF),
      automaticallyImplyLeading: false,
      actions: [
        if (!_isEditing) ...[
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            tooltip: 'Edit Profile',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _isSaving ? null : _cancelEdit,
            tooltip: 'Cancel',
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white),
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
                  const SizedBox(height: 12),
                  _buildProfileAvatar(),
                  const SizedBox(height: 8),
                  Text(
                    _getFullName(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _getAcademicInfo(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'firstName',
            Icons.person_outline,
            'First Name',
            _controllers['firstName']!,
          ),
          _buildEditableField(
            'lastName',
            Icons.person_outline,
            'Last Name',
            _controllers['lastName']!,
          ),
          _buildEditableField(
            'email',
            Icons.email,
            'Email',
            _controllers['email']!,
          ),
          _buildEditableField(
            'studentId',
            Icons.badge,
            'Student ID',
            _controllers['studentId']!,
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
            _controllers['nationality']!,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'phone',
            Icons.phone,
            'Phone',
            _controllers['phone']!,
          ),
          _buildEditableField(
            'contactNumber',
            Icons.phone_android,
            'Contact Number',
            _controllers['contactNumber']!,
          ),
          _buildEditableField(
            'alternateNumber',
            Icons.phone_iphone,
            'Alternate Number',
            _controllers['alternateNumber']!,
          ),
          _buildEditableField(
            'personalEmail',
            Icons.alternate_email,
            'Personal Email',
            _controllers['personalEmail']!,
          ),
          _buildEditableField(
            'emergencyContact',
            Icons.emergency,
            'Emergency Contact Name',
            _controllers['emergencyContact']!,
          ),
          _buildEditableField(
            'emergencyPhone',
            Icons.phone_in_talk,
            'Emergency Phone',
            _controllers['emergencyPhone']!,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Academic Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'institute',
            Icons.account_balance,
            'Institute',
            _controllers['institute']!,
            enabled: false, // Institute cannot be changed
          ),
          _buildEditableField(
            'course',
            Icons.menu_book,
            'Course',
            _controllers['course']!,
          ),
          _buildEditableField(
            'major',
            Icons.trending_up,
            'Major',
            _controllers['major']!,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Address Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'address',
            Icons.home,
            'Address',
            _controllers['address']!,
            maxLines: 2,
          ),
          _buildEditableField(
            'landmark',
            Icons.place,
            'Landmark',
            _controllers['landmark']!,
          ),
          _buildEditableField(
            'city',
            Icons.location_city,
            'City',
            _controllers['city']!,
          ),
          _buildEditableField(
            'district',
            Icons.map,
            'District',
            _controllers['district']!,
          ),
          _buildEditableField(
            'state',
            Icons.public,
            'State',
            _controllers['state']!,
          ),
          _buildEditableField(
            'country',
            Icons.language,
            'Country',
            _controllers['country']!,
          ),
          _buildEditableField(
            'zipcode',
            Icons.pin_drop,
            'ZIP Code',
            _controllers['zipcode']!,
          ),
          _buildEditableField(
            'permanentAddress',
            Icons.home_work,
            'Permanent Address',
            _controllers['permanentAddress']!,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildParentGuardianInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.family_restroom,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Parent/Guardian Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'fatherName',
            Icons.person,
            'Father\'s Name',
            _controllers['fatherName']!,
          ),
          _buildEditableField(
            'fatherOccupation',
            Icons.work_outline,
            'Father\'s Occupation',
            _controllers['fatherOccupation']!,
          ),
          _buildEditableField(
            'fatherPhone',
            Icons.phone,
            'Father\'s Phone',
            _controllers['fatherPhone']!,
          ),
          _buildEditableField(
            'motherName',
            Icons.person,
            'Mother\'s Name',
            _controllers['motherName']!,
          ),
          _buildEditableField(
            'motherOccupation',
            Icons.work_outline,
            'Mother\'s Occupation',
            _controllers['motherOccupation']!,
          ),
          _buildEditableField(
            'motherPhone',
            Icons.phone,
            'Mother\'s Phone',
            _controllers['motherPhone']!,
          ),
          _buildEditableField(
            'guardianName',
            Icons.person,
            'Guardian\'s Name',
            _controllers['guardianName']!,
          ),
          _buildEditableField(
            'guardianRelation',
            Icons.people_outline,
            'Guardian Relation',
            _controllers['guardianRelation']!,
          ),
          _buildEditableField(
            'guardianPhone',
            Icons.phone,
            'Guardian\'s Phone',
            _controllers['guardianPhone']!,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'title',
            Icons.title,
            'Title',
            _controllers['title']!,
          ),
          _buildEditableField(
            'summary',
            Icons.description,
            'Summary',
            _controllers['summary']!,
            maxLines: 3,
          ),
          _buildEditableField(
            'linkedin',
            Icons.link,
            'LinkedIn',
            _controllers['linkedin']!,
          ),
          _buildEditableField(
            'website',
            Icons.web,
            'Website',
            _controllers['website']!,
          ),
          _buildEditableField(
            'github',
            Icons.code,
            'GitHub',
            _controllers['github']!,
          ),
          _buildEditableField(
            'portfolio',
            Icons.business_center,
            'Portfolio',
            _controllers['portfolio']!,
          ),
          _buildEditableField(
            'behance',
            Icons.palette,
            'Behance',
            _controllers['behance']!,
          ),
          _buildEditableField(
            'dribbble',
            Icons.design_services,
            'Dribbble',
            _controllers['dribbble']!,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Job Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'jobType',
            Icons.business,
            'Job Type',
            _controllers['jobType']!,
          ),
          _buildEditableField(
            'preferredLocation',
            Icons.location_city,
            'Preferred Location',
            _controllers['preferredLocation']!,
          ),
          _buildEditableField(
            'workMode',
            Icons.work_outline,
            'Work Mode',
            _controllers['workMode']!,
          ),
          _buildEditableField(
            'salaryExpectation',
            Icons.attach_money,
            'Salary Expectation',
            _controllers['salaryExpectation']!,
          ),
          _buildEditableField(
            'noticePeriod',
            Icons.schedule,
            'Notice Period',
            _controllers['noticePeriod']!,
          ),
          _buildEditableField(
            'availability',
            Icons.event_available,
            'Availability',
            _controllers['availability']!,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6B5FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEditableField(
            'interests',
            Icons.favorite,
            'Interests',
            _controllers['interests']!,
            maxLines: 2,
          ),
          _buildEditableField(
            'achievements',
            Icons.emoji_events,
            'Achievements',
            _controllers['achievements']!,
            maxLines: 3,
          ),
          _buildEditableField(
            'publications',
            Icons.article,
            'Publications',
            _controllers['publications']!,
            maxLines: 2,
          ),
          _buildEditableField(
            'patents',
            Icons.description,
            'Patents',
            _controllers['patents']!,
            maxLines: 2,
          ),
          _buildEditableField(
            'awards',
            Icons.stars,
            'Awards',
            _controllers['awards']!,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing && enabled
                    ? TextFormField(
                        controller: controller,
                        enabled: enabled,
                        maxLines: maxLines,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        style: const TextStyle(
                          fontSize: 14,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          errorText: errorText,
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : const Color(0xFF6B5FFF),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not provided' : controller.text,
                        style: TextStyle(
                          fontSize: 14,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                displayValue,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      )
                    : Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 14,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing
                    ? DropdownButtonFormField<String>(
                        value: selectedValue,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B5FFF),
                              width: 2,
                            ),
                          ),
                        ),
                        items: [
                          if (allowCustom && currentValue.isNotEmpty && !options.contains(currentValue))
                            DropdownMenuItem(
                              value: currentValue,
                              child: Text(currentValue),
                            ),
                          ...options.map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
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
                          fontSize: 14,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing
                    ? TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: inputFormatters,
                        style: const TextStyle(
                          fontSize: 14,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          errorText: errorText,
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null ? Colors.red : const Color(0xFF6B5FFF),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty
                            ? 'Not specified'
                            : controller.text,
                        style: TextStyle(
                          fontSize: 14,
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
    final hasPhoto = profilePhoto != null && profilePhoto.toString().isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: const Color(0xFF6B5FFF),
          backgroundImage: hasPhoto
              ? NetworkImage(profilePhoto.toString())
              : null,
          child: !hasPhoto
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : _isUploadingPhoto
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6B5FFF), width: 2),
                ),
                child: _isUploadingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5FFF)),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Color(0xFF6B5FFF),
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
}
