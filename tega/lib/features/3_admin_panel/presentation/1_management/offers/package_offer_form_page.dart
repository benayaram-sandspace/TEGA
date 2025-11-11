import 'package:flutter/material.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/repositories/offer_repository.dart';

class PackageOfferFormPage extends StatefulWidget {
  final Map<String, dynamic>? packageOffer;
  final bool isEdit;

  const PackageOfferFormPage({
    super.key,
    this.packageOffer,
    this.isEdit = false,
  });

  @override
  State<PackageOfferFormPage> createState() => _PackageOfferFormPageState();
}

class _PackageOfferFormPageState extends State<PackageOfferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _offerRepository = OfferRepository();

  // Form controllers
  final _packageNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Form state
  String? _selectedInstitute;
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  // Available options
  List<Map<String, dynamic>> _availableCourses = [];
  List<Map<String, dynamic>> _availableTegaExams = [];
  List<String> _availableInstitutes = [];

  // Selected items
  List<Map<String, dynamic>> _selectedCourses = [];
  String? _selectedTegaExamId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.packageOffer != null) {
      _populateFormFromPackageOffer();
    }
    _loadAvailableOptions();
  }

  void _populateFormFromPackageOffer() {
    final package = widget.packageOffer!;
    _packageNameController.text = package['packageName'] ?? '';
    _descriptionController.text = package['description'] ?? '';
    _priceController.text = (package['price'] ?? 0).toString();
    _selectedInstitute = package['instituteName'];
    
    if (package['validUntil'] != null) {
      _validUntil = DateTime.parse(package['validUntil']);
    }
    
    if (package['includedCourses'] != null) {
      _selectedCourses = List<Map<String, dynamic>>.from(
        package['includedCourses'].map((course) => {
          'courseId': course['courseId'] ?? course['_id'],
          'courseName': course['courseName'] ?? course['title'] ?? 'Unknown',
        }),
      );
    }
    
    _selectedTegaExamId = package['includedExam'];
  }

  Future<void> _loadAvailableOptions() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _offerRepository.getAvailableCourses(),
        _offerRepository.getAvailableTegaExams(),
        _offerRepository.getAvailableInstitutes(),
      ]);

      // Deduplicate courses by ID
      final coursesList = List<Map<String, dynamic>>.from(results[0]);
      final seenCourseIds = <String>{};
      final deduplicatedCourses = <Map<String, dynamic>>[];
      for (final course in coursesList) {
        final courseId = course['_id']?.toString() ?? course['id']?.toString();
        if (courseId != null && !seenCourseIds.contains(courseId)) {
          seenCourseIds.add(courseId);
          deduplicatedCourses.add(course);
        }
      }

      setState(() {
        _availableCourses = deduplicatedCourses;
        _availableTegaExams = List<Map<String, dynamic>>.from(results[1]);
        _availableInstitutes = List<String>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load options: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPackageNameField(),
                            const SizedBox(height: 16),
                            _buildInstituteField(),
                            const SizedBox(height: 16),
                            _buildDescriptionField(),
                            const SizedBox(height: 16),
                            _buildCoursesSection(),
                            const SizedBox(height: 16),
                            _buildTegaExamField(),
                            const SizedBox(height: 16),
                            _buildPriceField(),
                            const SizedBox(height: 16),
                            _buildValidUntilField(),
                            const SizedBox(height: 32),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.isEdit ? 'Edit Package Offer' : 'Create Package Offer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildPackageNameField() {
    return TextFormField(
      controller: _packageNameController,
      decoration: InputDecoration(
        labelText: 'Package Name *',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
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
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter package name';
        }
        return null;
      },
    );
  }

  Widget _buildInstituteField() {
    return DropdownButtonFormField<String>(
      value: _selectedInstitute,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Institute Name *',
        hintText: 'Select Institute',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
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
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: _availableInstitutes.map((institute) {
        return DropdownMenuItem<String>(
          value: institute,
          child: Text(
            institute,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedInstitute = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an institute';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Package description...',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: Colors.grey[400]),
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
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Courses *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '(Add courses one by one)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          key: ValueKey('course_dropdown_${_selectedCourses.length}'),
          builder: (context) {
            // Get available courses (not already selected)
            final selectedIds = _selectedCourses
                .map((s) => s['courseId']?.toString() ?? s['_id']?.toString())
                .where((id) => id != null)
                .cast<String>()
                .toSet();

            // Filter and deduplicate in one pass
            final seenIds = <String>{};
            final items = <DropdownMenuItem<String>>[];
            
            for (final course in _availableCourses) {
              final courseId = course['_id']?.toString() ?? course['id']?.toString();
              if (courseId != null && 
                  !seenIds.contains(courseId) && 
                  !selectedIds.contains(courseId)) {
                seenIds.add(courseId);
                items.add(
                  DropdownMenuItem<String>(
                    value: courseId,
                    child: Text(
                      course['title'] ?? course['courseName'] ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }
            }

            return DropdownButtonFormField<String>(
              value: null,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select a course to add...',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: items,
              onChanged: (value) {
                if (value != null) {
                  final course = _availableCourses.firstWhere(
                    (c) {
                      final id = c['_id']?.toString() ?? c['id']?.toString();
                      return id == value;
                    },
                    orElse: () => <String, dynamic>{},
                  );
                  
                  if (course.isNotEmpty) {
                    setState(() {
                      _selectedCourses.add({
                        'courseId': value,
                        'courseName': course['title'] ?? course['courseName'] ?? 'Unknown',
                      });
                    });
                  }
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedCourses.isEmpty
              ? Center(
                  child: Text(
                    'No courses selected. Please select at least one course.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._selectedCourses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final course = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                course['courseName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: AppColors.error,
                              onPressed: () {
                                setState(() {
                                  _selectedCourses.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
        if (_selectedCourses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one course',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTegaExamField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TEGA Exam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedTegaExamId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'No Exam',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No Exam'),
            ),
            ..._availableTegaExams.map((exam) {
              return DropdownMenuItem<String>(
                value: exam['_id']?.toString() ?? exam['id']?.toString(),
                child: Text(
                  exam['title'] ?? exam['examTitle'] ?? 'Unknown',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTegaExamId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Package Price (₹) *',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
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
          borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        prefixText: '₹ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter package price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      },
    );
  }

  Widget _buildValidUntilField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valid Until Date *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'dd-mm-yyyy',
              hintStyle: TextStyle(color: Colors.grey[400]),
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
                borderSide: const BorderSide(color: AppColors.warmOrange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            child: Text(
              '${_validUntil.day.toString().padLeft(2, '0')}-${_validUntil.month.toString().padLeft(2, '0')}-${_validUntil.year}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the expiry date for this package',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
    );

    if (picked != null && picked != _validUntil) {
      setState(() {
        _validUntil = picked;
      });
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createPackageOffer,
          icon: Icon(
            widget.isEdit ? Icons.save_outlined : Icons.inventory_2_outlined,
            size: 20,
          ),
          label: Text(widget.isEdit ? 'Update Package' : 'Create Package'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createPackageOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one course'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final packageData = {
        'packageName': _packageNameController.text,
        'instituteName': _selectedInstitute,
        'description': _descriptionController.text,
        'includedCourses': _selectedCourses,
        'price': double.parse(_priceController.text),
        'validUntil': _validUntil.toIso8601String(),
        if (_selectedTegaExamId != null)
          'includedExam': {
            'examId': _selectedTegaExamId,
            'examTitle': _availableTegaExams
                .firstWhere(
                  (e) =>
                      (e['_id']?.toString() ?? e['id']?.toString()) ==
                      _selectedTegaExamId,
                )['title'] ??
                'Unknown',
          },
      };

      if (widget.isEdit && widget.packageOffer != null) {
        final packageId = widget.packageOffer!['_id'] ?? widget.packageOffer!['packageId'];
        await _offerRepository.updatePackageOffer(packageId.toString(), packageData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package offer updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        await _offerRepository.createPackageOffer(packageData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package offer created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create package offer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

