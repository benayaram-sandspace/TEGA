import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

// Import the new widget parts
import 'widgets/create_test_app_bar.dart';
import 'widgets/test_basic_info_section.dart';
import 'widgets/test_upload_section.dart';
import 'widgets/test_config_sections.dart';
import 'widgets/test_settings_section.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen>
    with TickerProviderStateMixin {
  // --- STATE AND CONTROLLERS ---
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  late AnimationController _formAnimationController;
  late Animation<double> _formAnimation;

  String? _selectedCourse;
  String _selectedDifficulty = 'Medium';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAutoGraded = false;
  bool _shuffleQuestions = false;
  bool _showResults = true;
  bool _allowRetake = false;
  int _retakeAttempts = 1;

  File? _selectedExcelFile;
  String? _fileName;
  bool _isFileUploading = false;

  final List<String> _courses = [
    'Computer Science - CSE101',
    'Mathematics - MAT201',
    'Physics - PHY101',
    'Chemistry - CHM101',
    'English Literature - ENG301',
    'Data Structures - CSE201',
    'Database Management - CSE301',
    'Software Engineering - CSE401',
  ];
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard', 'Expert'];

  // --- LIFECYCLE METHODS ---
  @override
  void initState() {
    super.initState();
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _formAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _descriptionController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---
  Future<void> _pickExcelFile() async {
    setState(() => _isFileUploading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result != null) {
        setState(() {
          _selectedExcelFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
        _showSuccessSnackbar('File uploaded: $_fileName');
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar('File picking error: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isFileUploading = false);
    }
  }

  void _removeFile() => setState(() {
    _selectedExcelFile = null;
    _fileName = null;
  });

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _createTest() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackbar('Please fill all required fields correctly.');
      return;
    }
    if (_selectedExcelFile == null) {
      _showErrorSnackbar('Please upload an Excel file with questions.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Created Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your test has been created with the file: $_fileName',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          const CreateTestAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _formAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_formAnimation),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TestBasicInfoSection(
                          testNameController: _testNameController,
                          descriptionController: _descriptionController,
                          selectedCourse: _selectedCourse,
                          courses: _courses,
                          onCourseChanged: (value) =>
                              setState(() => _selectedCourse = value),
                        ),
                        TestUploadSection(
                          fileName: _fileName,
                          isFileUploading: _isFileUploading,
                          onPickFile: _pickExcelFile,
                          onRemoveFile: _removeFile,
                          onDownloadTemplate: () =>
                              _showSuccessSnackbar('Downloading template...'),
                        ),
                        TestConfigAndScheduleSections(
                          totalMarksController: _totalMarksController,
                          passingMarksController: _passingMarksController,
                          durationController: _durationController,
                          selectedDifficulty: _selectedDifficulty,
                          difficultyLevels: _difficultyLevels,
                          onDifficultyChanged: (value) => setState(
                            () => _selectedDifficulty = value ?? 'Medium',
                          ),
                          selectedDate: _selectedDate,
                          onSelectDate: _selectDate,
                          selectedTime: _selectedTime,
                          onSelectTime: _selectTime,
                        ),
                        TestSettingsSection(
                          isAutoGraded: _isAutoGraded,
                          onAutoGradedChanged: (value) =>
                              setState(() => _isAutoGraded = value),
                          shuffleQuestions: _shuffleQuestions,
                          onShuffleChanged: (value) =>
                              setState(() => _shuffleQuestions = value),
                          showResults: _showResults,
                          onShowResultsChanged: (value) =>
                              setState(() => _showResults = value),
                          allowRetake: _allowRetake,
                          onAllowRetakeChanged: (value) =>
                              setState(() => _allowRetake = value),
                          retakeAttempts: _retakeAttempts,
                          onIncrementAttempts: () =>
                              setState(() => _retakeAttempts++),
                          onDecrementAttempts: () =>
                              setState(() => _retakeAttempts--),
                          instructionsController: _instructionsController,
                        ),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
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
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _createTest,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text(
              'Create Test',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}
