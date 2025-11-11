import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/constants/app_colors.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/3_admin_panel/presentation/0_dashboard/admin_dashboard_styles.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/3_admin_panel/data/repositories/exam_repository.dart';

class QuestionPapersPage extends StatefulWidget {
  const QuestionPapersPage({super.key});

  @override
  State<QuestionPapersPage> createState() => _QuestionPapersPageState();
}

class _QuestionPapersPageState extends State<QuestionPapersPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final ExamRepository _examRepository = ExamRepository();

  String? _selectedQuestionPaperType;
  String? _selectedCourseId;
  String _uploadMethod = 'excel'; // 'excel' or 'manual'
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isLoadingCourses = false;
  bool _isLoadingPapers = false;
  List<Map<String, dynamic>> _availableCourses = [];
  List<Map<String, dynamic>> _questionPapers = [];
  // Manual entry state
  final _qController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  String _correctAnswer = 'A';
  final List<Map<String, dynamic>> _manualQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadQuestionPapers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _qController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
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

  Future<void> _loadQuestionPapers() async {
    setState(() => _isLoadingPapers = true);
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminQuestionPapersAll),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            // Backend returns 'questionPapers' not 'data'
            final papers = data['questionPapers'] ?? data['data'] ?? [];
            _questionPapers = List<Map<String, dynamic>>.from(papers);
            _isLoadingPapers = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load question papers');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load question papers: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingPapers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load question papers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadQuestionPaper() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadMethod == 'excel' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Excel file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final headers = await _authService.getAuthHeaders();
      
      if (_uploadMethod == 'excel') {
        // Upload Excel file
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiEndpoints.adminQuestionPaperUpload),
        );

        request.headers.addAll(headers);
        request.files.add(
          await http.MultipartFile.fromPath(
            'questionPaper',
            _selectedFile!.path,
          ),
        );

        request.fields['courseId'] = _selectedCourseId ?? '';
        request.fields['description'] = _descriptionController.text.trim();
        request.fields['isTegaExamPaper'] = (_selectedQuestionPaperType == 'tega-exam').toString();

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Question paper uploaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _resetForm();
              _loadQuestionPapers();
            }
          } else {
            throw Exception(data['message'] ?? 'Upload failed');
          }
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Upload failed');
        }
      } else {
        // Manual entry upload via JSON
        if (_manualQuestions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add at least one question'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final payload = {
          'courseId': _selectedCourseId ?? '',
          'description': _descriptionController.text.trim(),
          'isTegaExamPaper': _selectedQuestionPaperType == 'tega-exam',
          'questionsData': _manualQuestions,
        };

        final jsonHeaders = {
          ...headers,
          'Content-Type': 'application/json',
        };

        final response = await http.post(
          Uri.parse(ApiEndpoints.adminQuestionPaperUploadJson),
          headers: jsonHeaders,
          body: json.encode(payload),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Question paper created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _resetForm();
              _loadQuestionPapers();
            }
          } else {
            throw Exception(data['message'] ?? 'Upload failed');
          }
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _descriptionController.clear();
    setState(() {
      _selectedQuestionPaperType = null;
      _selectedCourseId = null;
      _uploadMethod = 'excel';
      _selectedFile = null;
      _fileName = null;
      _manualQuestions.clear();
      _qController.clear();
      _optAController.clear();
      _optBController.clear();
      _optCController.clear();
      _optDController.clear();
      _correctAnswer = 'A';
    });
  }

  Future<void> _deleteQuestionPaper(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question Paper'),
        content: const Text('Are you sure you want to delete this question paper?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiEndpoints.adminQuestionPaperDelete(id)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question paper deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadQuestionPapers();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Delete failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(
                'Question Papers Management',
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: AdminDashboardStyles.textDark,
                ),
              ),
              const SizedBox(height: 32),

              // Upload Form Section
              _buildUploadForm(isSmallScreen),
              const SizedBox(height: 40),

              // Excel Format Instructions
              _buildExcelFormatInstructions(isSmallScreen),
              const SizedBox(height: 40),

              // Question Papers List
              _buildQuestionPapersList(isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadForm(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AdminDashboardStyles.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.upload_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Upload New Question Paper',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AdminDashboardStyles.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question Paper Type
            _buildFormField(
              label: 'Question Paper Type *',
              icon: Icons.category_rounded,
              child: DropdownButtonFormField<String>(
                value: _selectedQuestionPaperType,
                isExpanded: true,
                decoration: _buildInputDecoration(
                  hintText: 'Select type',
                  prefixIconData: Icons.category_rounded,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'course',
                    child: Text('Course'),
                  ),
                  DropdownMenuItem(
                    value: 'tega-exam',
                    child: Text('TEGA Exam'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedQuestionPaperType = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

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
                      decoration: _buildInputDecoration(
                        hintText: 'Select a course',
                        prefixIconData: Icons.school_rounded,
                      ),
                      items: _availableCourses.map((course) {
                        final courseId = course['_id']?.toString() ?? course['id']?.toString();
                        return DropdownMenuItem(
                          value: courseId,
                          child: Text(
                            course['title'] ?? course['courseName'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
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
            const SizedBox(height: 20),

            // Description
            _buildFormField(
              label: 'Description',
              icon: Icons.description_rounded,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _buildInputDecoration(
                  hintText: 'Brief description of the question paper',
                  prefixIconData: Icons.description_rounded,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Method
            Text(
              'Upload Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMethodButton(
                    label: 'Manual Entry',
                    isSelected: _uploadMethod == 'manual',
                    onTap: () => setState(() => _uploadMethod = 'manual'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMethodButton(
                    label: 'Excel Upload',
                    isSelected: _uploadMethod == 'excel',
                    onTap: () => setState(() => _uploadMethod = 'excel'),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // File Upload (only for Excel)
            if (_uploadMethod == 'excel') ...[
              _buildFormField(
                label: 'Upload Excel File *',
                icon: Icons.file_upload_rounded,
                child: InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AdminDashboardStyles.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminDashboardStyles.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Choose File'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _fileName ?? 'No file chosen',
                            style: TextStyle(
                              color: _fileName != null
                                  ? AdminDashboardStyles.textDark
                                  : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only Excel files (.xlsx, .xls) are allowed.',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ] else ...[
              // Manual Entry UI
              _buildFormField(
                label: 'Question',
                icon: Icons.help_outline_rounded,
                child: TextFormField(
                  controller: _qController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your question here...',
                    prefixIconData: Icons.edit_note_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Options A and B
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 700;
                  if (narrow) {
                    return Column(
                      children: [
                        _buildFormField(
                          label: 'Option A',
                          icon: Icons.circle_outlined,
                          child: TextFormField(
                            controller: _optAController,
                            decoration: _buildInputDecoration(
                              hintText: 'Option A',
                              prefixIconData: Icons.circle_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFormField(
                          label: 'Option B',
                          icon: Icons.circle_outlined,
                          child: TextFormField(
                            controller: _optBController,
                            decoration: _buildInputDecoration(
                              hintText: 'Option B',
                              prefixIconData: Icons.circle_outlined,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Option A',
                            icon: Icons.circle_outlined,
                            child: TextFormField(
                              controller: _optAController,
                              decoration: _buildInputDecoration(
                                hintText: 'Option A',
                                prefixIconData: Icons.circle_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Option B',
                            icon: Icons.circle_outlined,
                            child: TextFormField(
                              controller: _optBController,
                              decoration: _buildInputDecoration(
                                hintText: 'Option B',
                                prefixIconData: Icons.circle_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 700;
                  if (narrow) {
                    return Column(
                      children: [
                        _buildFormField(
                          label: 'Option C',
                          icon: Icons.circle_outlined,
                          child: TextFormField(
                            controller: _optCController,
                            decoration: _buildInputDecoration(
                              hintText: 'Option C',
                              prefixIconData: Icons.circle_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFormField(
                          label: 'Option D',
                          icon: Icons.circle_outlined,
                          child: TextFormField(
                            controller: _optDController,
                            decoration: _buildInputDecoration(
                              hintText: 'Option D',
                              prefixIconData: Icons.circle_outlined,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Option C',
                            icon: Icons.circle_outlined,
                            child: TextFormField(
                              controller: _optCController,
                              decoration: _buildInputDecoration(
                                hintText: 'Option C',
                                prefixIconData: Icons.circle_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Option D',
                            icon: Icons.circle_outlined,
                            child: TextFormField(
                              controller: _optDController,
                              decoration: _buildInputDecoration(
                                hintText: 'Option D',
                                prefixIconData: Icons.circle_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'Correct Answer',
                icon: Icons.check_circle_rounded,
                child: DropdownButtonFormField<String>(
                  value: _correctAnswer,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    hintText: 'Select correct answer',
                    prefixIconData: Icons.check_circle_rounded,
                  ),
                  items: const ['A', 'B', 'C', 'D']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _correctAnswer = v ?? 'A'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addManualQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Question'),
                ),
              ),
              const SizedBox(height: 16),
              if (_manualQuestions.isNotEmpty) _buildManualQuestionsPreview(),
            ],

            const SizedBox(height: 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadQuestionPaper,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(_isLoading ? 'Uploading...' : 'Upload'),
                style: AdminDashboardStyles.getPrimaryButtonStyle().copyWith(
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
  }

  void _addManualQuestion() {
    final q = _qController.text.trim();
    final a = _optAController.text.trim();
    final b = _optBController.text.trim();
    final c = _optCController.text.trim();
    final d = _optDController.text.trim();
    if (q.isEmpty || a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill the question and all four options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _manualQuestions.add({
        'question': q,
        'optionA': a,
        'optionB': b,
        'optionC': c,
        'optionD': d,
        'correct': _correctAnswer,
      });
      _qController.clear();
      _optAController.clear();
      _optBController.clear();
      _optCController.clear();
      _optDController.clear();
      _correctAnswer = 'A';
    });
  }

  Widget _buildManualQuestionsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Added Questions (${_manualQuestions.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._manualQuestions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['question'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Correct: ${q['correct']}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _manualQuestions.removeAt(idx);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  Widget _buildMethodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExcelFormatInstructions(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Excel File Format',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Excel file must contain these exact column headers:',
            style: TextStyle(
              fontSize: 14,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildColumnHeader('sno'),
                _buildColumnHeader('question'),
                _buildColumnHeader('optionA'),
                _buildColumnHeader('optionB'),
                _buildColumnHeader('optionC'),
                _buildColumnHeader('optionD'),
                _buildColumnHeader('correct'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('Each question gets 1 mark for correct answer, 0 for wrong'),
              _buildBulletPoint("'correct' column should contain A, B, C, or D"),
              _buildBulletPoint('Save your file as .xlsx or .xls format'),
              _buildBulletPoint(
                'Sample data: sno=1, question="What is 2+2?", optionA="3", optionB="4", optionC="5", optionD="6", correct="B"',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String header) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        header,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue[900],
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AdminDashboardStyles.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPapersList(bool isSmallScreen) {
    if (_isLoadingPapers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questionPapers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AdminDashboardStyles.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: AdminDashboardStyles.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No question papers found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardStyles.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your first question paper to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Papers',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AdminDashboardStyles.textDark,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: _questionPapers.map((paper) => _buildQuestionPaperCard(paper, true)).toList(),
              );
            } else {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _questionPapers.map((paper) => _buildQuestionPaperCard(paper, false)).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuestionPaperCard(Map<String, dynamic> paper, bool isFullWidth) {
    final name = paper['name'] ?? 'Unknown';
    final description = paper['description'] ?? 'No description provided';
    final questionCount = paper['questionCount'] ?? 0;
    final isTegaExam = paper['isTegaExamPaper'] == true;
    final usedByExams = paper['usedByExams'] as List<dynamic>? ?? [];

    return Container(
      width: isFullWidth ? double.infinity : 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and delete button
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AdminDashboardStyles.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AdminDashboardStyles.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteQuestionPaper(paper['_id'] ?? paper['id']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isTegaExam ? 'TEGA Exam' : 'Course',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AdminDashboardStyles.textLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Question count
          Text(
            'Questions: $questionCount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
          ),

          // Used by exams warning
          if (usedByExams.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Used by ${usedByExams.length} exam(s)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...usedByExams.take(2).map((exam) => Text(
                              exam['title'] ?? exam['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement view functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View functionality coming soon')),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminDashboardStyles.primary,
                    side: BorderSide(color: AdminDashboardStyles.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download functionality coming soon')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminDashboardStyles.primary,
                    side: BorderSide(color: AdminDashboardStyles.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
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
}

