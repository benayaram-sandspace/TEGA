import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/4_college_panel/data/repositories/college_repository.dart';

class AddCollegeAdminPage extends StatefulWidget {
  final College college;

  const AddCollegeAdminPage({super.key, required this.college});

  @override
  State<AddCollegeAdminPage> createState() => _AddCollegeAdminPageState();
}

class _AddCollegeAdminPageState extends State<AddCollegeAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final CollegeService _collegeService = CollegeService();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'College Admin';
  String _selectedStatus = 'Active';
  bool _isLoading = false;

  final List<String> _roles = [
    'College Admin',
    'Assistant Admin',
    'Content Manager',
    'Student Coordinator',
  ];

  final List<String> _statuses = ['Active', 'Inactive'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create new admin
      final newAdmin = CollegeAdmin(
        id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        status: _selectedStatus,
        role: _selectedRole,
      );

      final success = await _collegeService.addAdminToCollege(
        widget.college.id,
        newAdmin,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newAdmin.name} added successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('Failed to add admin');
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
      backgroundColor: AdminDashboardStyles.background,
      appBar: AppBar(
        title: const Text(
          'Add College Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AdminDashboardStyles.primary,
        elevation: 8,
        shadowColor: AdminDashboardStyles.primary.withValues(alpha: 0.3),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminDashboardStyles.primary,
                AdminDashboardStyles.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // College Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AdminDashboardStyles.getCardDecoration(
                  borderColor: AdminDashboardStyles.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminDashboardStyles.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: AdminDashboardStyles.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Adding admin for:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AdminDashboardStyles.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.college.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AdminDashboardStyles.textDark,
                                ),
                              ),
                              Text(
                                '${widget.college.city}, ${widget.college.state}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AdminDashboardStyles.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3),
              const SizedBox(height: 24),

              // Admin Name
              _buildFormField(
                label: 'Admin Name',
                controller: _nameController,
                hintText: 'Enter admin full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter admin name';
                  }
                  return null;
                },
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, delay: 200.ms),
              const SizedBox(height: 20),

              // Email
              _buildFormField(
                label: 'Email Address',
                controller: _emailController,
                hintText: 'admin@college.edu',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter valid email';
                  }
                  return null;
                },
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, delay: 300.ms),
              const SizedBox(height: 20),

              // Phone
              _buildFormField(
                label: 'Phone Number',
                controller: _phoneController,
                hintText: '+91 9876543210',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, delay: 400.ms),
              const SizedBox(height: 20),

              // Role Dropdown
              _buildDropdownField(
                label: 'Role',
                value: _selectedRole,
                items: _roles,
                icon: Icons.admin_panel_settings_outlined,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, delay: 500.ms),
              const SizedBox(height: 20),

              // Status Dropdown
              _buildDropdownField(
                label: 'Status',
                value: _selectedStatus,
                items: _statuses,
                icon: Icons.toggle_on_outlined,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, delay: 600.ms),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: AdminDashboardStyles.getSecondaryButtonStyle(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAdmin,
                      style: AdminDashboardStyles.getPrimaryButtonStyle(),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Add Admin',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ).animate().fade(duration: 500.ms).slideY(begin: 0.3, delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
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
            color: AdminDashboardStyles.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: AdminDashboardStyles.getCardDecoration(),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AdminDashboardStyles.textLight),
              prefixIcon: Icon(
                icon,
                color: AdminDashboardStyles.primary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AdminDashboardStyles.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AdminDashboardStyles.statusError,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
    required IconData icon,
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
            color: AdminDashboardStyles.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: AdminDashboardStyles.getCardDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: onChanged,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AdminDashboardStyles.primary,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: AdminDashboardStyles.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item,
                        style: const TextStyle(
                          color: AdminDashboardStyles.textDark,
                        ),
                      ),
                    ],
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