import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tega/features/3_admin_panel/data/services/admin_dashboard_service.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class EditCoursePage extends StatefulWidget {
  final Map<String, dynamic> course;

  const EditCoursePage({super.key, required this.course});

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final AdminDashboardService _dashboardService = AdminDashboardService();

  // Form controllers
  late final TextEditingController _courseNameController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _fullDescriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _durationController;
  late final TextEditingController _instructorController;
  late final TextEditingController _instructorBioController;
  late final TextEditingController _tagsController;
  late final TextEditingController _thumbnailUrlController;
  late final TextEditingController _bannerUrlController;
  late final TextEditingController _previewVideoUrlController;
  late final TextEditingController _instructorAvatarUrlController;

  String? _selectedCategory;
  String? _selectedLevel;
  String? _selectedStatus;
  bool _isFreeCourse = false;
  bool _isLoading = false;

  // Course modules
  List<Map<String, dynamic>> _modules = [];

  final List<String> _categories = [
    'Programming',
    'Web Development',
    'Mobile Development',
    'Data Science',
    'Machine Learning',
    'DevOps',
    'Cloud Computing',
    'Cybersecurity',
    'UI/UX Design',
    'Other',
  ];

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _statuses = ['Draft', 'Published'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _courseNameController = TextEditingController(
      text: widget.course['title'] ?? '',
    );
    _shortDescriptionController = TextEditingController(
      text:
          widget.course['shortDescription'] ??
          widget.course['description'] ??
          '',
    );
    _fullDescriptionController = TextEditingController(
      text:
          widget.course['fullDescription'] ??
          widget.course['description'] ??
          '',
    );
    _priceController = TextEditingController(
      text: widget.course['price']?.toString() ?? '',
    );
    _originalPriceController = TextEditingController(
      text: widget.course['originalPrice']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.course['estimatedDuration']?['hours']?.toString() ?? '',
    );
    _instructorController = TextEditingController(
      text: widget.course['instructor']?['name'] ?? '',
    );
    _instructorBioController = TextEditingController(
      text: widget.course['instructor']?['bio'] ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.course['tags']?.join(', ') ?? '',
    );
    _thumbnailUrlController = TextEditingController(
      text: widget.course['thumbnail'] ?? '',
    );
    _bannerUrlController = TextEditingController(
      text: widget.course['banner'] ?? '',
    );
    _previewVideoUrlController = TextEditingController(
      text: widget.course['previewVideo'] ?? '',
    );
    _instructorAvatarUrlController = TextEditingController(
      text: widget.course['instructor']?['avatar'] ?? '',
    );

    _selectedCategory = widget.course['category'];
    _selectedLevel = widget.course['level'];
    _selectedStatus = widget.course['status'] ?? 'Published';
    _isFreeCourse = widget.course['isFree'] ?? false;

    // Ensure selected values are valid
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }
    if (_selectedLevel != null && !_levels.contains(_selectedLevel)) {
      _selectedLevel = 'Beginner';
    }
    if (_selectedStatus != null && !_statuses.contains(_selectedStatus)) {
      _selectedStatus = 'Published';
    }

    // Initialize modules
    _initializeModules();
  }

  void _initializeModules() {
    if (widget.course['modules'] != null && widget.course['modules'] is List) {
      final modulesList = widget.course['modules'] as List;
      _modules = modulesList
          .map((module) => module as Map<String, dynamic>)
          .toList();
    } else {
      _modules = [];
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _shortDescriptionController.dispose();
    _fullDescriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _durationController.dispose();
    _instructorController.dispose();
    _instructorBioController.dispose();
    _tagsController.dispose();
    _thumbnailUrlController.dispose();
    _bannerUrlController.dispose();
    _previewVideoUrlController.dispose();
    _instructorAvatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final courseData = {
        'title': _courseNameController.text.trim(),
        'shortDescription': _shortDescriptionController.text.trim(),
        'fullDescription': _fullDescriptionController.text.trim(),
        'price': _priceController.text.trim().isNotEmpty
            ? double.parse(_priceController.text.trim())
            : 0,
        'originalPrice': _originalPriceController.text.trim().isNotEmpty
            ? double.parse(_originalPriceController.text.trim())
            : null,
        'duration': _durationController.text.trim().isNotEmpty
            ? int.parse(_durationController.text.trim())
            : 0,
        'category': _selectedCategory,
        'level': _selectedLevel,
        'status': _selectedStatus,
        'isFree': _isFreeCourse,
        'tags': _tagsController.text
            .trim()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'thumbnail': _thumbnailUrlController.text.trim(),
        'banner': _bannerUrlController.text.trim(),
        'previewVideo': _previewVideoUrlController.text.trim(),
        'instructor': {
          'name': _instructorController.text.trim(),
          'bio': _instructorBioController.text.trim(),
          'avatar': _instructorAvatarUrlController.text.trim(),
        },
        'modules': _modules,
      };

      await _dashboardService.updateCourse(
        widget.course['_id'] ?? widget.course['id'],
        courseData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update course: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF475569),
                size: 18,
              ),
            ),
          ),
        ),
        title: const Text(
          'Edit Course',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 768;
            final isDesktop = constraints.maxWidth > 1024;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isDesktop
                    ? 48
                    : isTablet
                    ? 32
                    : 24,
                24,
                isDesktop
                    ? 48
                    : isTablet
                    ? 32
                    : 24,
                100,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop
                        ? 800
                        : isTablet
                        ? 600
                        : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Column(
      children: [
        // Course Basic Information
        _buildSectionCard(
          title: 'Course Information',
          children: [
            _buildField(
              controller: _courseNameController,
              label: 'Course Title *',
              icon: Icons.school_rounded,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Course title is required';
                }
                if (value.trim().length < 3) {
                  return 'Course title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _shortDescriptionController,
              label: 'Short Description *',
              icon: Icons.description_rounded,
              isRequired: true,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Short description is required';
                }
                if (value.trim().length < 10) {
                  return 'Short description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _fullDescriptionController,
              label: 'Full Description *',
              icon: Icons.article_rounded,
              isRequired: true,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full description is required';
                }
                if (value.trim().length < 20) {
                  return 'Full description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                if (isSmallScreen) {
                  return Column(
                    children: [
                      _buildField(
                        controller: _priceController,
                        label: 'Price (INR)',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final price = double.tryParse(value.trim());
                            if (price == null || price < 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _originalPriceController,
                        label: 'Original Price (INR)',
                        icon: Icons.price_check_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final price = double.tryParse(value.trim());
                            if (price == null || price < 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceController,
                        label: 'Price (INR)',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final price = double.tryParse(value.trim());
                            if (price == null || price < 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        controller: _originalPriceController,
                        label: 'Original Price (INR)',
                        icon: Icons.price_check_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final price = double.tryParse(value.trim());
                            if (price == null || price < 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                if (isSmallScreen) {
                  return Column(
                    children: [
                      _buildDropdown(
                        value: _selectedCategory,
                        label: 'Category',
                        icon: Icons.category_rounded,
                        items: _categories,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        value: _selectedLevel,
                        label: 'Level',
                        icon: Icons.trending_up_rounded,
                        items: _levels,
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value;
                          });
                        },
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedCategory,
                        label: 'Category',
                        icon: Icons.category_rounded,
                        items: _categories,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedLevel,
                        label: 'Level',
                        icon: Icons.trending_up_rounded,
                        items: _levels,
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _tagsController,
              label: 'Tags (comma-separated)',
              icon: Icons.tag_rounded,
              hintText: 'React, JavaScript, Frontend',
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                if (isSmallScreen) {
                  return Column(
                    children: [
                      _buildDropdown(
                        value: _selectedStatus,
                        label: 'Status',
                        icon: Icons.publish_rounded,
                        items: _statuses,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _durationController,
                        label: 'Duration (hours)',
                        icon: Icons.access_time_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final duration = int.tryParse(value.trim());
                            if (duration == null || duration <= 0) {
                              return 'Please enter a valid duration';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedStatus,
                        label: 'Status',
                        icon: Icons.publish_rounded,
                        items: _statuses,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        controller: _durationController,
                        label: 'Duration (hours)',
                        icon: Icons.access_time_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final duration = int.tryParse(value.trim());
                            if (duration == null || duration <= 0) {
                              return 'Please enter a valid duration';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _buildCheckbox(
              value: _isFreeCourse,
              label: 'Free Course',
              onChanged: (value) {
                setState(() {
                  _isFreeCourse = value ?? false;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Course Media
        _buildSectionCard(
          title: 'Course Media',
          children: [
            _buildField(
              controller: _thumbnailUrlController,
              label: 'Thumbnail URL',
              icon: Icons.image_rounded,
              hintText: 'URL to course thumbnail image',
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _bannerUrlController,
              label: 'Banner URL',
              icon: Icons.photo_library_rounded,
              hintText: 'URL to course banner image',
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _previewVideoUrlController,
              label: 'Preview Video URL',
              icon: Icons.video_library_rounded,
              hintText: 'URL to course preview video',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Instructor Information
        _buildSectionCard(
          title: 'Instructor Information',
          children: [
            _buildField(
              controller: _instructorController,
              label: 'Instructor Name',
              icon: Icons.person_rounded,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Instructor name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _instructorAvatarUrlController,
              label: 'Avatar URL',
              icon: Icons.account_circle_rounded,
              hintText: 'Enter a URL to an image (not base64 data)',
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _instructorBioController,
              label: 'Instructor Bio',
              icon: Icons.info_rounded,
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Course Modules
        _buildSectionCard(
          title: 'Course Modules',
          children: [_buildModulesSection()],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminDashboardStyles.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSectionIcon(title),
                    color: AdminDashboardStyles.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Course Information':
        return Icons.info_outline_rounded;
      case 'Course Media':
        return Icons.perm_media_outlined;
      case 'Instructor Information':
        return Icons.person_outline_rounded;
      case 'Course Modules':
        return Icons.library_books_outlined;
      default:
        return Icons.settings_outlined;
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
              letterSpacing: -0.1,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 15,
                color: const Color(0xFF64748B).withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AdminDashboardStyles.primary,
                  size: 18,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AdminDashboardStyles.primary,
                  size: 18,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: Colors.white,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required String label,
    required void Function(bool?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? AdminDashboardStyles.primary.withOpacity(0.05)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AdminDashboardStyles.primary.withOpacity(0.2)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AdminDashboardStyles.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value
                    ? AdminDashboardStyles.primary
                    : const Color(0xFFCBD5E1),
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: value
                    ? AdminDashboardStyles.primary
                    : const Color(0xFF475569),
                letterSpacing: -0.1,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                value ? Icons.check_circle : Icons.radio_button_unchecked,
                color: value
                    ? AdminDashboardStyles.primary
                    : const Color(0xFFCBD5E1),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: isSmallScreen
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AdminDashboardStyles.primary,
                            AdminDashboardStyles.primary.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.25,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.1,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _updateCourse,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.save_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Update Course',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  color: const Color(0xFF64748B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    color: const Color(0xFF64748B),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AdminDashboardStyles.primary,
                              AdminDashboardStyles.primary.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AdminDashboardStyles.primary.withOpacity(
                                0.25,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: AdminDashboardStyles.primary.withOpacity(
                                0.1,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _updateCourse,
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.save_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Update Course',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildModulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Module Button
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AdminDashboardStyles.primary,
                AdminDashboardStyles.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AdminDashboardStyles.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _addModule,
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Module',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Modules List
        if (_modules.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No modules added yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click "Add Module" to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ..._modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            return _buildModuleCard(index, module);
          }).toList(),

        const SizedBox(height: 20),

        // Course Content Summary
        _buildContentSummary(),
      ],
    );
  }

  Widget _buildModuleCard(int index, Map<String, dynamic> module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Module Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: AdminDashboardStyles.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module['title'] ?? 'Untitled Module',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteModule(index),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Module Content
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module Title Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextFormField(
                    initialValue: module['title'] ?? '',
                    decoration: const InputDecoration(
                      hintText: 'Module title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: (value) {
                      _modules[index]['title'] = value;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Add Video Button
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminDashboardStyles.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AdminDashboardStyles.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _addVideoToModule(index),
                      borderRadius: BorderRadius.circular(8),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_call_rounded,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Add Video',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Videos List
                if (module['videos'] != null &&
                    (module['videos'] as List).isNotEmpty)
                  ...(module['videos'] as List).asMap().entries.map((
                    videoEntry,
                  ) {
                    final videoIndex = videoEntry.key;
                    final video = videoEntry.value;
                    return _buildVideoItem(index, videoIndex, video);
                  }).toList(),

                // Empty state for videos
                if (module['videos'] == null ||
                    (module['videos'] as List).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: const Center(
                      child: Text(
                        'No videos added yet',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSummary() {
    int totalLectures = 0;
    int totalVideos = 0;
    int totalMaterials = 0;

    for (var module in _modules) {
      // Count lectures
      if (module['lectures'] != null) {
        totalLectures += (module['lectures'] as List).length;
        for (var lecture in module['lectures']) {
          if (lecture['type'] == 'video') {
            totalVideos++;
          } else if (lecture['type'] == 'assignment') {
            totalMaterials++;
          }
        }
      }

      // Count videos from the new videos array
      if (module['videos'] != null) {
        totalVideos += (module['videos'] as List).length;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Content Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Modules', '${_modules.length}'),
              ),
              Expanded(child: _buildSummaryItem('Lectures', '$totalLectures')),
              Expanded(child: _buildSummaryItem('Videos', '$totalVideos')),
              Expanded(
                child: _buildSummaryItem('Materials', '$totalMaterials'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _addModule() {
    setState(() {
      _modules.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'New Module',
        'description': '',
        'order': _modules.length + 1,
        'isUnlocked': true,
        'unlockCondition': 'immediate',
        'lectures': [],
        'videos': [],
      });
    });
  }

  void _deleteModule(int index) {
    setState(() {
      _modules.removeAt(index);
    });
  }

  void _addVideoToModule(int moduleIndex) {
    setState(() {
      if (_modules[moduleIndex]['videos'] == null) {
        _modules[moduleIndex]['videos'] = [];
      }
      (_modules[moduleIndex]['videos'] as List).add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'New Video',
        'url': '',
        'duration': 0,
        'order': (_modules[moduleIndex]['videos'] as List).length + 1,
        'isPreview': false,
      });
    });
  }

  void _deleteVideoFromModule(int moduleIndex, int videoIndex) {
    setState(() {
      (_modules[moduleIndex]['videos'] as List).removeAt(videoIndex);
    });
  }

  Widget _buildVideoItem(
    int moduleIndex,
    int videoIndex,
    Map<String, dynamic> video,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: AdminDashboardStyles.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: video['title'] ?? '',
                  decoration: const InputDecoration(
                    hintText: 'Video title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    (_modules[moduleIndex]['videos']
                            as List)[videoIndex]['title'] =
                        value;
                  },
                ),
              ),
              IconButton(
                onPressed: () =>
                    _deleteVideoFromModule(moduleIndex, videoIndex),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 16,
                ),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: video['url'] ?? '',
            decoration: const InputDecoration(
              hintText: 'Video URL (YouTube, Vimeo, or direct video link)',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            onChanged: (value) {
              (_modules[moduleIndex]['videos'] as List)[videoIndex]['url'] =
                  value;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: video['duration']?.toString() ?? '',
                  decoration: const InputDecoration(
                    hintText: 'Duration (minutes)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final duration = int.tryParse(value) ?? 0;
                    (_modules[moduleIndex]['videos']
                            as List)[videoIndex]['duration'] =
                        duration;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Checkbox(
                    value: video['isPreview'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        (_modules[moduleIndex]['videos']
                                as List)[videoIndex]['isPreview'] =
                            value ?? false;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
