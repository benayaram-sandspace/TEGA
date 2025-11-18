import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';

class AddCollegePage extends StatefulWidget {
  const AddCollegePage({super.key});

  @override
  State<AddCollegePage> createState() => _AddCollegePageState();
}

class _AddCollegePageState extends State<AddCollegePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final CollegeService _collegeService = CollegeService();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _collegeNameController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  String _selectedState = 'Andhra Pradesh';
  bool _isLoading = false;

  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Chandigarh',
    'Puducherry',
    'Andaman and Nicobar Islands',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Lakshadweep',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _collegeNameController.dispose();
    _collegeIdController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveCollege() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create new college
      final newCollege = College(
        id: _collegeIdController.text.trim(),
        name: _collegeNameController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState,
        address: _addressController.text.trim(),
        status: 'Active',
        totalStudents: 0,
        dailyActiveStudents: 0,
        avgSkillScore: 0.0,
        avgInterviewPractices: 0.0,
        primaryAdmin: PrimaryAdmin(
          name: _contactNameController.text.trim(),
          email: _contactEmailController.text.trim(),
          phone: _contactPhoneController.text.trim(),
        ),
        admins: [],
        students: [],
      );

      final success = await _collegeService.addCollege(newCollege);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newCollege.name} added successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('Failed to add college');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text(
          'Add New College',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFFA726),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                        label: 'College Name',
                        controller: _collegeNameController,
                        hintText: 'Andhra University College of Engineering',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter college name';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 200.ms),
                  const SizedBox(height: 16),
                  _buildFormField(
                        label: 'College ID / Code',
                        controller: _collegeIdController,
                        hintText: 'e.g., AUCEV',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter college ID';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 300.ms),
                  const SizedBox(height: 16),
                  _buildFormField(
                        label: 'Address',
                        controller: _addressController,
                        hintText: 'Enter complete address',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 400.ms),
                  const SizedBox(height: 16),
                  _buildFormField(
                        label: 'City',
                        controller: _cityController,
                        hintText: 'e.g., Visakhapatnam',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 500.ms),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                        label: 'State',
                        value: _selectedState,
                        items: _states,
                        onChanged: (value) {
                          setState(() {
                            _selectedState = value!;
                          });
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 600.ms),
                  const SizedBox(height: 24),
                  const Text(
                        'Primary Admin Contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 700.ms),
                  const SizedBox(height: 16),
                  _buildFormField(
                        label: 'Contact Name',
                        controller: _contactNameController,
                        hintText: 'e.g., Dr. S. Prasad',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contact name';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 800.ms),
                  const SizedBox(height: 16),
                  _buildFormField(
                        label: 'Contact Email',
                        controller: _contactEmailController,
                        hintText: 'e.g., admin@university.ac.in',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 900.ms),
                  const SizedBox(height: 16),
                  _buildFormField(
                        label: 'Contact Phone',
                        controller: _contactPhoneController,
                        hintText: 'e.g., +91 9876543210',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 1000.ms),
                  const SizedBox(height: 32),
                  Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.borderMedium,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveCollege,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA726),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Save & Send Invite',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.5, delay: 1100.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Color(0xFFFFA726)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
