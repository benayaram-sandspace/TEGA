import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tega/core/services/admin_dashboard_cache_service.dart';
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
  final AdminDashboardCacheService _cacheService = AdminDashboardCacheService();

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
    _initializeCacheAndLoadData();
  }

  Future<void> _initializeCacheAndLoadData() async {
    // Initialize cache service
    await _cacheService.initialize();
    
    // Try to load from cache first
    await _loadFromCache();
    
    // Then load fresh data
    await _loadCourses();
    await _loadQuestionPapers();
  }

  Future<void> _loadFromCache() async {
    try {
      // Load courses from cache
      final cachedCourses = await _cacheService.getAvailableCourses();
      if (cachedCourses != null && cachedCourses.isNotEmpty) {
        setState(() {
          _availableCourses = List<Map<String, dynamic>>.from(cachedCourses);
        });
      }

      // Load question papers from cache
      final cachedPapers = await _cacheService.getQuestionPapersData();
      if (cachedPapers != null && cachedPapers.isNotEmpty) {
        setState(() {
          _questionPapers = cachedPapers;
        });
      }
    } catch (e) {
      // Silently handle cache errors
    }
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

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains('no address associated with hostname'));
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

  Future<void> _loadQuestionPapers({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && _questionPapers.isNotEmpty) {
      _loadQuestionPapersInBackground();
      return;
    }

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
          final papers = data['questionPapers'] ?? data['data'] ?? [];
          setState(() {
            _questionPapers = List<Map<String, dynamic>>.from(papers);
            _isLoadingPapers = false;
          });
          
          // Cache the data
          await _cacheService.setQuestionPapersData(_questionPapers);
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        } else {
          throw Exception(data['message'] ?? 'Failed to load question papers');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load question papers: ${response.statusCode}');
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedPapers = await _cacheService.getQuestionPapersData();
        if (cachedPapers != null && cachedPapers.isNotEmpty) {
          // Load from cache
          setState(() {
            _questionPapers = cachedPapers;
            _isLoadingPapers = false;
          });
          return;
        }
        
        // No cache available
        setState(() => _isLoadingPapers = false);
      } else {
        // Other errors
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
  }

  Future<void> _loadQuestionPapersInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminQuestionPapersAll),
        headers: headers,
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final papers = data['questionPapers'] ?? data['data'] ?? [];
          setState(() {
            _questionPapers = List<Map<String, dynamic>>.from(papers);
          });
          
          // Cache the data
          await _cacheService.setQuestionPapersData(_questionPapers);
          // Reset toast flag on successful load (internet is back)
          _cacheService.resetNoInternetToastFlag();
        }
      }
    } catch (e) {
      // Silently fail in background refresh - don't show toast here
      // Toast is only shown once in the main load method
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
              _loadQuestionPapers(forceRefresh: true);
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
              _loadQuestionPapers(forceRefresh: true);
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
          _loadQuestionPapers(forceRefresh: true);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(
            'Question Papers Management',
            style: TextStyle(
              fontSize: isMobile ? 20 : isTablet ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),

          // Upload Form Section
          _buildUploadForm(isMobile, isTablet, isDesktop),
          SizedBox(height: isMobile ? 32 : isTablet ? 36 : 40),

          // Excel Format Instructions
          _buildExcelFormatInstructions(isMobile, isTablet, isDesktop),
          SizedBox(height: isMobile ? 32 : isTablet ? 36 : 40),

          // Question Papers List
          _buildQuestionPapersList(isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildUploadForm(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.cardBackground,
        borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
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
                  padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
                  ),
                  child: Icon(
                    Icons.upload_rounded,
                    color: Colors.green,
                    size: isMobile ? 18 : isTablet ? 19 : 20,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                Text(
                  'Upload New Question Paper',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AdminDashboardStyles.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 20 : isTablet ? 22 : 24),

            // Question Paper Type
            _buildFormField(
              label: 'Question Paper Type *',
              icon: Icons.category_rounded,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
              child: DropdownButtonFormField<String>(
                value: _selectedQuestionPaperType,
                isExpanded: true,
                style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                decoration: _buildInputDecoration(
                  hintText: 'Select type',
                  prefixIconData: Icons.category_rounded,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'course',
                    child: Text(
                      'Course',
                      style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'tega-exam',
                    child: Text(
                      'TEGA Exam',
                      style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                    ),
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
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),

            // Course
            _buildFormField(
              label: 'Course *',
              icon: Icons.school_rounded,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
              child: _isLoadingCourses
                  ? SizedBox(
                      height: isMobile ? 50 : isTablet ? 53 : 56,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AdminDashboardStyles.primary),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      isExpanded: true,
                      style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                      decoration: _buildInputDecoration(
                        hintText: 'Select a course',
                        prefixIconData: Icons.school_rounded,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      items: _availableCourses.map((course) {
                        final courseId = course['_id']?.toString() ?? course['id']?.toString();
                        return DropdownMenuItem(
                          value: courseId,
                          child: Text(
                            course['title'] ?? course['courseName'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
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
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),

            // Description
            _buildFormField(
              label: 'Description',
              icon: Icons.description_rounded,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                decoration: _buildInputDecoration(
                  hintText: 'Brief description of the question paper',
                  prefixIconData: Icons.description_rounded,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : isTablet ? 22 : 24),

            // Upload Method
            Text(
              'Upload Method',
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textDark,
              ),
            ),
            SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
            Row(
              children: [
                Expanded(
                  child: _buildMethodButton(
                    label: 'Manual Entry',
                    isSelected: _uploadMethod == 'manual',
                    onTap: () => setState(() => _uploadMethod = 'manual'),
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                Expanded(
                  child: _buildMethodButton(
                    label: 'Excel Upload',
                    isSelected: _uploadMethod == 'excel',
                    onTap: () => setState(() => _uploadMethod = 'excel'),
                    color: Colors.green,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : isTablet ? 18 : 20),

            // File Upload (only for Excel)
            if (_uploadMethod == 'excel') ...[
              _buildFormField(
                label: 'Upload Excel File *',
                icon: Icons.file_upload_rounded,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
                child: InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : isTablet ? 15 : 16,
                      vertical: isMobile ? 14 : isTablet ? 15 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : isTablet ? 14 : 16,
                              vertical: isMobile ? 10 : isTablet ? 12 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                            ),
                          ),
                          child: Text(
                            'Choose File',
                            style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : isTablet ? 14 : 16),
                        Expanded(
                          child: Text(
                            _fileName ?? 'No file chosen',
                            style: TextStyle(
                              color: _fileName != null
                                  ? AdminDashboardStyles.textDark
                                  : Colors.grey[600],
                              fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Only Excel files (.xlsx, .xls) are allowed.',
                style: TextStyle(
                  fontSize: isMobile ? 11 : isTablet ? 11.5 : 12,
                  color: AdminDashboardStyles.textLight,
                ),
              ),
            ] else ...[
              // Manual Entry UI
              _buildFormField(
                label: 'Question',
                icon: Icons.help_outline_rounded,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
                child: TextFormField(
                  controller: _qController,
                  maxLines: 3,
                  style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your question here...',
                    prefixIconData: Icons.edit_note_rounded,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              // Options A and B
              isMobile
                  ? Column(
                      children: [
                        _buildFormField(
                          label: 'Option A',
                          icon: Icons.circle_outlined,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                          child: TextFormField(
                            controller: _optAController,
                            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                            decoration: _buildInputDecoration(
                              hintText: 'Option A',
                              prefixIconData: Icons.circle_outlined,
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                        _buildFormField(
                          label: 'Option B',
                          icon: Icons.circle_outlined,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                          child: TextFormField(
                            controller: _optBController,
                            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                            decoration: _buildInputDecoration(
                              hintText: 'Option B',
                              prefixIconData: Icons.circle_outlined,
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Option A',
                            icon: Icons.circle_outlined,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                            child: TextFormField(
                              controller: _optAController,
                              style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                              decoration: _buildInputDecoration(
                                hintText: 'Option A',
                                prefixIconData: Icons.circle_outlined,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isDesktop: isDesktop,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Option B',
                            icon: Icons.circle_outlined,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                            child: TextFormField(
                              controller: _optBController,
                              style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                              decoration: _buildInputDecoration(
                                hintText: 'Option B',
                                prefixIconData: Icons.circle_outlined,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isDesktop: isDesktop,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              isMobile
                  ? Column(
                      children: [
                        _buildFormField(
                          label: 'Option C',
                          icon: Icons.circle_outlined,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                          child: TextFormField(
                            controller: _optCController,
                            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                            decoration: _buildInputDecoration(
                              hintText: 'Option C',
                              prefixIconData: Icons.circle_outlined,
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                        _buildFormField(
                          label: 'Option D',
                          icon: Icons.circle_outlined,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                          child: TextFormField(
                            controller: _optDController,
                            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                            decoration: _buildInputDecoration(
                              hintText: 'Option D',
                              prefixIconData: Icons.circle_outlined,
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Option C',
                            icon: Icons.circle_outlined,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                            child: TextFormField(
                              controller: _optCController,
                              style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                              decoration: _buildInputDecoration(
                                hintText: 'Option C',
                                prefixIconData: Icons.circle_outlined,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isDesktop: isDesktop,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 10 : isTablet ? 11 : 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Option D',
                            icon: Icons.circle_outlined,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                            child: TextFormField(
                              controller: _optDController,
                              style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                              decoration: _buildInputDecoration(
                                hintText: 'Option D',
                                prefixIconData: Icons.circle_outlined,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isDesktop: isDesktop,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              _buildFormField(
                label: 'Correct Answer',
                icon: Icons.check_circle_rounded,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
                child: DropdownButtonFormField<String>(
                  value: _correctAnswer,
                  isExpanded: true,
                  style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                  decoration: _buildInputDecoration(
                    hintText: 'Select correct answer',
                    prefixIconData: Icons.check_circle_rounded,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                  items: ['A', 'B', 'C', 'D']
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _correctAnswer = v ?? 'A'),
                ),
              ),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addManualQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : isTablet ? 15 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
                    ),
                  ),
                  child: Text(
                    'Add Question',
                    style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              if (_manualQuestions.isNotEmpty) _buildManualQuestionsPreview(isMobile, isTablet, isDesktop),
            ],

            SizedBox(height: isMobile ? 20 : isTablet ? 22 : 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadQuestionPaper,
                icon: _isLoading
                    ? SizedBox(
                        width: isMobile ? 18 : isTablet ? 19 : 20,
                        height: isMobile ? 18 : isTablet ? 19 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.upload_rounded,
                        size: isMobile ? 18 : isTablet ? 19 : 20,
                      ),
                label: Text(
                  _isLoading ? 'Uploading...' : 'Upload',
                  style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
                ),
                style: AdminDashboardStyles.getPrimaryButtonStyle().copyWith(
                  padding: MaterialStatePropertyAll(
                    EdgeInsets.symmetric(vertical: isMobile ? 14 : isTablet ? 15 : 16),
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

  Widget _buildManualQuestionsPreview(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Added Questions (${_manualQuestions.length})',
            style: TextStyle(
              fontSize: isMobile ? 14 : isTablet ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
          ..._manualQuestions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: isMobile ? 6 : isTablet ? 7 : 8),
              padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Text(
                          'Correct: ${q['correct']}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: isMobile ? 18 : isTablet ? 20 : 22,
                    ),
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
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : isTablet ? 11 : 12,
          horizontal: isMobile ? 12 : isTablet ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
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
              fontSize: isMobile ? 13 : isTablet ? 14 : 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExcelFormatInstructions(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
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
              fontSize: isMobile ? 16 : isTablet ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
          Text(
            'Your Excel file must contain these exact column headers:',
            style: TextStyle(
              fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
              color: AdminDashboardStyles.textDark,
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Wrap(
              spacing: isMobile ? 8 : isTablet ? 10 : 12,
              runSpacing: isMobile ? 6 : isTablet ? 7 : 8,
              children: [
                _buildColumnHeader('sno', isMobile, isTablet, isDesktop),
                _buildColumnHeader('question', isMobile, isTablet, isDesktop),
                _buildColumnHeader('optionA', isMobile, isTablet, isDesktop),
                _buildColumnHeader('optionB', isMobile, isTablet, isDesktop),
                _buildColumnHeader('optionC', isMobile, isTablet, isDesktop),
                _buildColumnHeader('optionD', isMobile, isTablet, isDesktop),
                _buildColumnHeader('correct', isMobile, isTablet, isDesktop),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('Each question gets 1 mark for correct answer, 0 for wrong', isMobile, isTablet, isDesktop),
              _buildBulletPoint("'correct' column should contain A, B, C, or D", isMobile, isTablet, isDesktop),
              _buildBulletPoint('Save your file as .xlsx or .xls format', isMobile, isTablet, isDesktop),
              _buildBulletPoint(
                'Sample data: sno=1, question="What is 2+2?", optionA="3", optionB="4", optionC="5", optionD="6", correct="B"',
                isMobile,
                isTablet,
                isDesktop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String header, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : isTablet ? 10 : 12,
        vertical: isMobile ? 6 : isTablet ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(isMobile ? 4 : isTablet ? 5 : 6),
      ),
      child: Text(
        header,
        style: TextStyle(
          fontSize: isMobile ? 10 : isTablet ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue[900],
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isMobile, bool isTablet, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6 : isTablet ? 7 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 12 : isTablet ? 12.5 : 13,
                color: AdminDashboardStyles.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPapersList(bool isMobile, bool isTablet, bool isDesktop) {
    if (_isLoadingPapers) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminDashboardStyles.primary),
          ),
        ),
      );
    }

    if (_questionPapers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 28 : 32),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
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
                size: isMobile ? 48 : isTablet ? 56 : 64,
                color: AdminDashboardStyles.primary.withOpacity(0.5),
              ),
              SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
              Text(
                'No question papers found',
                style: TextStyle(
                  fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardStyles.textDark,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Upload your first question paper to get started',
                style: TextStyle(
                  fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                  color: AdminDashboardStyles.textLight,
                ),
                textAlign: TextAlign.center,
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
            fontSize: isMobile ? 18 : isTablet ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: AdminDashboardStyles.textDark,
          ),
        ),
        SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
        isMobile
            ? Column(
                children: _questionPapers.map((paper) => _buildQuestionPaperCard(paper, true, isMobile, isTablet, isDesktop)).toList(),
              )
            : Wrap(
                spacing: isMobile ? 12 : isTablet ? 14 : 16,
                runSpacing: isMobile ? 12 : isTablet ? 14 : 16,
                children: _questionPapers.map((paper) => _buildQuestionPaperCard(paper, false, isMobile, isTablet, isDesktop)).toList(),
              ),
      ],
    );
  }

  Widget _buildQuestionPaperCard(Map<String, dynamic> paper, bool isFullWidth, bool isMobile, bool isTablet, bool isDesktop) {
    final name = paper['name'] ?? 'Unknown';
    final description = paper['description'] ?? 'No description provided';
    final questionCount = paper['questionCount'] ?? 0;
    final isTegaExam = paper['isTegaExamPaper'] == true;
    final usedByExams = paper['usedByExams'] as List<dynamic>? ?? [];

    return Container(
      width: isFullWidth ? double.infinity : (isMobile ? double.infinity : isTablet ? 320 : 350),
      padding: EdgeInsets.all(isMobile ? 16 : isTablet ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : isTablet ? 15 : 16),
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
                size: isMobile ? 18 : isTablet ? 19 : 20,
              ),
              SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : isTablet ? 17 : 18,
                    fontWeight: FontWeight.bold,
                    color: AdminDashboardStyles.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: isMobile ? 18 : isTablet ? 20 : 22,
                ),
                onPressed: () => _deleteQuestionPaper(paper['_id'] ?? paper['id']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),

          // Type tag
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : isTablet ? 11 : 12,
              vertical: isMobile ? 4 : isTablet ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 16 : isTablet ? 18 : 20),
            ),
            child: Text(
              isTegaExam ? 'TEGA Exam' : 'Course',
              style: TextStyle(
                fontSize: isMobile ? 10 : isTablet ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
              color: AdminDashboardStyles.textLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),

          // Question count
          Text(
            'Questions: $questionCount',
            style: TextStyle(
              fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
              fontWeight: FontWeight.w600,
              color: AdminDashboardStyles.textDark,
            ),
          ),

          // Used by exams warning
          if (usedByExams.isNotEmpty) ...[
            SizedBox(height: isMobile ? 10 : isTablet ? 11 : 12),
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: isMobile ? 16 : isTablet ? 17 : 18,
                  ),
                  SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Used by ${usedByExams.length} exam(s)',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : isTablet ? 11.5 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                        ...usedByExams.take(2).map((exam) => Text(
                              exam['title'] ?? exam['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : isTablet ? 10.5 : 11,
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

          SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),

          // Action buttons
          isMobile
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View functionality coming soon')),
                          );
                        },
                        icon: Icon(Icons.visibility_rounded, size: isMobile ? 16 : isTablet ? 17 : 18),
                        label: Text(
                          'View',
                          style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminDashboardStyles.primary,
                          side: BorderSide(color: AdminDashboardStyles.primary),
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : isTablet ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : isTablet ? 10 : 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download functionality coming soon')),
                          );
                        },
                        icon: Icon(Icons.download_rounded, size: isMobile ? 16 : isTablet ? 17 : 18),
                        label: Text(
                          'Download',
                          style: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminDashboardStyles.primary,
                          side: BorderSide(color: AdminDashboardStyles.primary),
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : isTablet ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View functionality coming soon')),
                          );
                        },
                        icon: Icon(Icons.visibility_rounded, size: isTablet ? 17 : 18),
                        label: Text(
                          'View',
                          style: TextStyle(fontSize: isTablet ? 14 : 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminDashboardStyles.primary,
                          side: BorderSide(color: AdminDashboardStyles.primary),
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 9 : 10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 10 : 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download functionality coming soon')),
                          );
                        },
                        icon: Icon(Icons.download_rounded, size: isTablet ? 17 : 18),
                        label: Text(
                          'Download',
                          style: TextStyle(fontSize: isTablet ? 14 : 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminDashboardStyles.primary,
                          side: BorderSide(color: AdminDashboardStyles.primary),
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 9 : 10),
                          ),
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
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: isMobile ? 14 : isTablet ? 15 : 16,
                color: AdminDashboardStyles.primary,
              ),
              SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 13 : isTablet ? 13.5 : 14,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardStyles.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : isTablet ? 9 : 10),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIconData,
    Widget? suffixIcon,
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: isMobile ? 13 : isTablet ? 14 : 15,
      ),
      prefixIcon: prefixIconData != null
          ? Container(
              margin: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
              padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 7 : 8),
              decoration: BoxDecoration(
                color: AdminDashboardStyles.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
              ),
              child: Icon(
                prefixIconData,
                color: AdminDashboardStyles.primary,
                size: isMobile ? 16 : isTablet ? 17 : 18,
              ),
            )
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        borderSide: BorderSide(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        borderSide: BorderSide(
          color: AdminDashboardStyles.borderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        borderSide: BorderSide(
          color: AdminDashboardStyles.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : isTablet ? 15 : 16,
        vertical: isMobile ? 14 : isTablet ? 15 : 16,
      ),
    );
  }
}

