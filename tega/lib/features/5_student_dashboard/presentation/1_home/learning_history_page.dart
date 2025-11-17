import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/learning_history_service.dart';
import '../../data/student_dashboard_service.dart';
import '../../../1_authentication/data/auth_repository.dart';
import 'package:tega/core/services/learning_history_cache_service.dart';

class LearningHistoryPage extends StatefulWidget {
  const LearningHistoryPage({super.key});

  @override
  State<LearningHistoryPage> createState() => _LearningHistoryPageState();
}

class _LearningHistoryPageState extends State<LearningHistoryPage> {
  final LearningHistoryService _learningService = LearningHistoryService();
  final StudentDashboardService _dashboardService = StudentDashboardService();
  final LearningHistoryCacheService _cacheService = LearningHistoryCacheService();

  // Data
  LearningStats? _learningStats;
  List<Map<String, dynamic>> _enrolledCourses = [];

  // Loading states
  bool _isLoadingStats = true;
  bool _isLoadingCourses = true;

  // Error states
  String? _statsError;
  String? _coursesError;

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
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _loadData();
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

  Future<void> _loadData({bool forceRefresh = false}) async {
    await Future.wait([
      _loadLearningStats(forceRefresh: forceRefresh),
      _loadEnrolledCourses(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> _loadLearningStats({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedStats = await _cacheService.getLearningStats();
      if (cachedStats != null && mounted) {
        setState(() {
          _learningStats = LearningStats(
            completionRate: (cachedStats['completionRate'] ?? 0).toDouble(),
            completedLectures: cachedStats['completedLectures'] ?? 0,
            totalLectures: cachedStats['totalLectures'] ?? 0,
            totalTimeSpent: cachedStats['totalTimeSpent'] ?? 0,
            coursesEnrolled: cachedStats['coursesEnrolled'] ?? 0,
          );
          _isLoadingStats = false;
          _statsError = null;
        });
        // Still fetch in background to update cache
        _fetchLearningStatsInBackground();
        return;
      }
    }

    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    // Fetch from API
    await _fetchLearningStatsInBackground();
  }

  Future<void> _fetchLearningStatsInBackground() async {
    try {
      final stats = await _learningService.getLearningStats();

      // Cache learning stats data
      await _cacheService.setLearningStats({
        'completionRate': stats.completionRate,
        'completedLectures': stats.completedLectures,
        'totalLectures': stats.totalLectures,
        'totalTimeSpent': stats.totalTimeSpent,
        'coursesEnrolled': stats.coursesEnrolled,
      });

      if (mounted) {
        setState(() {
          _learningStats = stats;
          _isLoadingStats = false;
          _statsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedStats = await _cacheService.getLearningStats();
          if (cachedStats != null) {
            setState(() {
              _learningStats = LearningStats(
                completionRate: (cachedStats['completionRate'] ?? 0).toDouble(),
                completedLectures: cachedStats['completedLectures'] ?? 0,
                totalLectures: cachedStats['totalLectures'] ?? 0,
                totalTimeSpent: cachedStats['totalTimeSpent'] ?? 0,
                coursesEnrolled: cachedStats['coursesEnrolled'] ?? 0,
              );
              _statsError = null; // Clear error since we have cached data
              _isLoadingStats = false;
            });
            return;
          }
          // No cache available, show error
          setState(() {
            _statsError = 'No internet connection';
            _isLoadingStats = false;
          });
        } else {
          setState(() {
            _statsError = 'Unable to load learning stats. Please try again.';
            _isLoadingStats = false;
          });
        }
      }
    }
  }

  Future<void> _loadEnrolledCourses({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedCourses = await _cacheService.getEnrolledCourses();
      if (cachedCourses != null && cachedCourses.isNotEmpty && mounted) {
        setState(() {
          _enrolledCourses = cachedCourses;
          _isLoadingCourses = false;
          _coursesError = null;
        });
        // Still fetch in background to update cache
        _fetchEnrolledCoursesInBackground();
        return;
      }
    }

    setState(() {
      _isLoadingCourses = true;
      _coursesError = null;
    });

    // Fetch from API
    await _fetchEnrolledCoursesInBackground();
  }

  Future<void> _fetchEnrolledCoursesInBackground() async {
    try {
      final auth = AuthService();
      final headers = auth.getAuthHeaders();

      // Fetch paid courses
      final paidCourses = await _dashboardService.getEnrolledCourses(headers);
      
      // Get progress data to merge with paid courses
      final progressData = await _dashboardService.getAllProgress(headers);
      
      // Create a map of courseId -> progress for quick lookup
      final progressMap = <String, dynamic>{};
      for (var progress in progressData) {
        final courseId = progress['courseId']?.toString() ?? '';
        if (courseId.isNotEmpty) {
          progressMap[courseId] = progress;
        }
      }

      // Merge paid courses with progress data
      final mergedCourses = paidCourses.map((course) {
        // Check if courseId is a nested object (populated by MongoDB)
        String courseId;
        if (course['courseId'] is Map) {
          // If courseId is an object, get its _id or id
          courseId = course['courseId']['_id']?.toString() ?? 
                    course['courseId']['id']?.toString() ?? '';
        } else {
          // If courseId is a string
          courseId = course['courseId']?.toString() ?? 
                    course['id']?.toString() ?? 
                    course['_id']?.toString() ?? '';
        }
        
        final progress = progressMap[courseId];
        
        // Get course title
        String title = '';
        if (course['courseId'] is Map) {
          title = course['courseId']?['title']?.toString() ?? 
                 course['courseName']?.toString() ?? 
                 course['title']?.toString() ?? 
                 'Untitled Course';
        } else {
          title = course['courseName']?.toString() ?? 
                 course['title']?.toString() ?? 
                 course['name']?.toString() ?? 
                 'Untitled Course';
        }
        
        // Get progress percentage
        double progressPercentage = 0.0;
        if (progress != null) {
          progressPercentage = (progress['overallProgress'] ?? 0).toDouble();
        }
        
        // Get enrollment date or last accessed date
        DateTime? enrollmentDate;
        if (course['enrolledAt'] != null) {
          try {
            enrollmentDate = DateTime.parse(course['enrolledAt'].toString());
          } catch (_) {}
        } else if (course['createdAt'] != null) {
          try {
            enrollmentDate = DateTime.parse(course['createdAt'].toString());
          } catch (_) {}
        } else if (progress != null && progress['lastAccessedAt'] != null) {
          try {
            enrollmentDate = DateTime.parse(progress['lastAccessedAt'].toString());
          } catch (_) {}
        }
        
        return {
          'id': courseId,
          'title': title,
          'progress': progressPercentage,
          'enrollmentDate': (enrollmentDate ?? DateTime.now()).toIso8601String(),
          'thumbnail': course['thumbnail']?.toString(),
        };
      }).toList();

      // Sort by enrollment date (newest first)
      mergedCourses.sort((a, b) {
        final aDateStr = a['enrollmentDate'] as String;
        final bDateStr = b['enrollmentDate'] as String;
        final aDate = DateTime.parse(aDateStr);
        final bDate = DateTime.parse(bDateStr);
        return bDate.compareTo(aDate);
      });

      // Cache enrolled courses data
      await _cacheService.setEnrolledCourses(mergedCourses);

      if (mounted) {
        setState(() {
          _enrolledCourses = mergedCourses;
          _isLoadingCourses = false;
          _coursesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/internet error
        if (_isNoInternetError(e)) {
          // Try to load from cache if available
          final cachedCourses = await _cacheService.getEnrolledCourses();
          if (cachedCourses != null && cachedCourses.isNotEmpty) {
            setState(() {
              _enrolledCourses = cachedCourses;
              _coursesError = null; // Clear error since we have cached data
              _isLoadingCourses = false;
            });
            return;
          }
          // No cache available, show error
          setState(() {
            _coursesError = 'No internet connection';
            _isLoadingCourses = false;
          });
        } else {
          setState(() {
            _coursesError = 'Unable to load enrolled courses. Please try again.';
            _isLoadingCourses = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(child: _buildOverviewTab()),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C88FF)),
        ),
      );
    }

    if (_statsError != null) {
      return _buildErrorState(
        _statsError == 'No internet connection' 
            ? 'No internet connection'
            : 'Failed to load learning stats',
        _statsError!,
        _loadLearningStats,
      );
    }

    if (_learningStats == null) {
      return _buildEmptyState('No learning data available');
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: const Color(0xFF9C88FF),
      child: SingleChildScrollView(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Progress Ring
            _buildHeroSection(),
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
            // Search and Filter Section
            _buildSearchAndFilters(),
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
            // Enrolled Courses List
            _buildEnrolledCoursesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final stats = _learningStats!;
    final completionRate = stats.completionRate / 100;

    return Container(
      padding: EdgeInsets.all(
        isLargeDesktop 
            ? 40 
            : isDesktop 
            ? 36 
            : isTablet 
            ? 32 
            : isSmallScreen 
            ? 24 
            : 28
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C88FF), Color(0xFF7A6BFF)],
        ),
        borderRadius: BorderRadius.circular(
          isLargeDesktop ? 28 : isDesktop ? 26 : isTablet ? 24 : isSmallScreen ? 20 : 22
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C88FF).withOpacity(0.3),
            blurRadius: isLargeDesktop ? 24 : isDesktop ? 20 : isTablet ? 18 : isSmallScreen ? 12 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Ring Section
          Row(
            children: [
              // Circular Progress Ring
              SizedBox(
                width: isLargeDesktop 
                    ? 160 
                    : isDesktop 
                    ? 140 
                    : isTablet 
                    ? 120 
                    : isSmallScreen 
                    ? 100 
                    : 110,
                height: isLargeDesktop 
                    ? 160 
                    : isDesktop 
                    ? 140 
                    : isTablet 
                    ? 120 
                    : isSmallScreen 
                    ? 100 
                    : 110,
                child: Stack(
                  children: [
                    // Background Circle
                    Container(
                      width: isLargeDesktop 
                          ? 160 
                          : isDesktop 
                          ? 140 
                          : isTablet 
                          ? 120 
                          : isSmallScreen 
                          ? 100 
                          : 110,
                      height: isLargeDesktop 
                          ? 160 
                          : isDesktop 
                          ? 140 
                          : isTablet 
                          ? 120 
                          : isSmallScreen 
                          ? 100 
                          : 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    // Progress Circle
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: completionRate,
                        strokeWidth: isLargeDesktop 
                            ? 12 
                            : isDesktop 
                            ? 10 
                            : isTablet 
                            ? 9 
                            : isSmallScreen 
                            ? 7 
                            : 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    // Center Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stats.completionRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: isLargeDesktop 
                                  ? 36 
                                  : isDesktop 
                                  ? 32 
                                  : isTablet 
                                  ? 28 
                                  : isSmallScreen 
                                  ? 22 
                                  : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: isLargeDesktop 
                                  ? 18 
                                  : isDesktop 
                                  ? 16 
                                  : isTablet 
                                  ? 14 
                                  : isSmallScreen 
                                  ? 12 
                                  : 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isLargeDesktop ? 32 : isDesktop ? 28 : isTablet ? 24 : isSmallScreen ? 16 : 20),
              // Stats Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: isLargeDesktop 
                            ? 32 
                            : isDesktop 
                            ? 28 
                            : isTablet 
                            ? 24 
                            : isSmallScreen 
                            ? 20 
                            : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : isSmallScreen ? 6 : 8),
                    _buildStatRow(
                      Icons.school_outlined,
                      '${_enrolledCourses.length} Courses',
                      'Enrolled',
                    ),
                    SizedBox(height: isLargeDesktop ? 12 : isDesktop ? 10 : isTablet ? 8 : isSmallScreen ? 5 : 6),
                    _buildStatRow(
                      Icons.check_circle_outline,
                      '${stats.completedLectures} Completed',
                      'Lectures',
                    ),
                    SizedBox(height: isLargeDesktop ? 12 : isDesktop ? 10 : isTablet ? 8 : isSmallScreen ? 5 : 6),
                    _buildStatRow(
                      Icons.access_time,
                      stats.formattedTimeSpent,
                      'Study Time',
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeDesktop ? 32 : isDesktop ? 28 : isTablet ? 24 : 20),
          // Achievement Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeDesktop ? 28 : isDesktop ? 24 : isTablet ? 20 : isSmallScreen ? 16 : 18,
              vertical: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : isSmallScreen ? 8 : 9
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                isLargeDesktop ? 28 : isDesktop ? 24 : isTablet ? 22 : isSmallScreen ? 20 : 22
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events, 
                  color: Colors.white, 
                  size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : isSmallScreen ? 16 : 17
                ),
                SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                Flexible(
                  child: Text(
                    'Keep up the great work!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeDesktop 
                          ? 20 
                          : isDesktop 
                          ? 18 
                          : isTablet 
                          ? 16 
                          : isSmallScreen 
                          ? 14 
                          : 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: isLargeDesktop
              ? 24
              : isDesktop
                  ? 22
                  : isTablet
                      ? 20
                      : isSmallScreen
                          ? 18
                          : 19,
        ),
        SizedBox(
          width: isLargeDesktop
              ? 16
              : isDesktop
                  ? 14
                  : isTablet
                      ? 12
                      : isSmallScreen
                          ? 8
                          : 10,
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLargeDesktop
                  ? 22
                  : isDesktop
                      ? 20
                      : isTablet
                          ? 18
                          : isSmallScreen
                              ? 14
                              : 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: isLargeDesktop
              ? 12
              : isDesktop
                  ? 10
                  : isTablet
                      ? 8
                      : isSmallScreen
                          ? 4
                          : 6,
        ),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isLargeDesktop
                  ? 20
                  : isDesktop
                      ? 18
                      : isTablet
                          ? 16
                          : isSmallScreen
                              ? 12
                              : 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      height: isLargeDesktop
          ? 44
          : isDesktop
          ? 40
          : isTablet
          ? 38
          : isSmallScreen
          ? 32
          : 36,
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF9C88FF) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 22
              : isDesktop
              ? 20
              : isTablet
              ? 18
              : isSmallScreen
              ? 16
              : 18,
        ),
        border: Border.all(
          color: isSelected ? const Color(0xFF9C88FF) : const Color(0xFFE9ECEF),
          width: isLargeDesktop || isDesktop
              ? 1.5
              : isTablet
              ? 1.2
              : isSmallScreen
              ? 0.8
              : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6C757D),
            fontSize: isLargeDesktop
                ? 16
                : isDesktop
                ? 14
                : isTablet
                ? 13
                : isSmallScreen
                ? 11
                : 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildErrorState(String title, String message, VoidCallback onRetry) {
    final isNoInternet = message == 'No internet connection';
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 48
              : isDesktop
              ? 40
              : isTablet
              ? 36
              : isSmallScreen
              ? 24
              : 32,
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
              title,
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
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
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
              ),
            ] else ...[
              SizedBox(
                height: isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 8
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
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
              ),
            ],
            SizedBox(
              height: isLargeDesktop
                  ? 32
                  : isDesktop
                  ? 28
                  : isTablet
                  ? 24
                  : isSmallScreen
                  ? 16
                  : 24,
            ),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh,
                size: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 22
                    : isTablet
                    ? 20
                    : isSmallScreen
                    ? 18
                    : 20,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isLargeDesktop
                      ? 18
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 13
                      : 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C88FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 32
                      : isDesktop
                      ? 28
                      : isTablet
                      ? 24
                      : isSmallScreen
                      ? 16
                      : 20,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 12
                      : isSmallScreen
                      ? 8
                      : 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isLargeDesktop
              ? 48
              : isDesktop
              ? 40
              : isTablet
              ? 36
              : isSmallScreen
              ? 24
              : 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    ? 20
                    : 22,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF9C88FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: isLargeDesktop
                    ? 80
                    : isDesktop
                    ? 72
                    : isTablet
                    ? 64
                    : isSmallScreen
                    ? 48
                    : 56,
                color: const Color(0xFF9C88FF),
              ),
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
            Text(
              message,
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(
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
      decoration: BoxDecoration(
        color: Colors.white,
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: isLargeDesktop
                ? 20
                : isDesktop
                ? 16
                : isTablet
                ? 14
                : isSmallScreen
                ? 8
                : 12,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 7 : 6
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C88FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 7 : 8
                  ),
                ),
                child: Icon(
                  Icons.tune,
                  color: const Color(0xFF9C88FF),
                  size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : 17,
                ),
              ),
              SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9),
              Expanded(
                child: Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: isLargeDesktop 
                        ? 20 
                        : isDesktop 
                        ? 18 
                        : isTablet 
                        ? 17 
                        : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeDesktop ? 24 : isDesktop ? 20 : isTablet ? 18 : 16),
          // Filter Chips Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Activities', true),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Lectures', false),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Quizzes', false),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Assignments', false),
                      SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                      _buildFilterChip('Certificates', false),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9),
              // Sort Button
              Container(
                height: isLargeDesktop ? 40 : isDesktop ? 36 : isTablet ? 34 : 32,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop ? 20 : isDesktop ? 18 : isTablet ? 16 : 16
                  ),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      color: const Color(0xFF6C757D),
                      size: isLargeDesktop ? 18 : isDesktop ? 16 : isTablet ? 15 : 14,
                    ),
                    SizedBox(width: isLargeDesktop ? 8 : isDesktop ? 6 : isTablet ? 5 : 4),
                    Flexible(
                      child: Text(
                        'Newest',
                        style: TextStyle(
                          color: const Color(0xFF6C757D),
                          fontSize: isLargeDesktop 
                              ? 14 
                              : isDesktop 
                              ? 12 
                              : isTablet 
                              ? 11 
                              : 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 6 : 5),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF6C757D),
                      size: isLargeDesktop ? 18 : isDesktop ? 16 : isTablet ? 15 : 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeDesktop ? 20 : isDesktop ? 16 : isTablet ? 14 : 12),
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: isLargeDesktop ? 48 : isDesktop ? 44 : isTablet ? 42 : 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C88FF), Color(0xFF7A6BFF)],
                    ),
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C88FF).withOpacity(0.3),
                        blurRadius: isLargeDesktop ? 10 : isDesktop ? 8 : isTablet ? 7 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                      ),
                      onTap: () {},
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_rounded,
                              color: Colors.white,
                              size: isLargeDesktop ? 20 : isDesktop ? 18 : isTablet ? 17 : 16,
                            ),
                            SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 8),
                            Flexible(
                              child: Text(
                                'View Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isLargeDesktop 
                                      ? 16 
                                      : isDesktop 
                                      ? 14 
                                      : isTablet 
                                      ? 13 
                                      : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 10 : 9),
              Container(
                height: isLargeDesktop ? 48 : isDesktop ? 44 : isTablet ? 42 : 40,
                width: isLargeDesktop ? 48 : isDesktop ? 44 : isTablet ? 42 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                  ),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      isLargeDesktop ? 14 : isDesktop ? 12 : isTablet ? 11 : 11
                    ),
                    onTap: () {},
                    child: Center(
                      child: Icon(
                        Icons.refresh_rounded,
                        color: const Color(0xFF6C757D),
                        size: isLargeDesktop ? 22 : isDesktop ? 20 : isTablet ? 18 : 17,
                      ),
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

  Widget _buildEnrolledCoursesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isLargeDesktop
              ? 20
              : isDesktop
              ? 18
              : isTablet
              ? 16
              : isSmallScreen
              ? 12
              : 14,
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
                  : 3,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
              isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 12
                  : isSmallScreen
                  ? 8
                  : 10,
            ),
            child: Text(
              'My Courses',
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
                color: const Color(0xFF2C3E50),
              ),
            ),
          ),
          // Loading State
          if (_isLoadingCourses)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 48
                      : isDesktop
                      ? 40
                      : isTablet
                      ? 36
                      : isSmallScreen
                      ? 24
                      : 32,
                ),
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C88FF)),
                  strokeWidth: isLargeDesktop
                      ? 4
                      : isDesktop
                      ? 3.5
                      : isTablet
                      ? 3
                      : isSmallScreen
                      ? 2.5
                      : 3,
                ),
              ),
            )
          // Error State
          else if (_coursesError != null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(
                  isLargeDesktop
                      ? 48
                      : isDesktop
                      ? 40
                      : isTablet
                      ? 36
                      : isSmallScreen
                      ? 24
                      : 32,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: isLargeDesktop
                          ? 64
                          : isDesktop
                          ? 56
                          : isTablet
                          ? 48
                          : isSmallScreen
                          ? 40
                          : 44,
                      color: Colors.grey[400],
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
                    Text(
                      _coursesError == 'No internet connection'
                          ? 'No internet connection'
                          : 'Failed to load courses',
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 16
                            : isSmallScreen
                            ? 14
                            : 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_coursesError == 'No internet connection') ...[
                      SizedBox(
                        height: isLargeDesktop
                            ? 12
                            : isDesktop
                            ? 10
                            : isTablet
                            ? 8
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      Text(
                        'Please check your connection and try again',
                        textAlign: TextAlign.center,
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
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: isLargeDesktop
                            ? 12
                            : isDesktop
                            ? 10
                            : isTablet
                            ? 8
                            : isSmallScreen
                            ? 6
                            : 8,
                      ),
                      Text(
                        _coursesError!,
                        textAlign: TextAlign.center,
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
                          color: Colors.grey[600],
                        ),
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
                    ElevatedButton.icon(
                      onPressed: () => _loadEnrolledCourses(forceRefresh: true),
                      icon: Icon(
                        Icons.refresh,
                        size: isLargeDesktop
                            ? 22
                            : isDesktop
                            ? 20
                            : isTablet
                            ? 18
                            : isSmallScreen
                            ? 16
                            : 18,
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
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C88FF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeDesktop
                              ? 28
                              : isDesktop
                              ? 24
                              : isTablet
                              ? 20
                              : isSmallScreen
                              ? 14
                              : 18,
                          vertical: isLargeDesktop
                              ? 14
                              : isDesktop
                              ? 12
                              : isTablet
                              ? 10
                              : isSmallScreen
                              ? 8
                              : 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Empty State
          else if (_enrolledCourses.isEmpty)
            Padding(
              padding: EdgeInsets.all(
                isLargeDesktop
                    ? 48
                    : isDesktop
                    ? 40
                    : isTablet
                    ? 36
                    : isSmallScreen
                    ? 24
                    : 32,
              ),
              child: Center(
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
                            ? 20
                            : 22,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        size: isLargeDesktop
                            ? 64
                            : isDesktop
                            ? 56
                            : isTablet
                            ? 48
                            : isSmallScreen
                            ? 40
                            : 44,
                        color: Colors.grey,
                      ),
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
                      'No enrolled courses found',
                      style: TextStyle(
                        fontSize: isLargeDesktop
                            ? 22
                            : isDesktop
                            ? 20
                            : isTablet
                            ? 18
                            : isSmallScreen
                            ? 16
                            : 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(
                      height: isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 10
                          : isTablet
                          ? 8
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    Text(
                      'Enroll in courses to see them here',
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
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Courses List
          else
            Column(
              children: _enrolledCourses.map((course) => _buildCourseCard(course)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['title'] as String;
    final progress = (course['progress'] as num).toDouble();
    final enrollmentDateStr = course['enrollmentDate'] as String;
    final enrollmentDate = DateTime.parse(enrollmentDateStr);
    final progressPercent = progress.round();
    
    // Format date
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${monthNames[enrollmentDate.month - 1]} ${enrollmentDate.day}, ${enrollmentDate.year}';
    
    // Progress color
    final progressColor = progressPercent == 0 
        ? Colors.red 
        : progressPercent < 50 
            ? Colors.orange 
            : const Color(0xFF4CAF50);

    return Container(
      margin: EdgeInsets.only(
        bottom: isLargeDesktop
            ? 2
            : isDesktop
            ? 1.5
            : isTablet
            ? 1
            : isSmallScreen
            ? 0.5
            : 1,
      ),
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
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE9ECEF).withOpacity(0.5),
            width: isLargeDesktop || isDesktop
                ? 1.5
                : isTablet
                ? 1.2
                : isSmallScreen
                ? 0.8
                : 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Icon
          Container(
            margin: EdgeInsets.only(
              top: isLargeDesktop
                  ? 4
                  : isDesktop
                  ? 3
                  : isTablet
                  ? 2
                  : isSmallScreen
                  ? 1
                  : 2,
            ),
            padding: EdgeInsets.all(
              isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 10
                  : isSmallScreen
                  ? 8
                  : 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
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
            child: Icon(
              Icons.menu_book_outlined,
              color: const Color(0xFF2196F3),
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
          ),
          SizedBox(
            width: isLargeDesktop
                ? 20
                : isDesktop
                ? 18
                : isTablet
                ? 16
                : isSmallScreen
                ? 12
                : 14,
          ),
          // Course Details - Expanded to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Course Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 18
                        : isTablet
                        ? 17
                        : isSmallScreen
                        ? 14
                        : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 12
                      : isDesktop
                      ? 10
                      : isTablet
                      ? 8
                      : isSmallScreen
                      ? 6
                      : 8,
                ),
                // Course Progress Text
                Text(
                  'Course progress: $progressPercent%',
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
                    color: const Color(0xFF6C757D),
                    height: 1.4,
                  ),
                ),
                SizedBox(
                  height: isLargeDesktop
                      ? 10
                      : isDesktop
                      ? 8
                      : isTablet
                      ? 6
                      : isSmallScreen
                      ? 4
                      : 6,
                ),
                // Date and Status - Wrap in Flexible to prevent overflow
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: isLargeDesktop
                              ? 15
                              : isDesktop
                              ? 14
                              : isTablet
                              ? 13
                              : isSmallScreen
                              ? 11
                              : 12,
                          color: const Color(0xFF6C757D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: isLargeDesktop
                          ? 16
                          : isDesktop
                          ? 14
                          : isTablet
                          ? 12
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                    Flexible(
                      child: Container(
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
                              ? 4
                              : isDesktop
                              ? 3
                              : isTablet
                              ? 2.5
                              : isSmallScreen
                              ? 2
                              : 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            isLargeDesktop
                                ? 6
                                : isDesktop
                                ? 5
                                : isTablet
                                ? 4
                                : isSmallScreen
                                ? 3
                                : 4,
                          ),
                        ),
                        child: Text(
                          '$progressPercent% Complete',
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
                            color: progressColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                ? 14
                : isTablet
                ? 12
                : isSmallScreen
                ? 8
                : 10,
          ),
          // Progress Indicator - Fixed width to prevent overflow
          SizedBox(
            width: isLargeDesktop
                ? 60
                : isDesktop
                ? 55
                : isTablet
                ? 50
                : isSmallScreen
                ? 40
                : 45,
            child: Padding(
              padding: EdgeInsets.only(
                top: isLargeDesktop
                    ? 4
                    : isDesktop
                    ? 3
                    : isTablet
                    ? 2
                    : isSmallScreen
                    ? 1
                    : 2,
              ),
              child: Container(
                height: isLargeDesktop
                    ? 6
                    : isDesktop
                    ? 5
                    : isTablet
                    ? 4.5
                    : isSmallScreen
                    ? 3.5
                    : 4,
                width: isLargeDesktop
                    ? 60
                    : isDesktop
                    ? 55
                    : isTablet
                    ? 50
                    : isSmallScreen
                    ? 40
                    : 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 3
                        : isDesktop
                        ? 2.5
                        : isTablet
                        ? 2
                        : isSmallScreen
                        ? 1.5
                        : 2,
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progress / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(
                        isLargeDesktop
                            ? 3
                            : isDesktop
                            ? 2.5
                            : isTablet
                            ? 2
                            : isSmallScreen
                            ? 1.5
                            : 2,
                      ),
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

}

