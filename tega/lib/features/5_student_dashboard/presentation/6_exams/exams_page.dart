import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/core/services/exams_cache_service.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courseExams = [];
  List<Map<String, dynamic>> _filteredExams = [];
  Map<String, dynamic>? _tegaMainExam;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Exams';
  String? _errorMessage;
  final ExamsCacheService _cacheService = ExamsCacheService();

  final List<String> _filters = ['All Exams', 'Course Exams', 'Normal Exams'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initializeCache();
    _animationController.forward();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadExams();
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

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      // Combine all exams (course exams + TEGA exam if available)
      List<Map<String, dynamic>> allExams = List.from(_courseExams);
      if (_tegaMainExam != null) {
        allExams.add(_tegaMainExam!);
      }

      _filteredExams = allExams.where((exam) {
        // Search filter
        final matchesSearch =
            exam['title'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            exam['courseName'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        if (!matchesSearch) return false;

        // Type filter
        final isTegaExam =
            exam['courseName'] == 'TEGA Exam' ||
            exam['_backendData']?['isTegaExam'] == true ||
            (exam['_backendData']?['courseId'] == null ||
                exam['_backendData']?['courseId'].toString() == 'null');
        final isCourseExam = !isTegaExam;

        final matchesFilter =
            _selectedFilter == 'All Exams' ||
            (_selectedFilter == 'Course Exams' && isCourseExam) ||
            (_selectedFilter == 'Normal Exams' && isTegaExam);

        return matchesFilter;
      }).toList();
    });
  }

  Future<void> _loadExams({bool forceRefresh = false}) async {
    try {
      setState(() {
        _errorMessage = null;
      });

      // Try to load from cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedExams = await _cacheService.getExamsData();
        if (cachedExams != null && cachedExams.isNotEmpty && mounted) {
          setState(() {
            _courseExams = cachedExams;
            _isLoading = false;
            _errorMessage = null;
          });
          // Apply filters after loading from cache
          _applyFilters();
          // Still fetch in background to update cache
          _fetchExamsInBackground();
          return;
        }
      }

      // Fetch from API
      await _fetchExamsInBackground();
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedExams = await _cacheService.getExamsData();
          if (cachedExams != null && cachedExams.isNotEmpty) {
            setState(() {
              _courseExams = cachedExams;
              _isLoading = false;
              _errorMessage = null; // Clear error since we have cached data
            });
            _applyFilters();
            return;
          }
          // No cache available, show error
          setState(() {
            _errorMessage = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fetchExamsInBackground() async {
    try {
      final auth = AuthService();
      final studentId = auth.currentUser?.id;

      if (studentId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();

      // Fetch available exams from backend
      final backendExams = await api.getAvailableExams(studentId, headers);

      // Separate TEGA exams from course exams
      Map<String, dynamic>? tegaMainExam;
      List<Map<String, dynamic>> courseExams = [];

      // Transform backend exam data to UI format
      for (final exam in backendExams) {
        final examData = exam as Map<String, dynamic>;

        // Check if this is a TEGA exam
        final isTegaExam =
            examData['isTegaExam'] == true ||
            examData['courseId'] == null ||
            (examData['courseId'] is String &&
                examData['courseId'].toString() == 'null');

        // Get course name
        String courseName = 'TEGA Exam';
        if (examData['courseId'] != null) {
          if (examData['courseId'] is Map) {
            courseName = examData['courseId']['courseName'] ?? 'Course Exam';
          } else if (examData['courseId'] is String &&
              examData['courseId'].toString() != 'null') {
            courseName = 'Course Exam';
          }
        }

        // Format duration
        final durationMinutes = examData['duration'] ?? 120;
        String durationText = '${durationMinutes} min';
        if (durationMinutes >= 60) {
          final hours = durationMinutes ~/ 60;
          final minutes = durationMinutes % 60;
          if (minutes == 0) {
            durationText = '$hours ${hours == 1 ? 'hour' : 'hours'}';
          } else {
            durationText = '$hours h $minutes min';
          }
        }

        // Get total questions
        int totalQuestions = 0;
        if (examData['questionPaperId'] != null) {
          if (examData['questionPaperId'] is Map) {
            totalQuestions = examData['questionPaperId']['totalQuestions'] ?? 0;
          }
        }
        final questionsText = totalQuestions > 0
            ? '$totalQuestions ${totalQuestions == 1 ? 'question' : 'questions'}'
            : 'Questions TBD';

        // Determine difficulty based on exam data
        String difficulty = 'Intermediate';
        if (examData['totalMarks'] != null &&
            examData['passingMarks'] != null) {
          final totalMarks = examData['totalMarks'] as num;
          final passingMarks = examData['passingMarks'] as num;
          final passingPercentage = (passingMarks / totalMarks) * 100;
          if (passingPercentage >= 80) {
            difficulty = 'Hard';
          } else if (passingPercentage >= 60) {
            difficulty = 'Intermediate';
          } else {
            difficulty = 'Easy';
          }
        }

        // Get category from subject or course
        String category =
            examData['subject']?.toString() ??
            examData['courseId']?['courseName']?.toString() ??
            'General';

        // Get attempts from registration if available
        int attempts = 0;
        if (examData['registration'] != null) {
          // Check if there are any exam attempts
          attempts = examData['registration']['attempts'] ?? 0;
        }

        final transformedExam = {
          'id': examData['_id']?.toString() ?? '',
          'title': examData['title']?.toString() ?? 'Untitled Exam',
          'courseName': courseName,
          'duration': durationText,
          'questions': questionsText,
          'difficulty': difficulty,
          'category': category,
          'attempts': attempts,
          'maxAttempts': examData['maxAttempts'] ?? 3,
          'passingScore':
              examData['passingMarks'] != null && examData['totalMarks'] != null
              ? ((examData['passingMarks'] as num) /
                        (examData['totalMarks'] as num) *
                        100)
                    .round()
              : 70,
          // Store additional backend data for later use
          '_backendData': examData,
        };

        // Separate TEGA main exam from course exams
        if (isTegaExam) {
          tegaMainExam = transformedExam;
        } else {
          courseExams.add(transformedExam);
        }
      }

      // Cache exams data (only course exams, TEGA exam is separate)
      await _cacheService.setExamsData(courseExams);

      if (mounted) {
        setState(() {
          _tegaMainExam = tegaMainExam;
          _courseExams = courseExams;
          _isLoading = false;
          _errorMessage = null;
        });
        // Apply filters after loading exams
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedExams = await _cacheService.getExamsData();
          if (cachedExams != null && cachedExams.isNotEmpty) {
            setState(() {
              _courseExams = cachedExams;
              _isLoading = false;
              _errorMessage = null; // Clear error since we have cached data
            });
            _applyFilters();
            return;
          }
          // No cache available, show error
          setState(() {
            _errorMessage = 'No internet connection';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleStartExam(Map<String, dynamic> exam) async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final api = StudentDashboardService();
      final examId = exam['id'] as String;

      if (examId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid exam ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get backend data
      final backendData = exam['_backendData'] as Map<String, dynamic>?;
      if (backendData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Exam data not available. Please refresh and try again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if already registered
      final isRegistered = backendData['isRegistered'] == true;
      String? slotId;

      // If not registered, register first
      if (!isRegistered) {
        // Get available slots
        final availableSlots = backendData['availableSlots'] as List<dynamic>?;
        if (availableSlots == null || availableSlots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No available slots for this exam'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Use the first available slot
        final firstSlot = availableSlots.first as Map<String, dynamic>;
        slotId = firstSlot['slotId']?.toString();

        if (slotId == null || slotId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid slot information'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
          ),
        );

        // Register for exam
        final registerResult = await api.registerForExam(
          examId,
          slotId,
          headers,
        );

        Navigator.of(context).pop(); // Close loading dialog

        if (registerResult['success'] != true) {
          final message =
              registerResult['message'] ?? 'Failed to register for exam';

          // Check if payment is required
          if (registerResult['requiresPayment'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
        ),
      );

      // Start exam
      final startResult = await api.startExam(examId, headers);

      Navigator.of(context).pop(); // Close loading dialog

      if (startResult['success'] == true) {
        // Navigate to exam page (you'll need to create this page)
        // For now, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting ${exam['title']}...'),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Navigate to actual exam page
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ExamTakingPage(examId: examId),
        //   ),
        // );
      } else {
        final message = startResult['message'] ?? 'Failed to start exam';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
      );
    }

    if (_errorMessage != null &&
        _courseExams.isEmpty &&
        _tegaMainExam == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Main Exam Section (only show if TEGA exam is available)
          if (_tegaMainExam != null) ...[_buildMainExamSection()],

          // Course Exams Section
          if (_courseExams.isNotEmpty) ...[
            _buildCourseExamsSection(),
          ] else ...[
            _buildNoCourseExamsSection(),
          ],

          // Bottom Spacing
          SliverToBoxAdapter(
            child: SizedBox(
              height: isLargeDesktop
                  ? 48
                  : isDesktop
                  ? 40
                  : isTablet
                  ? 32
                  : isSmallScreen
                  ? 20
                  : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isNoInternet = _errorMessage == 'No internet connection';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(
            isLargeDesktop
                ? 40
                : isDesktop
                ? 32
                : isTablet
                ? 28
                : isSmallScreen
                ? 20
                : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: isLargeDesktop
                    ? 80
                    : isDesktop
                    ? 72
                    : isTablet
                    ? 64
                    : isSmallScreen
                    ? 48
                    : 56,
                color: Colors.grey[400],
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Text(
                isNoInternet
                    ? 'No internet connection'
                    : 'Something went wrong',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 15
                      : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              if (isNoInternet) ...[
                SizedBox(
                  height: isLargeDesktop
                      ? 12
                      : isDesktop
                      ? 10
                      : isTablet
                      ? 9
                      : isSmallScreen
                      ? 8
                      : 8,
                ),
                Text(
                  'Please check your connection and try again',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 13
                        : isTablet
                        ? 12.5
                        : isSmallScreen
                        ? 11
                        : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(
                height: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _loadExams(forceRefresh: true);
                },
                icon: Icon(
                  Icons.refresh,
                  size: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 19
                      : isSmallScreen
                      ? 16
                      : 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 15
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 12
                        : 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5FFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 12
                        : 16,
                    vertical: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 8
                        : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 10
                          : isTablet
                          ? 9
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainExamSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Exam',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),
            _buildModernMainExam(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMainExam() {
    // If no TEGA main exam, don't show the section
    if (_tegaMainExam == null) {
      return const SizedBox.shrink();
    }

    final exam = _tegaMainExam!;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B5FFF),
                    Color(0xFF8F7FFF),
                    Color(0xFFB39DFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B5FFF).withOpacity(0.3),
                    blurRadius: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 10
                        : 16,
                    offset: Offset(
                      0,
                      isLargeDesktop
                          ? 10
                          : isDesktop
                          ? 8
                          : isTablet
                          ? 7
                          : isSmallScreen
                          ? 4
                          : 6,
                    ),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showMainExamDialog(context, exam),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 20
                        : isTablet
                        ? 18
                        : isSmallScreen
                        ? 12
                        : 16,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      isLargeDesktop
                          ? 32
                          : isDesktop
                          ? 28
                          : isTablet
                          ? 26
                          : isSmallScreen
                          ? 16
                          : 24,
                    ),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(
                                isLargeDesktop
                                    ? 20
                                    : isDesktop
                                    ? 16
                                    : isTablet
                                    ? 14
                                    : isSmallScreen
                                    ? 10
                                    : 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  isLargeDesktop
                                      ? 20
                                      : isDesktop
                                      ? 16
                                      : isTablet
                                      ? 14
                                      : isSmallScreen
                                      ? 10
                                      : 12,
                                ),
                              ),
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: isLargeDesktop
                                    ? 40
                                    : isDesktop
                                    ? 32
                                    : isTablet
                                    ? 30
                                    : isSmallScreen
                                    ? 22
                                    : 28,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: isLargeDesktop
                                  ? 20
                                  : isDesktop
                                  ? 16
                                  : isTablet
                                  ? 14
                                  : isSmallScreen
                                  ? 8
                                  : 12,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam['title'] ?? 'Tega Main Exam',
                                    style: TextStyle(
                                      fontSize: isLargeDesktop
                                          ? 28
                                          : isDesktop
                                          ? 24
                                          : isTablet
                                          ? 22
                                          : isSmallScreen
                                          ? 18
                                          : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: isLargeDesktop || isDesktop
                                        ? 2
                                        : isTablet
                                        ? 2
                                        : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    height: isLargeDesktop || isDesktop
                                        ? 6
                                        : isTablet
                                        ? 5
                                        : isSmallScreen
                                        ? 2
                                        : 4,
                                  ),
                                  Text(
                                    exam['_backendData']?['description']
                                            ?.toString() ??
                                        'Comprehensive assessment across all domains',
                                    style: TextStyle(
                                      fontSize: isLargeDesktop
                                          ? 16
                                          : isDesktop
                                          ? 15
                                          : isTablet
                                          ? 14
                                          : isSmallScreen
                                          ? 11
                                          : 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: isLargeDesktop || isDesktop
                                        ? 2
                                        : isTablet
                                        ? 2
                                        : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeDesktop
                                    ? 14
                                    : isDesktop
                                    ? 12
                                    : isTablet
                                    ? 11
                                    : isSmallScreen
                                    ? 7
                                    : 8,
                                vertical: isLargeDesktop
                                    ? 8
                                    : isDesktop
                                    ? 6
                                    : isTablet
                                    ? 5.5
                                    : isSmallScreen
                                    ? 3
                                    : 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  isLargeDesktop
                                      ? 10
                                      : isDesktop
                                      ? 8
                                      : isTablet
                                      ? 7
                                      : isSmallScreen
                                      ? 5
                                      : 6,
                                ),
                              ),
                              child: Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: isLargeDesktop
                                      ? 14
                                      : isDesktop
                                      ? 13
                                      : isTablet
                                      ? 12
                                      : isSmallScreen
                                      ? 9
                                      : 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: isLargeDesktop
                              ? 28
                              : isDesktop
                              ? 24
                              : isTablet
                              ? 22
                              : isSmallScreen
                              ? 14
                              : 20,
                        ),

                        // Features
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernFeatureCard(
                                icon: Icons.library_books_rounded,
                                title: exam['questions'] ?? 'Questions TBD',
                                subtitle: 'Total questions',
                              ),
                            ),
                            SizedBox(
                              width: isLargeDesktop
                                  ? 16
                                  : isDesktop
                                  ? 12
                                  : isTablet
                                  ? 11
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            Expanded(
                              child: _buildModernFeatureCard(
                                icon: Icons.timer_rounded,
                                title: exam['duration'] ?? 'Duration TBD',
                                subtitle: 'Exam duration',
                              ),
                            ),
                            SizedBox(
                              width: isLargeDesktop
                                  ? 16
                                  : isDesktop
                                  ? 12
                                  : isTablet
                                  ? 11
                                  : isSmallScreen
                                  ? 6
                                  : 8,
                            ),
                            Expanded(
                              child: _buildModernFeatureCard(
                                icon: Icons.emoji_events_rounded,
                                title: 'Certificate',
                                subtitle: 'Master certification',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: isLargeDesktop
                              ? 28
                              : isDesktop
                              ? 24
                              : isTablet
                              ? 22
                              : isSmallScreen
                              ? 14
                              : 20,
                        ),

                        // Start Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(
                              isLargeDesktop
                                  ? 14
                                  : isDesktop
                                  ? 12
                                  : isTablet
                                  ? 11
                                  : isSmallScreen
                                  ? 8
                                  : 10,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                blurRadius: isLargeDesktop
                                    ? 16
                                    : isDesktop
                                    ? 12
                                    : isTablet
                                    ? 11
                                    : isSmallScreen
                                    ? 6
                                    : 8,
                                offset: Offset(
                                  0,
                                  isLargeDesktop
                                      ? 6
                                      : isDesktop
                                      ? 4
                                      : isTablet
                                      ? 3
                                      : isSmallScreen
                                      ? 2
                                      : 3,
                                ),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_tegaMainExam != null) {
                                  _showMainExamDialog(context, _tegaMainExam!);
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                isLargeDesktop
                                    ? 14
                                    : isDesktop
                                    ? 12
                                    : isTablet
                                    ? 11
                                    : isSmallScreen
                                    ? 8
                                    : 10,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLargeDesktop
                                      ? 28
                                      : isDesktop
                                      ? 24
                                      : isTablet
                                      ? 22
                                      : isSmallScreen
                                      ? 14
                                      : 20,
                                  vertical: isLargeDesktop
                                      ? 18
                                      : isDesktop
                                      ? 16
                                      : isTablet
                                      ? 15
                                      : isSmallScreen
                                      ? 10
                                      : 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.black87,
                                      size: isLargeDesktop
                                          ? 28
                                          : isDesktop
                                          ? 24
                                          : isTablet
                                          ? 22
                                          : isSmallScreen
                                          ? 18
                                          : 20,
                                    ),
                                    SizedBox(
                                      width: isLargeDesktop
                                          ? 12
                                          : isDesktop
                                          ? 8
                                          : isTablet
                                          ? 7
                                          : isSmallScreen
                                          ? 4
                                          : 6,
                                    ),
                                    Text(
                                      'Start Tega Main Exam',
                                      style: TextStyle(
                                        fontSize: isLargeDesktop
                                            ? 18
                                            : isDesktop
                                            ? 16
                                            : isTablet
                                            ? 15
                                            : isSmallScreen
                                            ? 12
                                            : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: isLargeDesktop
          ? 140
          : isDesktop
          ? 120
          : isTablet
          ? 110
          : isSmallScreen
          ? 90
          : 100,
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 20
            : isDesktop
            ? 16
            : isTablet
            ? 14
            : isSmallScreen
            ? 10
            : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 16
              : isDesktop
              ? 12
              : isTablet
              ? 11
              : isSmallScreen
              ? 8
              : 10,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isLargeDesktop
                ? 32
                : isDesktop
                ? 24
                : isTablet
                ? 22
                : isSmallScreen
                ? 18
                : 20,
            color: const Color(0xFFFFD700),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 10
                : isDesktop
                ? 8
                : isTablet
                ? 7
                : isSmallScreen
                ? 4
                : 6,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 11
                  : 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 4
                : isDesktop
                ? 3
                : isTablet
                ? 2.5
                : isSmallScreen
                ? 1
                : 2,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 13
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 9
                  : 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseExamsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course Exams',
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 28
                        : isDesktop
                        ? 24
                        : isTablet
                        ? 22
                        : isSmallScreen
                        ? 18
                        : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 14
                        : isDesktop
                        ? 12
                        : isTablet
                        ? 11
                        : isSmallScreen
                        ? 7
                        : 8,
                    vertical: isLargeDesktop
                        ? 8
                        : isDesktop
                        ? 6
                        : isTablet
                        ? 5.5
                        : isSmallScreen
                        ? 3
                        : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5FFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 10
                          : isDesktop
                          ? 8
                          : isTablet
                          ? 7
                          : isSmallScreen
                          ? 5
                          : 6,
                    ),
                  ),
                  child: Text(
                    '${_filteredExams.length} exams',
                    style: TextStyle(
                      fontSize: isLargeDesktop
                          ? 14
                          : isDesktop
                          ? 13
                          : isTablet
                          ? 12
                          : isSmallScreen
                          ? 9
                          : 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B5FFF),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 10
                  : 12,
            ),

            // Search and Filters
            _buildModernSearchAndFilters(),
            SizedBox(
              height: isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
            ),

            // Exams List
            _filteredExams.isNotEmpty
                ? _buildModernCourseExams()
                : _buildNoResultsFound(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchAndFilters() {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 8
                    : isTablet
                    ? 7
                    : isSmallScreen
                    ? 4
                    : 6,
                offset: Offset(
                  0,
                  isLargeDesktop
                      ? 3
                      : isDesktop
                      ? 2
                      : isTablet
                      ? 2
                      : isSmallScreen
                      ? 1
                      : 2,
                ),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 15
                  : isSmallScreen
                  ? 12
                  : 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search exams...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isLargeDesktop
                    ? 18
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : isSmallScreen
                    ? 12
                    : 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF6B5FFF),
                size: isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 12
                    : 16,
                vertical: isLargeDesktop
                    ? 18
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : isSmallScreen
                    ? 10
                    : 14,
              ),
            ),
          ),
        ),
        SizedBox(
          height: isLargeDesktop
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 14
              : isSmallScreen
              ? 10
              : 12,
        ),

        // Category Filters
        SizedBox(
          height: isLargeDesktop
              ? 52
              : isDesktop
              ? 48
              : isTablet
              ? 46
              : isSmallScreen
              ? 38
              : 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: EdgeInsets.only(
                  right: isLargeDesktop
                      ? 12
                      : isDesktop
                      ? 10
                      : isTablet
                      ? 9
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B5FFF) : Colors.white,
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 10
                          : isTablet
                          ? 9
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6B5FFF)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: isLargeDesktop
                            ? 8
                            : isDesktop
                            ? 6
                            : isTablet
                            ? 5
                            : isSmallScreen
                            ? 3
                            : 4,
                        offset: Offset(
                          0,
                          isLargeDesktop
                              ? 3
                              : isDesktop
                              ? 2
                              : isTablet
                              ? 2
                              : isSmallScreen
                              ? 1
                              : 2,
                        ),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 12
                            : isDesktop
                            ? 10
                            : isTablet
                            ? 9
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeDesktop
                              ? 18
                              : isDesktop
                              ? 16
                              : isTablet
                              ? 15
                              : isSmallScreen
                              ? 10
                              : 12,
                          vertical: isLargeDesktop
                              ? 12
                              : isDesktop
                              ? 10
                              : isTablet
                              ? 9.5
                              : isSmallScreen
                              ? 6
                              : 8,
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 15
                                : isTablet
                                ? 14
                                : isSmallScreen
                                ? 11
                                : 13,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernCourseExams() {
    return Column(
      children: _filteredExams.map((exam) {
        final index = _filteredExams.indexOf(exam);
        final delay = index * 100;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + delay),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: index == _filteredExams.length - 1
                        ? 0
                        : (isLargeDesktop
                              ? 20
                              : isDesktop
                              ? 16
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 10
                              : 12),
                  ),
                  child: _buildModernExamCard(exam),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildModernExamCard(Map<String, dynamic> exam) {
    Color getDifficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'easy':
        case 'beginner':
          return const Color(0xFF4CAF50);
        case 'medium':
        case 'intermediate':
          return const Color(0xFFFF9800);
        case 'hard':
        case 'advanced':
          return const Color(0xFFF44336);
        default:
          return const Color(0xFF6B5FFF);
      }
    }

    final difficultyColor = getDifficultyColor(exam['difficulty']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 16
              : isTablet
              ? 14
              : isSmallScreen
              ? 10
              : 12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 16
                : isDesktop
                ? 12
                : isTablet
                ? 10
                : isSmallScreen
                ? 6
                : 8,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 6
                  : isDesktop
                  ? 4
                  : isTablet
                  ? 3
                  : isSmallScreen
                  ? 2
                  : 2,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExamDialog(context, exam),
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 20
                : isDesktop
                ? 16
                : isTablet
                ? 14
                : isSmallScreen
                ? 10
                : 12,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(
                    isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6B5FFF),
                        const Color(0xFF8F7FFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 12
                          : isTablet
                          ? 11
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    size: isLargeDesktop
                        ? 36
                        : isDesktop
                        ? 28
                        : isTablet
                        ? 26
                        : isSmallScreen
                        ? 20
                        : 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : isSmallScreen
                      ? 8
                      : 12,
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exam['title'],
                              style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 22
                                    : isDesktop
                                    ? 20
                                    : isTablet
                                    ? 18
                                    : isSmallScreen
                                    ? 14
                                    : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: isLargeDesktop || isDesktop
                                  ? 2
                                  : isTablet
                                  ? 2
                                  : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeDesktop
                                  ? 10
                                  : isDesktop
                                  ? 8
                                  : isTablet
                                  ? 7
                                  : isSmallScreen
                                  ? 5
                                  : 6,
                              vertical: isLargeDesktop
                                  ? 6
                                  : isDesktop
                                  ? 4
                                  : isTablet
                                  ? 3.5
                                  : isSmallScreen
                                  ? 2
                                  : 2,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isLargeDesktop
                                    ? 8
                                    : isDesktop
                                    ? 6
                                    : isTablet
                                    ? 5
                                    : isSmallScreen
                                    ? 3
                                    : 4,
                              ),
                            ),
                            child: Text(
                              exam['difficulty'],
                              style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 12
                                    : isDesktop
                                    ? 11
                                    : isTablet
                                    ? 10
                                    : isSmallScreen
                                    ? 8
                                    : 9,
                                color: difficultyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: isLargeDesktop
                            ? 8
                            : isDesktop
                            ? 6
                            : isTablet
                            ? 5
                            : isSmallScreen
                            ? 3
                            : 4,
                      ),
                      Text(
                        exam['courseName'],
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 11
                              : 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: isLargeDesktop || isDesktop
                            ? 2
                            : isTablet
                            ? 2
                            : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: isLargeDesktop
                            ? 16
                            : isDesktop
                            ? 12
                            : isTablet
                            ? 11
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: _buildModernInfoChip(
                              icon: Icons.timer_outlined,
                              label: exam['duration'],
                            ),
                          ),
                          SizedBox(
                            width: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 12
                                : isTablet
                                ? 11
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                          Flexible(
                            child: _buildModernInfoChip(
                              icon: Icons.quiz_outlined,
                              label: exam['questions'],
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              '${exam['attempts']}/${exam['maxAttempts']} attempts',
                              style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 14
                                    : isDesktop
                                    ? 13
                                    : isTablet
                                    ? 12
                                    : isSmallScreen
                                    ? 10
                                    : 11,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 10
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 14
                      : 16,
                  color: const Color(0xFF6B5FFF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isLargeDesktop
              ? 18
              : isDesktop
              ? 16
              : isTablet
              ? 15
              : isSmallScreen
              ? 12
              : 14,
          color: Colors.grey[600],
        ),
        SizedBox(
          width: isLargeDesktop
              ? 6
              : isDesktop
              ? 5
              : isTablet
              ? 4.5
              : isSmallScreen
              ? 3
              : 4,
        ),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 13
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 10
                  : 11,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCourseExamsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(
          isLargeDesktop
              ? 32
              : isDesktop
              ? 24
              : isTablet
              ? 20
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: _buildNoCourseExams(),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 56
            : isDesktop
            ? 48
            : isTablet
            ? 40
            : isSmallScreen
            ? 24
            : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 28
              : isDesktop
              ? 24
              : isTablet
              ? 22
              : isSmallScreen
              ? 16
              : 20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 10
                : isSmallScreen
                ? 6
                : 8,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 6
                  : isDesktop
                  ? 4
                  : isTablet
                  ? 3
                  : isSmallScreen
                  ? 2
                  : 3,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B5FFF).withOpacity(0.1),
                  const Color(0xFF8F7FFF).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: isLargeDesktop
                  ? 80
                  : isDesktop
                  ? 72
                  : isTablet
                  ? 64
                  : isSmallScreen
                  ? 48
                  : 56,
              color: const Color(0xFF6B5FFF),
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 20
                : isSmallScreen
                ? 12
                : 16,
          ),
          Text(
            'No Exams Found',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 26
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 18
                  : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 8
                : 10,
          ),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 15
                  : isSmallScreen
                  ? 12
                  : 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: isLargeDesktop
                ? 32
                : isDesktop
                ? 28
                : isTablet
                ? 24
                : isSmallScreen
                ? 16
                : 20,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 14
                    : isDesktop
                    ? 12
                    : isTablet
                    ? 11
                    : isSmallScreen
                    ? 8
                    : 10,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B5FFF).withOpacity(0.3),
                  blurRadius: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 10
                      : isSmallScreen
                      ? 6
                      : 8,
                  offset: Offset(
                    0,
                    isLargeDesktop
                        ? 6
                        : isDesktop
                        ? 4
                        : isTablet
                        ? 3
                        : isSmallScreen
                        ? 2
                        : 3,
                  ),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _selectedFilter = 'All Exams';
                    _applyFilters();
                  });
                },
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 32
                        : isDesktop
                        ? 28
                        : isTablet
                        ? 26
                        : isSmallScreen
                        ? 16
                        : 24,
                    vertical: isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 8
                        : 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: isLargeDesktop
                            ? 24
                            : isDesktop
                            ? 20
                            : isTablet
                            ? 19
                            : isSmallScreen
                            ? 16
                            : 18,
                      ),
                      SizedBox(
                        width: isLargeDesktop
                            ? 12
                            : isDesktop
                            ? 10
                            : isTablet
                            ? 9
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      Text(
                        'Clear Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isLargeDesktop
                              ? 18
                              : isDesktop
                              ? 17
                              : isTablet
                              ? 16
                              : isSmallScreen
                              ? 12
                              : 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCourseExams() {
    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop
            ? 56
            : isDesktop
            ? 48
            : isTablet
            ? 40
            : isSmallScreen
            ? 24
            : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 28
              : isDesktop
              ? 24
              : isTablet
              ? 22
              : isSmallScreen
              ? 16
              : 20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeDesktop
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 10
                : isSmallScreen
                ? 6
                : 8,
            offset: Offset(
              0,
              isLargeDesktop
                  ? 6
                  : isDesktop
                  ? 4
                  : isTablet
                  ? 3
                  : isSmallScreen
                  ? 2
                  : 3,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B5FFF).withOpacity(0.1),
                  const Color(0xFF8F7FFF).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 28
                    : isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
            ),
            child: Icon(
              Icons.school_outlined,
              size: isLargeDesktop
                  ? 80
                  : isDesktop
                  ? 72
                  : isTablet
                  ? 64
                  : isSmallScreen
                  ? 48
                  : 56,
              color: const Color(0xFF6B5FFF),
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 28
                : isDesktop
                ? 24
                : isTablet
                ? 20
                : isSmallScreen
                ? 12
                : 16,
          ),
          Text(
            'No Course Exams Yet',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 26
                  : isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : isSmallScreen
                  ? 18
                  : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(
            height: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 8
                : 10,
          ),
          Text(
            'Enroll in courses to unlock course-specific exams',
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 18
                  : isDesktop
                  ? 16
                  : isTablet
                  ? 15
                  : isSmallScreen
                  ? 12
                  : 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMainExamDialog(BuildContext context, Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 18
                : isSmallScreen
                ? 12
                : 16,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 9
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                ),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: isLargeDesktop
                    ? 32
                    : isDesktop
                    ? 28
                    : isTablet
                    ? 26
                    : isSmallScreen
                    ? 20
                    : 24,
              ),
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            Flexible(
              child: Text(
                exam['title'] ?? 'Start Tega Main Exam',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 24
                      : isDesktop
                      ? 22
                      : isTablet
                      ? 20
                      : isSmallScreen
                      ? 16
                      : 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 2
                    : isTablet
                    ? 2
                    : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam['_backendData']?['description']?.toString() ??
                  'Are you ready to begin the comprehensive Tega Main Exam?',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 18
                    : isDesktop
                    ? 17
                    : isTablet
                    ? 16
                    : isSmallScreen
                    ? 13
                    : 15,
              ),
              maxLines: isLargeDesktop || isDesktop
                  ? 3
                  : isTablet
                  ? 2
                  : 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 12
                  : 14,
            ),
            _buildDialogInfo(
              Icons.timer_rounded,
              'Duration: ${exam['duration'] ?? 'TBD'}',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.quiz_rounded,
              'Questions: ${exam['questions'] ?? 'TBD'}',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.trending_up_rounded,
              'Difficulty: ${exam['difficulty'] ?? 'Intermediate'}',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.verified_rounded,
              'Passing Score: ${exam['passingScore'] ?? 70}%',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.replay_rounded,
              'Attempts: ${exam['attempts'] ?? 0}/${exam['maxAttempts'] ?? 3}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 12
                    : 13,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 7,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await _handleStartExam(exam);
                },
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 7,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 22
                        : isTablet
                        ? 20
                        : isSmallScreen
                        ? 14
                        : 18,
                    vertical: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 11
                        : isTablet
                        ? 10
                        : isSmallScreen
                        ? 7
                        : 9,
                  ),
                  child: Text(
                    'Start Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 15
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 12
                          : 13,
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

  void _showExamDialog(BuildContext context, Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isLargeDesktop
                ? 24
                : isDesktop
                ? 20
                : isTablet
                ? 18
                : isSmallScreen
                ? 12
                : 16,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 9
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
                ),
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
              ),
              child: Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: isLargeDesktop
                    ? 32
                    : isDesktop
                    ? 28
                    : isTablet
                    ? 26
                    : isSmallScreen
                    ? 20
                    : 24,
              ),
            ),
            SizedBox(
              width: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 8
                  : 12,
            ),
            Flexible(
              child: Text(
                exam['title'],
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 14
                      : 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: isLargeDesktop || isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course: ${exam['courseName']}',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 12
                    : 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: isLargeDesktop || isDesktop
                  ? 2
                  : isTablet
                  ? 2
                  : 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 16
                  : isSmallScreen
                  ? 12
                  : 14,
            ),
            _buildDialogInfo(
              Icons.timer_rounded,
              'Duration: ${exam['duration']}',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.quiz_rounded,
              'Questions: ${exam['questions']}',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.trending_up_rounded,
              'Difficulty: ${exam['difficulty']}',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.verified_rounded,
              'Passing Score: ${exam['passingScore']}%',
            ),
            SizedBox(
              height: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            _buildDialogInfo(
              Icons.replay_rounded,
              'Attempts: ${exam['attempts']}/${exam['maxAttempts']}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 15
                    : isTablet
                    ? 14
                    : isSmallScreen
                    ? 12
                    : 13,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5FFF), Color(0xFF8F7FFF)],
              ),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 10
                    : isDesktop
                    ? 9
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 7,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await _handleStartExam(exam);
                },
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 9
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 7,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeDesktop
                        ? 24
                        : isDesktop
                        ? 22
                        : isTablet
                        ? 20
                        : isSmallScreen
                        ? 14
                        : 18,
                    vertical: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 11
                        : isTablet
                        ? 10
                        : isSmallScreen
                        ? 7
                        : 9,
                  ),
                  child: Text(
                    'Start Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 15
                          : isTablet
                          ? 14
                          : isSmallScreen
                          ? 12
                          : 13,
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

  Widget _buildDialogInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: isLargeDesktop
              ? 22
              : isDesktop
              ? 20
              : isTablet
              ? 19
              : isSmallScreen
              ? 16
              : 18,
          color: const Color(0xFF6B5FFF),
        ),
        SizedBox(
          width: isLargeDesktop
              ? 12
              : isDesktop
              ? 10
              : isTablet
              ? 9
              : isSmallScreen
              ? 6
              : 8,
        ),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 15
                  : isTablet
                  ? 14
                  : isSmallScreen
                  ? 12
                  : 13,
              color: Colors.grey[700],
            ),
            maxLines: isLargeDesktop || isDesktop
                ? 2
                : isTablet
                ? 2
                : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
