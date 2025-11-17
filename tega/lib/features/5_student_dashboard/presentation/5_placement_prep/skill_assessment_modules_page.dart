import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/data/student_dashboard_service.dart';
import 'package:tega/features/5_student_dashboard/presentation/5_placement_prep/skill_assessment_quiz_page.dart';
import 'package:tega/core/services/placement_prep_cache_service.dart';

class SkillAssessmentModulesPage extends StatefulWidget {
  const SkillAssessmentModulesPage({super.key});

  @override
  State<SkillAssessmentModulesPage> createState() =>
      _SkillAssessmentModulesPageState();
}

class _SkillAssessmentModulesPageState
    extends State<SkillAssessmentModulesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _modules = [];
  String? _errorMessage;
  final PlacementPrepCacheService _cacheService = PlacementPrepCacheService();

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadSkillAssessments();
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

  Future<void> _loadSkillAssessments({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Try to load from cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedData = await _cacheService.getSkillAssessmentsData();
        if (cachedData != null && cachedData['modules'] != null && mounted) {
          final modules = cachedData['modules'] as List<dynamic>? ?? [];
          setState(() {
            _modules = modules
                .map<Map<String, dynamic>>((m) => {
                      'id': m['_id']?.toString() ?? '',
                      'title': m['title']?.toString() ?? 'Untitled Module',
                      'description': m['description']?.toString() ?? '',
                      'questionCount': m['questionCount'] ?? 0,
                      'status': m['status']?.toString() ?? 'not-started',
                      'progress': m['progress'] ?? 0,
                      'assessmentHistory': m['assessmentHistory'] ?? {},
                    })
                .toList();
            _isLoading = false;
          });
          // Still fetch in background to update cache
          _fetchSkillAssessmentsInBackground();
          return;
        }
      }

      // Fetch from API
      await _fetchSkillAssessmentsInBackground();
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
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

  Future<void> _fetchSkillAssessmentsInBackground() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();
      final service = StudentDashboardService();

      final data = await service.getSkillAssessments(headers);
      final modules = data['modules'] as List<dynamic>? ?? [];

      // Cache the data
      await _cacheService.setSkillAssessmentsData(data);

      if (mounted) {
        setState(() {
          _modules = modules
              .map<Map<String, dynamic>>((m) => {
                    'id': m['_id']?.toString() ?? '',
                    'title': m['title']?.toString() ?? 'Untitled Module',
                    'description': m['description']?.toString() ?? '',
                    'questionCount': m['questionCount'] ?? 0,
                    'status': m['status']?.toString() ?? 'not-started',
                    'progress': m['progress'] ?? 0,
                    'assessmentHistory': m['assessmentHistory'] ?? {},
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
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

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Skill Assessments',
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
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5FFF)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
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
                          _errorMessage == 'No internet connection'
                              ? 'No internet connection'
                              : 'Something went wrong',
                          style: TextStyle(
                            color: Colors.grey[700],
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
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_errorMessage == 'No internet connection') ...[
                          SizedBox(
                            height: isLargeDesktop
                                ? 8
                                : isDesktop
                                ? 6
                                : isTablet
                                ? 5
                                : isSmallScreen
                                ? 4
                                : 5,
                          ),
                          Text(
                            'Please check your connection and try again',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isLargeDesktop
                                  ? 14
                                  : isDesktop
                                  ? 13
                                  : isTablet
                                  ? 12
                                  : isSmallScreen
                                  ? 10
                                  : 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                        ElevatedButton(
                          onPressed: () => _loadSkillAssessments(forceRefresh: true),
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
                          ),
                          child: Text(
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _modules.isEmpty
                  ? Center(
                      child: Padding(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assessment_outlined,
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
                              'No skill assessment modules available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isLargeDesktop
                                    ? 20
                                    : isDesktop
                                    ? 18
                                    : isTablet
                                    ? 16
                                    : isSmallScreen
                                    ? 14
                                    : 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(
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
                      itemCount: _modules.length,
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        return _buildModuleCard(module);
                      },
                    ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    final title = module['title'] as String;
    final description = module['description'] as String;
    final questionCount = module['questionCount'] as int;
    final status = module['status'] as String;
    final progress = module['progress'] as num;
    final assessmentHistory = module['assessmentHistory'] as Map<String, dynamic>?;
    final totalAttempts = assessmentHistory?['totalAttempts'] ?? 0;
    final correctAnswers = assessmentHistory?['correctAnswers'] ?? 0;

    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'in-progress'
            ? Colors.orange
            : Colors.grey;

    return Container(
      margin: EdgeInsets.only(
        bottom: isLargeDesktop
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SkillAssessmentQuizPage(
                  moduleId: module['id'] as String,
                  moduleTitle: title,
                ),
              ),
            );
          },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
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
                        Icons.assessment_rounded,
                        color: const Color(0xFF667eea),
                        size: isLargeDesktop
                            ? 32
                            : isDesktop
                            ? 24
                            : isTablet
                            ? 22
                            : isSmallScreen
                            ? 18
                            : 20,
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
                            title,
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
                                ? 3
                                : isTablet
                                ? 2
                                : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.isNotEmpty) ...[
                            SizedBox(
                              height: isLargeDesktop
                                  ? 6
                                  : isDesktop
                                  ? 5
                                  : isTablet
                                  ? 4
                                  : isSmallScreen
                                  ? 2
                                  : 3,
                            ),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: isLargeDesktop
                                    ? 16
                                    : isDesktop
                                    ? 15
                                    : isTablet
                                    ? 14
                                    : isSmallScreen
                                    ? 11
                                    : 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: isLargeDesktop || isDesktop
                                  ? 3
                                  : isTablet
                                  ? 2
                                  : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeDesktop
                            ? 12
                            : isDesktop
                            ? 10
                            : isTablet
                            ? 9
                            : isSmallScreen
                            ? 6
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
                        color: statusColor.withOpacity(0.1),
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
                        status == 'completed'
                            ? 'Completed'
                            : status == 'in-progress'
                                ? 'In Progress'
                                : 'Not Started',
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
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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
                Row(
                  children: [
                    _buildStatChip(
                      Icons.help_outline,
                      '$questionCount Questions',
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
                    if (totalAttempts > 0)
                      _buildStatChip(
                        Icons.check_circle_outline,
                        '$correctAnswers/$totalAttempts Correct',
                      ),
                  ],
                ),
                if (progress > 0) ...[
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
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF667eea),
                    ),
                    minHeight: isLargeDesktop
                        ? 8
                        : isDesktop
                        ? 7
                        : isTablet
                        ? 6
                        : isSmallScreen
                        ? 4
                        : 5,
                  ),
                  SizedBox(
                    height: isLargeDesktop
                        ? 6
                        : isDesktop
                        ? 5
                        : isTablet
                        ? 4
                        : isSmallScreen
                        ? 2
                        : 3,
                  ),
                  Text(
                    '${progress.toStringAsFixed(0)}% Complete',
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
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 12
            : isDesktop
            ? 10
            : isTablet
            ? 9
            : isSmallScreen
            ? 6
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
        color: Colors.grey[100],
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
      child: Row(
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
            color: Colors.grey[700],
          ),
          SizedBox(
            width: isLargeDesktop
                ? 8
                : isDesktop
                ? 7
                : isTablet
                ? 6
                : isSmallScreen
                ? 4
                : 5,
          ),
          Text(
            text,
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
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

