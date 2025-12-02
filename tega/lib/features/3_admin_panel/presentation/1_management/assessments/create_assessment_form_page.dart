import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class CreateAssessmentFormPage extends StatefulWidget {
  const CreateAssessmentFormPage({super.key});

  @override
  State<CreateAssessmentFormPage> createState() =>
      _CreateAssessmentFormPageState();
}

class _CreateAssessmentFormPageState extends State<CreateAssessmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _examRepository = ExamRepository();
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

  // Form controllers
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _maxAttemptsController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String? _selectedCourseId;
  DateTime? _examDate;
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = false;
  bool _isLoadingCourses = false;

  // Available courses
  List<Map<String, dynamic>> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    await _loadFromCache();

    // Then load fresh data
    await _loadCourses();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedCourses = await _cacheService.getAvailableCourses();

      if (cachedCourses != null && cachedCourses.isNotEmpty) {
        setState(() {
          _availableCourses = List<Map<String, dynamic>>.from(cachedCourses);
        });
      }
    } catch (e) {
      // Silently handle cache errors
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _maxAttemptsController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
  }

  Future<void> _loadCourses({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _availableCourses.isNotEmpty) {
      _loadCoursesInBackground();
      return;
    }

    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _examRepository.getAvailableCourses();
      setState(() {
        _availableCourses = courses;
        _isLoadingCourses = false;
      });

      // Cache the data
      await _cacheService.setAvailableCourses(courses);
      // Reset toast flag on successful load (internet is back)
      _cacheService.resetNoInternetToastFlag();
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedCourses = await _cacheService.getAvailableCourses();
        if (cachedCourses != null && cachedCourses.isNotEmpty) {
          // Load from cache
          setState(() {
            _availableCourses = List<Map<String, dynamic>>.from(cachedCourses);
            _isLoadingCourses = false;
          });
          return;
        }

        // No cache available
        setState(() => _isLoadingCourses = false);
      } else {
        // Other errors
        setState(() => _isLoadingCourses = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load courses: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadCoursesInBackground() async {
    try {
      final courses = await _examRepository.getAvailableCourses();
      if (mounted) {
        setState(() {
          _availableCourses = courses;
        });

        // Cache the data
        await _cacheService.setAvailableCourses(courses);
        // Reset toast flag on successful load (internet is back)
        _cacheService.resetNoInternetToastFlag();
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
    }
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );

    if (picked != null && picked != _examDate) {
      setState(() => _examDate = picked);
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeSlot slot,
    bool isStartTime,
  ) async {
    final currentTime = isStartTime
        ? _parseTime(slot.startTime) ?? TimeOfDay.now()
        : _parseTime(slot.endTime) ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          slot.startTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          slot.endTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(
        TimeSlot(
          slotId: 'Slot-${_timeSlots.length + 1}',
          startTime: '--:--',
          endTime: '--:--',
          maxParticipants: 30,
        ),
      );
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _createAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an exam date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_timeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate time slots
    for (var i = 0; i < _timeSlots.length; i++) {
      final slot = _timeSlots[i];
      if (slot.startTime == '--:--' || slot.endTime == '--:--') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please set start and end time for slot ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final examData = {
        'title': _titleController.text.trim(),
        'courseId': _selectedCourseId == 'tega-exam'
            ? 'tega-exam'
            : _selectedCourseId,
        'isTegaExam': _selectedCourseId == 'tega-exam',
        'description': _descriptionController.text.trim(),
        'duration': int.parse(_durationController.text),
        'totalMarks': int.parse(_totalMarksController.text),
        'passingMarks': int.parse(_passingMarksController.text),
        'maxAttempts': int.parse(_maxAttemptsController.text),
        'examDate': _examDate!.toIso8601String(),
        'instructions': _instructionsController.text.trim(),
        'slots': _timeSlots
            .map(
              (slot) => {
                'slotId': slot.slotId,
                'startTime': slot.startTime,
                'endTime': slot.endTime,
                'maxParticipants': slot.maxParticipants,
              },
            )
            .toList(),
        'requiresPayment': false,
        'price': 0,
      };

      await _examRepository.createExam(examData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _titleController.clear();
        _durationController.clear();
        _totalMarksController.clear();
        _passingMarksController.clear();
        _maxAttemptsController.text = '1';
        _descriptionController.clear();
        _instructionsController.clear();
        setState(() {
          _selectedCourseId = null;
          _examDate = null;
          _timeSlots = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        color: AdminDashboardStyles.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive padding based on screen width
            final isSmallScreen = constraints.maxWidth < 600;
            final isMediumScreen =
                constraints.maxWidth >= 600 && constraints.maxWidth < 900;

            final outerPadding = isSmallScreen
                ? 16.0
                : (isMediumScreen ? 20.0 : 24.0);
            final innerPadding = isSmallScreen
                ? 16.0
                : (isMediumScreen ? 20.0 : 24.0);
            final headerSpacing = isSmallScreen ? 24.0 : 32.0;
            final fieldSpacing = isSmallScreen ? 16.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(outerPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: AdminDashboardStyles.cardBackground,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  border: Border.all(
                    color: AdminDashboardStyles.primary.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(innerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    LayoutBuilder(
                      builder: (context, headerConstraints) {
                        if (headerConstraints.maxWidth < 400) {
                          // Stack vertically on very small screens
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminDashboardStyles.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.assessment_rounded,
                                  color: AdminDashboardStyles.primary,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Text(
                                'Create Assessment',
                                style: AdminDashboardStyles.welcomeHeader
                                    .copyWith(
                                      fontSize: isSmallScreen ? 20 : 24,
                                    ),
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              Text(
                                'Schedule and create new assessments, exams, and evaluations',
                                style: AdminDashboardStyles.statTitle.copyWith(
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Horizontal layout
                          return Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminDashboardStyles.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.assessment_rounded,
                                  color: AdminDashboardStyles.primary,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Assessment',
                                      style: AdminDashboardStyles.welcomeHeader
                                          .copyWith(
                                            fontSize: isSmallScreen ? 20 : 24,
                                          ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 6),
                                    Text(
                                      'Schedule and create new assessments, exams, and evaluations',
                                      style: AdminDashboardStyles.statTitle
                                          .copyWith(
                                            fontSize: isSmallScreen ? 12 : 13,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: headerSpacing),
                    // Assessment Title
                    _buildFormField(
                      label: 'Assessment Title *',
                      icon: Icons.title_rounded,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter assessment title',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AdminDashboardStyles.primary.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.title_rounded,
                              color: AdminDashboardStyles.primary,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AdminDashboardStyles.borderLight,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AdminDashboardStyles.borderLight,
                              width: 1,
                            ),
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
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Assessment title is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Course
                    _buildFormField(
                      label: 'Course *',
                      icon: Icons.school_rounded,
                      child: _isLoadingCourses
                          ? const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedCourseId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Select a course',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AdminDashboardStyles.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: AdminDashboardStyles.primary,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AdminDashboardStyles.borderLight,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AdminDashboardStyles.borderLight,
                                    width: 1,
                                  ),
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
                                  borderSide: BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.error,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'tega-exam',
                                  child: Text('TEGA Exam'),
                                ),
                                ..._availableCourses.map((course) {
                                  final courseId =
                                      course['_id']?.toString() ??
                                      course['id']?.toString();
                                  return DropdownMenuItem(
                                    value: courseId,
                                    child: Text(
                                      course['title'] ??
                                          course['courseName'] ??
                                          'Unknown',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedCourseId = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a course';
                                }
                                return null;
                              },
                            ),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Exam Date
                    _buildFormField(
                      label: 'Exam Date *',
                      icon: Icons.calendar_today_rounded,
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            hintText: 'dd-mm-yyyy',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AdminDashboardStyles.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: AdminDashboardStyles.primary,
                                size: 18,
                              ),
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: AdminDashboardStyles.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AdminDashboardStyles.borderLight,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AdminDashboardStyles.borderLight,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AdminDashboardStyles.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            _examDate != null
                                ? DateFormat('dd-MM-yyyy').format(_examDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _examDate != null
                                  ? AdminDashboardStyles.textDark
                                  : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Duration, Total Marks, Passing Marks row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 700) {
                          // Stack vertically on small screens
                          return Column(
                            children: [
                              _buildFormField(
                                label: 'Duration (minutes) *',
                                icon: Icons.timer_rounded,
                                child: TextFormField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'e.g., 120',
                                    prefixIconData: Icons.timer_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final duration = int.tryParse(value);
                                    if (duration == null || duration <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildFormField(
                                label: 'Total Marks *',
                                icon: Icons.star_rounded,
                                child: TextFormField(
                                  controller: _totalMarksController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'e.g., 100',
                                    prefixIconData: Icons.star_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final marks = int.tryParse(value);
                                    if (marks == null || marks <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildFormField(
                                label: 'Passing Marks *',
                                icon: Icons.check_circle_rounded,
                                child: TextFormField(
                                  controller: _passingMarksController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'e.g., 50',
                                    prefixIconData: Icons.check_circle_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final marks = int.tryParse(value);
                                    if (marks == null || marks < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Horizontal layout on larger screens
                          return Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  label: 'Duration (minutes) *',
                                  icon: Icons.timer_rounded,
                                  child: TextFormField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      hintText: 'e.g., 120',
                                      prefixIconData: Icons.timer_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final duration = int.tryParse(value);
                                      if (duration == null || duration <= 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFormField(
                                  label: 'Total Marks *',
                                  icon: Icons.star_rounded,
                                  child: TextFormField(
                                    controller: _totalMarksController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      hintText: 'e.g., 100',
                                      prefixIconData: Icons.star_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final marks = int.tryParse(value);
                                      if (marks == null || marks <= 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFormField(
                                  label: 'Passing Marks *',
                                  icon: Icons.check_circle_rounded,
                                  child: TextFormField(
                                    controller: _passingMarksController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      hintText: 'e.g., 50',
                                      prefixIconData:
                                          Icons.check_circle_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final marks = int.tryParse(value);
                                      if (marks == null || marks < 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: fieldSpacing),

                    // Max Attempts
                    _buildFormField(
                      label: 'Max Attempts',
                      icon: Icons.repeat_rounded,
                      child: TextFormField(
                        controller: _maxAttemptsController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          hintText: '1',
                          prefixIconData: Icons.repeat_rounded,
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final attempts = int.tryParse(value);
                            if (attempts == null || attempts < 1) {
                              return 'Must be at least 1';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Description
                    _buildFormField(
                      label: 'Description',
                      icon: Icons.description_rounded,
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(
                          hintText: 'Enter assessment description...',
                          prefixIconData: Icons.description_rounded,
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Instructions
                    _buildFormField(
                      label: 'Instructions',
                      icon: Icons.info_rounded,
                      child: TextFormField(
                        controller: _instructionsController,
                        maxLines: 5,
                        decoration: _buildInputDecoration(
                          hintText: 'Enter exam instructions...',
                          prefixIconData: Icons.info_rounded,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Time Slots Section
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 400) {
                          // Stack vertically on very small screens
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: AdminDashboardStyles.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Time Slots *',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AdminDashboardStyles.textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addTimeSlot,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Slot'),
                                  style:
                                      AdminDashboardStyles.getPrimaryButtonStyle(),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Horizontal layout on larger screens
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: AdminDashboardStyles.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Time Slots *',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AdminDashboardStyles.textDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _addTimeSlot,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Slot'),
                                style:
                                    AdminDashboardStyles.getPrimaryButtonStyle(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Time Slots List
                    if (_timeSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AdminDashboardStyles.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AdminDashboardStyles.primary.withOpacity(
                              0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 48,
                                color: AdminDashboardStyles.primary.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No time slots added',
                                style: TextStyle(
                                  color: AdminDashboardStyles.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click "Add Slot" to add one',
                                style: TextStyle(
                                  color: AdminDashboardStyles.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._timeSlots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final slot = entry.value;
                        return _buildTimeSlotRow(slot, index);
                      }),

                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createAssessment,
                        icon: _isLoading
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
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _isLoading ? 'Creating...' : 'Create Assessment',
                        ),
                        style: AdminDashboardStyles.getPrimaryButtonStyle()
                            .copyWith(
                              padding: const MaterialStatePropertyAll(
                                EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIconData,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: prefixIconData != null
          ? Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                prefixIconData,
                color: AdminDashboardStyles.primary,
                size: 18,
              ),
            )
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AdminDashboardStyles.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AdminDashboardStyles.primary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardStyles.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildTimeSlotRow(TimeSlot slot, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminDashboardStyles.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            // Stack vertically on small screens
            return Column(
              children: [
                _buildFormField(
                  label: 'Slot ID',
                  icon: Icons.label_rounded,
                  child: TextFormField(
                    initialValue: slot.slotId,
                    decoration: _buildInputDecoration(
                      hintText: 'e.g., Slot-1',
                      prefixIconData: Icons.label_rounded,
                    ),
                    onChanged: (value) {
                      slot.slotId = value;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'Start Time',
                  icon: Icons.access_time_rounded,
                  child: InkWell(
                    onTap: () => _selectTime(context, slot, true),
                    child: InputDecorator(
                      decoration: _buildInputDecoration(
                        hintText: '--:--',
                        prefixIconData: Icons.access_time_rounded,
                        suffixIcon: Icon(
                          Icons.access_time,
                          color: AdminDashboardStyles.primary,
                        ),
                      ),
                      child: Text(
                        slot.startTime,
                        style: TextStyle(
                          color: slot.startTime == '--:--'
                              ? Colors.grey[600]
                              : AdminDashboardStyles.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'End Time',
                  icon: Icons.access_time_rounded,
                  child: InkWell(
                    onTap: () => _selectTime(context, slot, false),
                    child: InputDecorator(
                      decoration: _buildInputDecoration(
                        hintText: '--:--',
                        prefixIconData: Icons.access_time_rounded,
                        suffixIcon: Icon(
                          Icons.access_time,
                          color: AdminDashboardStyles.primary,
                        ),
                      ),
                      child: Text(
                        slot.endTime,
                        style: TextStyle(
                          color: slot.endTime == '--:--'
                              ? Colors.grey[600]
                              : AdminDashboardStyles.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'Max Participants',
                        icon: Icons.people_rounded,
                        child: TextFormField(
                          initialValue: slot.maxParticipants.toString(),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(
                            hintText: 'e.g., 50',
                            prefixIconData: Icons.people_rounded,
                          ),
                          onChanged: (value) {
                            final participants = int.tryParse(value);
                            if (participants != null && participants > 0) {
                              slot.maxParticipants = participants;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _removeTimeSlot(index),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Horizontal layout on larger screens
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormField(
                    label: 'Slot ID',
                    icon: Icons.label_rounded,
                    child: TextFormField(
                      initialValue: slot.slotId,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g., Slot-1',
                        prefixIconData: Icons.label_rounded,
                      ),
                      onChanged: (value) {
                        slot.slotId = value;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'Start Time',
                        icon: Icons.access_time_rounded,
                        child: InkWell(
                          onTap: () => _selectTime(context, slot, true),
                          child: InputDecorator(
                            decoration: _buildInputDecoration(
                              hintText: '--:--',
                              prefixIconData: Icons.access_time_rounded,
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: AdminDashboardStyles.primary,
                              ),
                            ),
                            child: Text(
                              slot.startTime,
                              style: TextStyle(
                                color: slot.startTime == '--:--'
                                    ? Colors.grey[600]
                                    : AdminDashboardStyles.textDark,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        label: 'End Time',
                        icon: Icons.access_time_rounded,
                        child: InkWell(
                          onTap: () => _selectTime(context, slot, false),
                          child: InputDecorator(
                            decoration: _buildInputDecoration(
                              hintText: '--:--',
                              prefixIconData: Icons.access_time_rounded,
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: AdminDashboardStyles.primary,
                              ),
                            ),
                            child: Text(
                              slot.endTime,
                              style: TextStyle(
                                color: slot.endTime == '--:--'
                                    ? Colors.grey[600]
                                    : AdminDashboardStyles.textDark,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildFormField(
                    label: 'Max Participants',
                    icon: Icons.people_rounded,
                    child: TextFormField(
                      initialValue: slot.maxParticipants.toString(),
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g., 50',
                        prefixIconData: Icons.people_rounded,
                      ),
                      onChanged: (value) {
                        final participants = int.tryParse(value);
                        if (participants != null && participants > 0) {
                          slot.maxParticipants = participants;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _removeTimeSlot(index),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class TimeSlot {
  String slotId;
  String startTime;
  String endTime;
  int maxParticipants;

  TimeSlot({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
  });
}
