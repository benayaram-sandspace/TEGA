import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';

class EditExamPage extends StatefulWidget {
  final Map<String, dynamic> exam;

  const EditExamPage({super.key, required this.exam});

  @override
  State<EditExamPage> createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage> {
  final _formKey = GlobalKey<FormState>();
  final _examRepository = ExamRepository();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _totalMarksController;
  late final TextEditingController _passingMarksController;
  late final TextEditingController _maxAttemptsController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionsController;

  // Form state
  String? _selectedCourseId;
  DateTime? _examDate;
  List<TimeSlot> _timeSlots = [];
  TimeSlot? _newTimeSlot;
  final _newSlotIdController = TextEditingController();
  final _newSlotParticipantsController = TextEditingController(text: '30');
  bool _isLoading = false;
  bool _isLoadingCourses = false;

  // Available courses
  List<Map<String, dynamic>> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    _populateFormFromExam();
    _loadCourses();
    _fetchFreshExamDetails(); // ensure latest from DB
  }

  void _populateFormFromExam() {
    final exam = widget.exam;
    
    _titleController = TextEditingController(text: exam['title']?.toString() ?? '');
    _durationController = TextEditingController(text: (exam['duration'] ?? 0).toString());
    _totalMarksController = TextEditingController(text: (exam['totalMarks'] ?? 0).toString());
    _passingMarksController = TextEditingController(text: (exam['passingMarks'] ?? 0).toString());
    _maxAttemptsController = TextEditingController(text: (exam['maxAttempts'] ?? 1).toString());
    _descriptionController = TextEditingController(text: exam['description']?.toString() ?? '');
    _instructionsController = TextEditingController(text: exam['instructions']?.toString() ?? '');

    // Set course
    final courseId = exam['courseId'];
    if (courseId != null) {
      if (courseId is Map) {
        _selectedCourseId = courseId['_id']?.toString() ?? courseId['id']?.toString();
      } else {
        _selectedCourseId = courseId.toString();
      }
    } else if (exam['isTegaExam'] == true) {
      _selectedCourseId = 'tega-exam';
    }

    // Set exam date
    if (exam['examDate'] != null) {
      try {
        _examDate = DateTime.parse(exam['examDate'].toString());
      } catch (_) {
        _examDate = null;
      }
    }

    // Set time slots
    final slots = exam['slots'] ?? [];
    if (slots is List) {
      _timeSlots = slots.map<TimeSlot>((slot) {
        return TimeSlot(
          slotId: slot['slotId']?.toString() ?? 'Slot-${_timeSlots.length + 1}',
          startTime: slot['startTime']?.toString() ?? '--:--',
          endTime: slot['endTime']?.toString() ?? '--:--',
          maxParticipants: (slot['maxParticipants'] ?? 30) as int,
        );
      }).toList();
    }
  }

  Future<void> _fetchFreshExamDetails() async {
    try {
      final id = (widget.exam['_id'] ?? widget.exam['id']).toString();
      final fresh = await _examRepository.getExamById(id);
      if (!mounted) return;
      setState(() {
        // Re-populate with the latest DB values
        widget.exam.addAll(fresh);
        _populateFormFromExam();
      });
    } catch (_) {
      // Silent fail; we still have initial data from navigation
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
    _newSlotIdController.dispose();
    _newSlotParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _examRepository.getAvailableCourses();
      setState(() {
        _availableCourses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
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

  Future<void> _selectTime(BuildContext context, TimeSlot slot, bool isStartTime) async {
    final currentTime = isStartTime ? _parseTime(slot.startTime) : _parseTime(slot.endTime);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStartTime) {
          slot.startTime = timeStr;
        } else {
          slot.endTime = timeStr;
        }
      });
    }
  }


  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _updateExam() async {
    if (!_formKey.currentState!.validate()) return;

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

    setState(() => _isLoading = true);

    try {
      final examId = (widget.exam['_id'] ?? widget.exam['id']).toString();
      final examData = {
        'title': _titleController.text.trim(),
        'courseId': _selectedCourseId == 'tega-exam' ? 'tega-exam' : _selectedCourseId,
        'description': _descriptionController.text.trim(),
        'duration': int.parse(_durationController.text),
        'totalMarks': int.parse(_totalMarksController.text),
        'passingMarks': int.parse(_passingMarksController.text),
        'maxAttempts': int.parse(_maxAttemptsController.text),
        'examDate': _examDate!.toIso8601String(),
        'instructions': _instructionsController.text.trim(),
        'slots': _timeSlots.map((slot) => {
          'slotId': slot.slotId,
          'startTime': slot.startTime,
          'endTime': slot.endTime,
          'maxParticipants': slot.maxParticipants,
        }).toList(),
      };

      await _examRepository.updateExam(examId, examData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update exam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardStyles.background,
      appBar: AppBar(
        backgroundColor: AdminDashboardStyles.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Assessment'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Container(
          color: AdminDashboardStyles.background,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
              
              final outerPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
              final innerPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
              
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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              color: AdminDashboardStyles.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
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
                                  'Update Assessment',
                                  style: AdminDashboardStyles.welcomeHeader.copyWith(
                                    fontSize: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 6),
                                Text(
                                  'Edit exam details and time slots',
                                  style: AdminDashboardStyles.statTitle.copyWith(
                                    fontSize: isSmallScreen ? 12 : 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Exam Title
                      _buildFormField(
                        label: 'Exam Title *',
                        icon: Icons.title_rounded,
                        child: TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            hintText: 'e.g., TEGA Main Exam',
                            prefixIconData: Icons.title_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter exam title';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Course Selection
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
                                decoration: _buildInputDecoration(
                                  hintText: 'Select a course',
                                  prefixIconData: Icons.school_rounded,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'tega-exam',
                                    child: Text('TEGA Exam'),
                                  ),
                                  ..._availableCourses.map((course) {
                                    final courseId = course['_id']?.toString() ?? course['id']?.toString();
                                    return DropdownMenuItem(
                                      value: courseId,
                                      child: Text(
                                        course['title'] ?? course['courseName'] ?? 'Unknown',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
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
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Description
                      _buildFormField(
                        label: 'Description',
                        icon: Icons.description_rounded,
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _buildInputDecoration(
                            hintText: 'Enter exam description',
                            prefixIconData: Icons.description_rounded,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Duration, Total Marks, Passing Marks
                      LayoutBuilder(
                        builder: (context, c) {
                          final narrow = c.maxWidth < 700;
                          if (narrow) {
                            return Column(
                              children: [
                                _buildFormField(
                                  label: 'Duration (minutes) *',
                                  icon: Icons.timer_rounded,
                                  child: TextFormField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      hintText: 'e.g., 60',
                                      prefixIconData: Icons.timer_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter duration';
                                      }
                                      final duration = int.tryParse(value);
                                      if (duration == null || duration <= 0) {
                                        return 'Please enter a valid duration';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
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
                                        return 'Please enter total marks';
                                      }
                                      final marks = int.tryParse(value);
                                      if (marks == null || marks <= 0) {
                                        return 'Please enter valid total marks';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                _buildFormField(
                                  label: 'Passing Marks *',
                                  icon: Icons.check_circle_rounded,
                                  child: TextFormField(
                                    controller: _passingMarksController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      hintText: 'e.g., 40',
                                      prefixIconData: Icons.check_circle_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter passing marks';
                                      }
                                      final marks = int.tryParse(value);
                                      if (marks == null || marks < 0) {
                                        return 'Please enter valid passing marks';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            );
                          } else {
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
                                        hintText: 'e.g., 60',
                                        prefixIconData: Icons.timer_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter duration';
                                        }
                                        final duration = int.tryParse(value);
                                        if (duration == null || duration <= 0) {
                                          return 'Please enter a valid duration';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
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
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter total marks';
                                        }
                                        final marks = int.tryParse(value);
                                        if (marks == null || marks <= 0) {
                                          return 'Please enter valid total marks';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Passing Marks *',
                                    icon: Icons.check_circle_rounded,
                                    child: TextFormField(
                                      controller: _passingMarksController,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration(
                                        hintText: 'e.g., 40',
                                        prefixIconData: Icons.check_circle_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter passing marks';
                                        }
                                        final marks = int.tryParse(value);
                                        if (marks == null || marks < 0) {
                                          return 'Please enter valid passing marks';
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
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Max Attempts
                      _buildFormField(
                        label: 'Max Attempts *',
                        icon: Icons.repeat_rounded,
                        child: TextFormField(
                          controller: _maxAttemptsController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(
                            hintText: 'e.g., 1',
                            prefixIconData: Icons.repeat_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter max attempts';
                            }
                            final attempts = int.tryParse(value);
                            if (attempts == null || attempts < 1) {
                              return 'Please enter valid max attempts';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Exam Date
                      _buildFormField(
                        label: 'Exam Date *',
                        icon: Icons.calendar_today_rounded,
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: _buildInputDecoration(
                              hintText: 'Select exam date',
                              prefixIconData: Icons.calendar_today_rounded,
                              suffixIcon: Icon(
                                Icons.calendar_today,
                                color: AdminDashboardStyles.primary,
                              ),
                            ),
                            child: Text(
                              _examDate != null
                                  ? DateFormat('dd-MM-yyyy').format(_examDate!)
                                  : 'Select exam date',
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
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Instructions
                      _buildFormField(
                        label: 'Instructions',
                        icon: Icons.info_rounded,
                        child: TextFormField(
                          controller: _instructionsController,
                          maxLines: 4,
                          decoration: _buildInputDecoration(
                            hintText: 'Enter exam instructions...',
                            prefixIconData: Icons.info_rounded,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Time Slots Section
                      _buildTimeSlotsSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updateExam,
                            style: AdminDashboardStyles.getPrimaryButtonStyle().copyWith(
                              padding: const MaterialStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Update Exam'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotsSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 400;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: AdminDashboardStyles.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Time Slots *',
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
                ],
              );
            } else {
              return Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: AdminDashboardStyles.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Time Slots *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdminDashboardStyles.textDark,
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // Existing Time Slots
        if (_timeSlots.isNotEmpty) ...[
          ..._timeSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            return _buildTimeSlotRow(slot, index, isSmallScreen);
          }),
          const SizedBox(height: 16),
        ],

        // Add New Time Slot Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminDashboardStyles.accentBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AdminDashboardStyles.accentBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Time Slot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardStyles.accentBlue,
                ),
              ),
              const SizedBox(height: 16),
              _buildNewTimeSlotForm(isSmallScreen),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Note: You can add new time slots or remove existing ones. Changes will be saved when you update the exam.',
          style: TextStyle(
            fontSize: 12,
            color: AdminDashboardStyles.textLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotRow(TimeSlot slot, int index, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminDashboardStyles.borderLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                Row(
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
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
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

  Widget _buildNewTimeSlotForm(bool isSmallScreen) {
    if (_newTimeSlot == null) {
      _newTimeSlot = TimeSlot(
        slotId: 'Slot-${_timeSlots.length + 1}',
        startTime: '--:--',
        endTime: '--:--',
        maxParticipants: 30,
      );
      _newSlotIdController.text = _newTimeSlot!.slotId;
      _newSlotParticipantsController.text = '30';
    }
    final newSlot = _newTimeSlot!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 700;
        if (narrow) {
          return Column(
            children: [
              _buildFormField(
                label: 'Slot ID',
                icon: Icons.label_rounded,
                child: TextFormField(
                  controller: _newSlotIdController,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g., Slot-2',
                    prefixIconData: Icons.label_rounded,
                  ),
                  onChanged: (value) => newSlot.slotId = value,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'Start Time',
                icon: Icons.access_time_rounded,
                child: InkWell(
                  onTap: () => _selectTime(context, newSlot, true),
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
                      newSlot.startTime,
                      style: TextStyle(
                        color: newSlot.startTime == '--:--'
                            ? Colors.grey[600]
                            : AdminDashboardStyles.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'End Time',
                icon: Icons.access_time_rounded,
                child: InkWell(
                  onTap: () => _selectTime(context, newSlot, false),
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
                      newSlot.endTime,
                      style: TextStyle(
                        color: newSlot.endTime == '--:--'
                            ? Colors.grey[600]
                            : AdminDashboardStyles.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'Max Participants',
                icon: Icons.people_rounded,
                child: TextFormField(
                  controller: _newSlotParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g., 30',
                    prefixIconData: Icons.people_rounded,
                  ),
                  onChanged: (value) {
                    final participants = int.tryParse(value);
                    if (participants != null && participants > 0) {
                      newSlot.maxParticipants = participants;
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (newSlot.startTime != '--:--' && newSlot.endTime != '--:--') {
                      setState(() {
                        _timeSlots.add(TimeSlot(
                          slotId: newSlot.slotId,
                          startTime: newSlot.startTime,
                          endTime: newSlot.endTime,
                          maxParticipants: newSlot.maxParticipants,
                        ));
                        _newTimeSlot = TimeSlot(
                          slotId: 'Slot-${_timeSlots.length + 2}',
                          startTime: '--:--',
                          endTime: '--:--',
                          maxParticipants: 30,
                        );
                        _newSlotIdController.text = _newTimeSlot!.slotId;
                        _newSlotParticipantsController.text = '30';
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select both start and end time'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add New Slot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminDashboardStyles.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'Slot ID',
                  icon: Icons.label_rounded,
                  child: TextFormField(
                    controller: TextEditingController(text: newSlot.slotId),
                    decoration: _buildInputDecoration(
                      hintText: 'e.g., Slot-2',
                      prefixIconData: Icons.label_rounded,
                    ),
                    onChanged: (value) => newSlot.slotId = value,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'Start Time',
                  icon: Icons.access_time_rounded,
                  child: InkWell(
                    onTap: () => _selectTime(context, newSlot, true),
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
                        newSlot.startTime,
                        style: TextStyle(
                          color: newSlot.startTime == '--:--'
                              ? Colors.grey[600]
                              : AdminDashboardStyles.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'End Time',
                  icon: Icons.access_time_rounded,
                  child: InkWell(
                    onTap: () => _selectTime(context, newSlot, false),
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
                        newSlot.endTime,
                        style: TextStyle(
                          color: newSlot.endTime == '--:--'
                              ? Colors.grey[600]
                              : AdminDashboardStyles.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'Max Participants',
                  icon: Icons.people_rounded,
                  child: TextFormField(
                    controller: TextEditingController(text: newSlot.maxParticipants.toString()),
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                      hintText: 'e.g., 30',
                      prefixIconData: Icons.people_rounded,
                    ),
                    onChanged: (value) {
                      final participants = int.tryParse(value);
                      if (participants != null && participants > 0) {
                        newSlot.maxParticipants = participants;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (newSlot.startTime != '--:--' && newSlot.endTime != '--:--') {
                      setState(() {
                        _timeSlots.add(TimeSlot(
                          slotId: newSlot.slotId,
                          startTime: newSlot.startTime,
                          endTime: newSlot.endTime,
                          maxParticipants: newSlot.maxParticipants,
                        ));
                        _newTimeSlot = TimeSlot(
                          slotId: 'Slot-${_timeSlots.length + 2}',
                          startTime: '--:--',
                          endTime: '--:--',
                          maxParticipants: 30,
                        );
                        _newSlotIdController.text = _newTimeSlot!.slotId;
                        _newSlotParticipantsController.text = '30';
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select both start and end time'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add New Slot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminDashboardStyles.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          );
        }
      },
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
              Icon(
                icon,
                size: 16,
                color: AdminDashboardStyles.primary,
              ),
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

