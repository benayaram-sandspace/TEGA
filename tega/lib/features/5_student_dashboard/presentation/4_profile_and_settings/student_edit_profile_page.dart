import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../1_authentication/data/auth_repository.dart';
import '../../../../core/constants/api_constants.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Basic Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedGender = 'Male';

  // Academic Information
  final _instituteController = TextEditingController();
  final _courseController = TextEditingController();
  final _majorController = TextEditingController();
  final _yearOfStudyController = TextEditingController();

  // Address Information
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _zipcodeController = TextEditingController();

  // Professional Information
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();
  final _githubController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _dobController.dispose();
    _instituteController.dispose();
    _courseController.dispose();
    _majorController.dispose();
    _yearOfStudyController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _zipcodeController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _githubController.dispose();
    super.dispose();
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
            _populateFields();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateFields() {
    if (_profileData == null) return;

    _firstNameController.text = _profileData!['firstName'] ?? '';
    _lastNameController.text = _profileData!['lastName'] ?? '';
    _emailController.text = _profileData!['email'] ?? '';
    _phoneController.text =
        _profileData!['phone'] ?? _profileData!['contactNumber'] ?? '';
    _studentIdController.text = _profileData!['studentId'] ?? '';
    _dobController.text = _profileData!['dob'] != null
        ? DateTime.parse(
            _profileData!['dob'],
          ).toLocal().toString().split(' ')[0]
        : '';
    _selectedGender = _profileData!['gender'] ?? 'Male';

    _instituteController.text = _profileData!['institute'] ?? '';
    _courseController.text = _profileData!['course'] ?? '';
    _majorController.text = _profileData!['major'] ?? '';
    _yearOfStudyController.text =
        _profileData!['yearOfStudy']?.toString() ?? '';

    _addressController.text = _profileData!['address'] ?? '';
    _landmarkController.text = _profileData!['landmark'] ?? '';
    _cityController.text = _profileData!['city'] ?? '';
    _districtController.text = _profileData!['district'] ?? '';
    _zipcodeController.text = _profileData!['zipcode'] ?? '';

    _titleController.text = _profileData!['title'] ?? '';
    _summaryController.text = _profileData!['summary'] ?? '';
    _linkedinController.text = _profileData!['linkedin'] ?? '';
    _websiteController.text = _profileData!['website'] ?? '';
    _githubController.text = _profileData!['github'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final headers = _authService.getAuthHeaders();
      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'dob': _dobController.text.isNotEmpty ? _dobController.text : null,
        'gender': _selectedGender,
        'institute': _instituteController.text.trim(),
        'course': _courseController.text.trim(),
        'major': _majorController.text.trim(),
        'yearOfStudy': _yearOfStudyController.text.isNotEmpty
            ? int.tryParse(_yearOfStudyController.text)
            : null,
        'address': _addressController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'zipcode': _zipcodeController.text.trim(),
        'title': _titleController.text.trim(),
        'summary': _summaryController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'website': _websiteController.text.trim(),
        'github': _githubController.text.trim(),
      };

      final response = await http.put(
        Uri.parse(ApiEndpoints.studentProfile),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Section
              _buildProfilePhotoSection(),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              _buildTextField(
                controller: _firstNameController,
                label: "First Name",
                validator: (value) =>
                    value?.isEmpty == true ? 'First name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: "Last Name",
                validator: (value) =>
                    value?.isEmpty == true ? 'Last name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: "Email",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Email is required';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: "Phone Number",
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _studentIdController,
                label: "Student ID",
                readOnly: true,
                hintText: "Auto-generated",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _dobController,
                label: "Date of Birth",
                readOnly: true,
                onTap: () => _selectDate(context),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: "Gender",
                value: _selectedGender,
                items: ['Male', 'Female', 'Other'],
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 24),

              // Academic Information Section
              _buildSectionHeader('Academic Information'),
              _buildTextField(
                controller: _instituteController,
                label: "Institute/College",
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _courseController, label: "Course"),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _majorController,
                label: "Major/Stream",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _yearOfStudyController,
                label: "Year of Study",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              // Address Information Section
              _buildSectionHeader('Address Information'),
              _buildTextField(
                controller: _addressController,
                label: "Address",
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _landmarkController,
                label: "Landmark",
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: "City",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _districtController,
                      label: "District",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _zipcodeController,
                label: "ZIP Code",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              // Professional Information Section
              _buildSectionHeader('Professional Information'),
              _buildTextField(
                controller: _titleController,
                label: "Professional Title",
                hintText: "e.g., Software Developer, Data Scientist",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _summaryController,
                label: "Professional Summary",
                maxLines: 3,
                hintText: "Brief description of your professional background",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _linkedinController,
                label: "LinkedIn Profile",
                keyboardType: TextInputType.url,
                hintText: "https://linkedin.com/in/yourprofile",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _websiteController,
                label: "Personal Website",
                keyboardType: TextInputType.url,
                hintText: "https://yourwebsite.com",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _githubController,
                label: "GitHub Profile",
                keyboardType: TextInputType.url,
                hintText: "https://github.com/yourusername",
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profileData?['profilePhoto'] != null
                    ? NetworkImage(_profileData!['profilePhoto'])
                    : const NetworkImage(
                        'https://randomuser.me/api/portraits/men/32.jpg',
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // Handle profile picture change
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile photo upload coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5FFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile photo upload coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text("Change Photo"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B5FFF),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B5FFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B5FFF), width: 2),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateTime.parse(_dobController.text)
          : DateTime.now().subtract(
              const Duration(days: 365 * 20),
            ), // Default to 20 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dobController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }
}
