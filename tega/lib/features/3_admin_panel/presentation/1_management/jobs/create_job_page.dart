import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _applicationLinkController = TextEditingController();
  final _experienceController = TextEditingController();
  final _deadlineController = TextEditingController();

  // Form values
  String _selectedJobType = 'full-time';
  String _selectedPostingType = 'job';
  String _selectedStatus = 'open';
  DateTime? _selectedDeadline;
  bool _isActive = true;

  final List<String> _jobTypes = [
    'full-time',
    'part-time',
    'contract',
    'internship',
  ];
  final List<String> _postingTypes = ['job', 'internship'];
  final List<String> _statuses = ['open', 'active', 'closed', 'paused'];

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _applicationLinkController.dispose();
    _experienceController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final headers = _authService.getAuthHeaders();
      final jobData = {
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'jobType': _selectedJobType,
        'postingType': _selectedPostingType,
        'status': _selectedStatus,
        'isActive': _isActive,
        if (_salaryController.text.isNotEmpty)
          'salary': int.tryParse(_salaryController.text) ?? 0,
        if (_selectedDeadline != null)
          'deadline': _selectedDeadline!.toIso8601String(),
        if (_requirementsController.text.isNotEmpty)
          'requirements': _requirementsController.text
              .split('\n')
              .where((req) => req.trim().isNotEmpty)
              .toList(),
        if (_benefitsController.text.isNotEmpty)
          'benefits': _benefitsController.text
              .split('\n')
              .where((benefit) => benefit.trim().isNotEmpty)
              .toList(),
        if (_applicationLinkController.text.isNotEmpty)
          'applicationLink': _applicationLinkController.text.trim(),
        if (_experienceController.text.isNotEmpty)
          'experience': _experienceController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.adminCreateJob),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(jobData),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Job created successfully');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to create job');
        }
      } else {
        _showErrorSnackBar('Failed to create job (${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating job: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDeadline = date;
        _deadlineController.text = DateFormat.yMd().format(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Create Job'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
              _buildCard('Basic Information', [
                _buildTextField(
                  controller: _titleController,
                  label: 'Job Title',
                  hint: 'e.g., Software Engineer',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Job title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyController,
                  label: 'Company',
                  hint: 'e.g., Tech Corp',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'e.g., Mumbai, India',
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Job Type',
                  value: _selectedJobType,
                  items: _jobTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedJobType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Posting Type',
                  value: _selectedPostingType,
                  items: _postingTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedPostingType = value!;
                    });
                  },
                ),
              ]),
              const SizedBox(height: 16),
              // Job Details Card
              _buildCard('Job Details', [
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe the role and responsibilities...',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Job description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _experienceController,
                  label: 'Experience Required',
                  hint: 'e.g., 2-3 years',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _salaryController,
                  label: 'Salary (₹)',
                  hint: 'e.g., 500000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _applicationLinkController,
                  label: 'Application Link',
                  hint: 'https://company.com/apply',
                ),
              ]),
              const SizedBox(height: 16),
              // Requirements & Benefits Card
              _buildCard('Requirements & Benefits', [
                _buildTextField(
                  controller: _requirementsController,
                  label: 'Requirements (one per line)',
                  hint:
                      'Bachelor\'s degree in Computer Science\n2+ years of experience\n...',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _benefitsController,
                  label: 'Benefits (one per line)',
                  hint: 'Health insurance\nFlexible working hours\n...',
                  maxLines: 4,
                ),
              ]),
              const SizedBox(height: 16),
              // Status & Settings Card
              _buildCard('Status & Settings', [
                _buildDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: _statuses,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _deadlineController,
                  label: 'Deadline',
                  hint: 'Select a date',
                  readOnly: true,
                  onTap: _selectDeadline,
                  suffixIcon: Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Job will be visible to students'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: const Color(0xFF6B5FFF),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
              const SizedBox(height: 32),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5FFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
                          : const Text('Create Job'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
        border: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        enabledBorder: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        focusedBorder: _buildOutlineBorder(const Color(0xFF6B5FFF)),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        enabledBorder: _buildOutlineBorder(const Color(0xFFE2E8F0)),
        focusedBorder: _buildOutlineBorder(const Color(0xFF6B5FFF)),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item.toUpperCase()),
        );
      }).toList(),
    );
  }
}
