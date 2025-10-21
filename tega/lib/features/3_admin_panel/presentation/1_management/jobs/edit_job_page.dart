import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditJobPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const EditJobPage({super.key, required this.job});

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _salaryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _requirementsController;
  late final TextEditingController _benefitsController;
  late final TextEditingController _applicationLinkController;
  late final TextEditingController _experienceController;
  late final TextEditingController _deadlineController;

  // Form values
  late String _selectedJobType;
  late String _selectedPostingType;
  late String _selectedStatus;
  DateTime? _selectedDeadline;
  late bool _isActive;

  final List<String> _jobTypes = [
    'full-time',
    'part-time',
    'contract',
    'internship',
  ];
  final List<String> _postingTypes = ['job', 'internship'];
  final List<String> _statuses = ['open', 'active', 'closed', 'paused'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeValues();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.job['title'] ?? '');
    _companyController = TextEditingController(
      text: widget.job['company'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.job['location'] ?? '',
    );
    _salaryController = TextEditingController(
      text: widget.job['salary'] != null ? widget.job['salary'].toString() : '',
    );
    _descriptionController = TextEditingController(
      text: widget.job['description'] ?? '',
    );
    _requirementsController = TextEditingController(
      text: widget.job['requirements'] != null
          ? (widget.job['requirements'] as List).join('\n')
          : '',
    );
    _benefitsController = TextEditingController(
      text: widget.job['benefits'] != null
          ? (widget.job['benefits'] as List).join('\n')
          : '',
    );
    _applicationLinkController = TextEditingController(
      text: widget.job['applicationLink'] ?? '',
    );
    _experienceController = TextEditingController(
      text: widget.job['experience'] ?? '',
    );
    _deadlineController = TextEditingController();
  }

  void _initializeValues() {
    _selectedJobType = widget.job['jobType'] ?? 'full-time';
    _selectedPostingType = widget.job['postingType'] ?? 'job';
    _selectedStatus = widget.job['status'] ?? 'open';
    _isActive = widget.job['isActive'] ?? true;

    if (widget.job['deadline'] != null) {
      _selectedDeadline = DateTime.parse(widget.job['deadline']);
      _deadlineController.text = DateFormat.yMd().format(_selectedDeadline!);
    }
  }

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

  Future<void> _updateJob() async {
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

      final response = await http.put(
        Uri.parse(ApiEndpoints.adminUpdateJob(widget.job['_id'])),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(jobData),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Job updated successfully');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to update job');
        }
      } else {
        _showErrorSnackBar('Failed to update job (${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating job: $e');
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
        title: const Text('Edit Job'),
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
                      onPressed: _isLoading ? null : _updateJob,
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
                          : const Text('Update'),
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
    // Ensure the value exists in the items list, otherwise default to the first item
    final String? currentValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: currentValue,
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
      validator: (value) => value == null ? 'Please select an option' : null,
    );
  }
}
