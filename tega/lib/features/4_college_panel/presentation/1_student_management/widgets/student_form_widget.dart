import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/features/4_college_panel/data/models/college_student_model.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/1_student_management/widgets/form_field_widget.dart';

class StudentForm extends StatefulWidget {
  final Function(Student) onSubmit;
  final bool isLoading;

  const StudentForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  // Dropdown values
  String? _selectedCourse;
  String? _selectedBatch;
  String? _selectedDepartment;
  String? _selectedGender;
  DateTime? _selectedDate;

  // Sample data - Replace with actual data from backend
  final List<String> _courses = [
    'B.Tech',
    'M.Tech',
    'MBA',
    'MCA',
    'B.Sc',
    'M.Sc',
  ];
  final List<String> _batches = [
    '2024-2028',
    '2023-2027',
    '2022-2026',
    '2021-2025',
  ];
  final List<String> _departments = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _addressController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // ~18 years ago
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: DashboardStyles.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select date of birth'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final student = Student(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        studentId: _studentIdController.text,
        course: _selectedCourse!,
        batch: _selectedBatch!,
        department: _selectedDepartment!,
        dateOfBirth: _selectedDate!,
        gender: _selectedGender!,
        address: _addressController.text,
        guardianName: _guardianNameController.text,
        guardianPhone: _guardianPhoneController.text,
        enrollmentDate: DateTime.now(),
      );

      widget.onSubmit(student);
      _resetForm();
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _studentIdController.clear();
    _addressController.clear();
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    setState(() {
      _selectedCourse = null;
      _selectedBatch = null;
      _selectedDepartment = null;
      _selectedGender = null;
      _selectedDate = null;
    });
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required int index,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.2,
                (index * 0.2) + 0.4,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: Colors.grey[600])
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DashboardStyles.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildSectionCard(
            title: 'Personal Information',
            icon: Icons.person_rounded,
            color: DashboardStyles.primary,
            index: 0,
            children: [
              if (isSmallScreen) ...[
                // Stack fields vertically on small screens
                FormFieldWidget(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Enter first name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter last name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: FormFieldWidget(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'Enter first name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormFieldWidget(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Enter last name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (isSmallScreen) ...[
                FormFieldWidget(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'student@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+91 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (value!.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: FormFieldWidget(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'student@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (!value!.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormFieldWidget(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+91 9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (value!.length != 10) return 'Must be 10 digits';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (isSmallScreen) ...[
                // Date of Birth
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null
                                  ? 'Select date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.grey[400]
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Gender',
                  hint: 'Select gender',
                  value: _selectedGender,
                  items: _genders,
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) => value == null ? 'Required' : null,
                  prefixIcon: Icons.wc_outlined,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Select date'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: TextStyle(
                                        color: _selectedDate == null
                                            ? Colors.grey[400]
                                            : Colors.black87,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Gender',
                        hint: 'Select gender',
                        value: _selectedGender,
                        items: _genders,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                        validator: (value) => value == null ? 'Required' : null,
                        prefixIcon: Icons.wc_outlined,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Academic Information Section
          _buildSectionCard(
            title: 'Academic Information',
            icon: Icons.school_rounded,
            color: Colors.orange,
            index: 1,
            children: [
              FormFieldWidget(
                controller: _studentIdController,
                label: 'Student ID',
                hint: 'Enter unique student ID',
                prefixIcon: Icons.badge_outlined,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (isSmallScreen) ...[
                _buildDropdownField(
                  label: 'Course',
                  hint: 'Select course',
                  value: _selectedCourse,
                  items: _courses,
                  onChanged: (value) => setState(() => _selectedCourse = value),
                  validator: (value) => value == null ? 'Required' : null,
                  prefixIcon: Icons.menu_book_outlined,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Batch',
                  hint: 'Select batch',
                  value: _selectedBatch,
                  items: _batches,
                  onChanged: (value) => setState(() => _selectedBatch = value),
                  validator: (value) => value == null ? 'Required' : null,
                  prefixIcon: Icons.group_outlined,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Course',
                        hint: 'Select course',
                        value: _selectedCourse,
                        items: _courses,
                        onChanged: (value) =>
                            setState(() => _selectedCourse = value),
                        validator: (value) => value == null ? 'Required' : null,
                        prefixIcon: Icons.menu_book_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Batch',
                        hint: 'Select batch',
                        value: _selectedBatch,
                        items: _batches,
                        onChanged: (value) =>
                            setState(() => _selectedBatch = value),
                        validator: (value) => value == null ? 'Required' : null,
                        prefixIcon: Icons.group_outlined,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Department',
                hint: 'Select department',
                value: _selectedDepartment,
                items: _departments,
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value),
                validator: (value) => value == null ? 'Required' : null,
                prefixIcon: Icons.business_outlined,
              ),
            ],
          ),

          // Guardian Information Section
          _buildSectionCard(
            title: 'Guardian Information',
            icon: Icons.family_restroom_rounded,
            color: Colors.purple,
            index: 2,
            children: [
              if (isSmallScreen) ...[
                FormFieldWidget(
                  controller: _guardianNameController,
                  label: 'Guardian Name',
                  hint: 'Enter guardian name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _guardianPhoneController,
                  label: 'Guardian Phone',
                  hint: '+91 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (value!.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: FormFieldWidget(
                        controller: _guardianNameController,
                        label: 'Guardian Name',
                        hint: 'Enter guardian name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormFieldWidget(
                        controller: _guardianPhoneController,
                        label: 'Guardian Phone',
                        hint: '+91 9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (value!.length != 10) return 'Must be 10 digits';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              FormFieldWidget(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter complete address',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),

          // Action Buttons with animation
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                  ),
                ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.isLoading ? null : _resetForm,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        isSmallScreen ? 'Reset' : 'Reset Form',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DashboardStyles.primary,
                            DashboardStyles.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: DashboardStyles.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: widget.isLoading ? null : _submitForm,
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text(
                          'Add Student',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
