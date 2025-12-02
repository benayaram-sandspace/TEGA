import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/principal_dashboard_cache_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AuthService _authService = AuthService();
  final PrincipalDashboardCacheService _cacheService =
      PrincipalDashboardCacheService();
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;
  int _totalStudents = 0;
  int _activeLearners = 0;
  double _avgPerformance = 0.0;

  // Course enrollment data
  List<Map<String, dynamic>> _courseEnrollments = [];
  int _totalEnrollments = 0;
  int _activeCourses = 0;
  int _totalInstituteStudents = 0;

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
    await _loadAnalyticsData();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _cacheService.getAnalyticsData();
      if (cachedData != null && mounted) {
        setState(() {
          _isLoadingFromCache = true;
        });

        // Restore data from cache
        _totalStudents = cachedData['totalStudents'] as int? ?? 0;
        _activeLearners = cachedData['activeLearners'] as int? ?? 0;
        _avgPerformance =
            (cachedData['avgPerformance'] as num?)?.toDouble() ?? 0.0;
        _courseEnrollments = List<Map<String, dynamic>>.from(
          cachedData['courseEnrollments'] as List? ?? [],
        );
        _totalEnrollments = cachedData['totalEnrollments'] as int? ?? 0;
        _activeCourses = cachedData['activeCourses'] as int? ?? 0;
        _totalInstituteStudents =
            cachedData['totalInstituteStudents'] as int? ?? 0;

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    } catch (e) {
      // Silently handle cache errors
      if (mounted) {
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    }
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

  Future<void> _loadAnalyticsData({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && !_isLoadingFromCache && _totalStudents > 0) {
      _loadAnalyticsDataInBackground();
      return;
    }

    if (!_isLoadingFromCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(ApiEndpoints.principalDashboard), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['stats'] != null) {
          final stats = data['stats'] as Map<String, dynamic>;
          final totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
          final activeLearners = stats['activeStudents'] as int? ?? 0;

          // Fetch average performance from course-engagement endpoint
          await _calculatePerformanceAndRisk(headers, totalStudents);

          // Fetch course enrollment data
          await _loadCourseEnrollments(headers);

          if (mounted) {
            setState(() {
              _totalStudents = totalStudents;
              _activeLearners = activeLearners;
              _isLoading = false;
              _isLoadingFromCache = false;
            });

            // Cache the analytics data
            await _cacheService.setAnalyticsData({
              'totalStudents': totalStudents,
              'activeLearners': activeLearners,
              'avgPerformance': _avgPerformance,
              'courseEnrollments': _courseEnrollments,
              'totalEnrollments': _totalEnrollments,
              'activeCourses': _activeCourses,
              'totalInstituteStudents': _totalInstituteStudents,
            });

            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoadingFromCache = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    } catch (e) {
      // Check if it's a network/internet error
      if (_isNoInternetError(e)) {
        // Try to load from cache if available
        final cachedData = await _cacheService.getAnalyticsData();
        if (cachedData != null && mounted) {
          // Restore data from cache
          setState(() {
            _totalStudents = cachedData['totalStudents'] as int? ?? 0;
            _activeLearners = cachedData['activeLearners'] as int? ?? 0;
            _avgPerformance =
                (cachedData['avgPerformance'] as num?)?.toDouble() ?? 0.0;
            _courseEnrollments = List<Map<String, dynamic>>.from(
              cachedData['courseEnrollments'] as List? ?? [],
            );
            _totalEnrollments = cachedData['totalEnrollments'] as int? ?? 0;
            _activeCourses = cachedData['activeCourses'] as int? ?? 0;
            _totalInstituteStudents =
                cachedData['totalInstituteStudents'] as int? ?? 0;
            _isLoading = false;
            _isLoadingFromCache = false;
            _errorMessage = null;
          });

          // Handle offline state
          _cacheService.handleOfflineState(context);
        } else {
          // No cache available
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = 'No internet connection';
            });

            // Handle offline state
            _cacheService.handleOfflineState(context);
          }
        }
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _errorMessage = 'Error loading analytics: $e';
            _isLoading = false;
            _isLoadingFromCache = false;
          });
        }
      }
    }
  }

  Future<void> _loadAnalyticsDataInBackground() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(ApiEndpoints.principalDashboard), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['stats'] != null) {
          final stats = data['stats'] as Map<String, dynamic>;
          final totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
          final activeLearners = stats['activeStudents'] as int? ?? 0;

          // Fetch average performance from course-engagement endpoint
          await _calculatePerformanceAndRisk(headers, totalStudents);

          // Fetch course enrollment data
          await _loadCourseEnrollments(headers);

          if (mounted) {
            setState(() {
              _totalStudents = totalStudents;
              _activeLearners = activeLearners;
            });

            // Cache the analytics data
            await _cacheService.setAnalyticsData({
              'totalStudents': totalStudents,
              'activeLearners': activeLearners,
              'avgPerformance': _avgPerformance,
              'courseEnrollments': _courseEnrollments,
              'totalEnrollments': _totalEnrollments,
              'activeCourses': _activeCourses,
              'totalInstituteStudents': _totalInstituteStudents,
            });

            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        }
      }
    } catch (e) {
      // Silently handle background errors
      if (_isNoInternetError(e)) {
        _cacheService.handleOfflineState(context);
      }
    }
  }

  Future<void> _calculatePerformanceAndRisk(
    Map<String, String> headers,
    int totalStudents,
  ) async {
    try {
      // Use course-engagement endpoint to get average completion/performance from backend
      final engagementResponse = await http
          .get(
            Uri.parse(ApiEndpoints.principalCourseEngagement),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (engagementResponse.statusCode == 200) {
        final engagementData = json.decode(engagementResponse.body);

        // Check response structure - data might be directly in response or nested
        if (engagementData['success'] == true) {
          Map<String, dynamic>? data;

          // Try different possible response structures
          if (engagementData['data'] != null) {
            data = engagementData['data'] as Map<String, dynamic>?;
          } else if (engagementData['avgCompletion'] != null) {
            // If avgCompletion is directly in response
            final avgCompletion = engagementData['avgCompletion'];
            setState(() {
              _avgPerformance = (avgCompletion is int)
                  ? avgCompletion.toDouble()
                  : (avgCompletion is double)
                  ? avgCompletion
                  : 0.0;
            });
            return;
          }

          if (data != null) {
            // Get avgCompletion from data
            final avgCompletion = data['avgCompletion'];

            if (avgCompletion != null) {
              setState(() {
                _avgPerformance = (avgCompletion is int)
                    ? avgCompletion.toDouble()
                    : (avgCompletion is double)
                    ? avgCompletion
                    : (avgCompletion is num)
                    ? avgCompletion.toDouble()
                    : 0.0;
              });
              return;
            }
          }
        }
      }

      // If endpoint fails, set to 0
      setState(() {
        _avgPerformance = 0.0;
      });
    } catch (e) {
      // If calculation fails, use defaults
      setState(() {
        _avgPerformance = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final padding = isMobile
        ? 12.0
        : isTablet
        ? 16.0
        : 20.0;
    final spacing = isMobile
        ? 16.0
        : isTablet
        ? 18.0
        : 20.0;

    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: SafeArea(
        child: _isLoading && !_isLoadingFromCache
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _totalStudents == 0
            ? _buildErrorState(isMobile, isTablet)
            : SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(isMobile, isTablet),
                    SizedBox(height: spacing),
                    _buildCourseEnrollmentChart(isMobile, isTablet),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile
              ? 24.0
              : isTablet
              ? 32.0
              : 40.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isMobile
                  ? 56
                  : isTablet
                  ? 64
                  : 72,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'No internet connection',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: isMobile
                    ? 14
                    : isTablet
                    ? 15
                    : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            ElevatedButton.icon(
              onPressed: () => _loadAnalyticsData(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isMobile, bool isTablet) {
    final padding = isMobile
        ? 12.0
        : isTablet
        ? 14.0
        : 16.0;
    final spacing = isMobile
        ? 8.0
        : isTablet
        ? 10.0
        : 12.0;
    final borderRadius = isMobile
        ? 10.0
        : isTablet
        ? 11.0
        : 12.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isMobile
                ? 8
                : isTablet
                ? 9
                : 10,
            offset: Offset(0, isMobile ? 1.5 : 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.people_outline,
              iconColor: const Color(0xFF3B82F6),
              title: 'Total Students',
              value: _totalStudents.toString(),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatItem(
              icon: Icons.trending_up_outlined,
              iconColor: DashboardStyles.accentGreen,
              title: 'Active Learners',
              value: _activeLearners.toString(),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatItem(
              icon: Icons.track_changes_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Avg Performance',
              value: '${_avgPerformance.toInt()}%',
              isMobile: isMobile,
              isTablet: isTablet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isMobile,
    required bool isTablet,
  }) {
    final iconSize = isMobile
        ? 28.0
        : isTablet
        ? 30.0
        : 32.0;
    final iconInnerSize = isMobile
        ? 14.0
        : isTablet
        ? 15.0
        : 16.0;
    final valueFontSize = isMobile
        ? 18.0
        : isTablet
        ? 20.0
        : 22.0;
    final titleFontSize = isMobile
        ? 10.0
        : isTablet
        ? 10.5
        : 11.0;
    final iconSpacing = isMobile
        ? 8.0
        : isTablet
        ? 9.0
        : 10.0;
    final valueSpacing = isMobile ? 1.5 : 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(isMobile ? 5 : 6),
          ),
          child: Icon(icon, color: Colors.white, size: iconInnerSize),
        ),
        SizedBox(height: iconSpacing),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
        SizedBox(height: valueSpacing),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _loadCourseEnrollments(Map<String, String> headers) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.principalCourseEnrollments),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['courseEnrollments'] != null) {
          final enrollments = List<Map<String, dynamic>>.from(
            data['courseEnrollments'],
          );

          // Get totalInstituteStudents from backend
          final totalInstituteStudents =
              data['totalInstituteStudents'] as int? ?? 0;

          // Calculate totals
          int totalEnrollments = 0;
          int activeCourses = 0;

          for (var course in enrollments) {
            final enrollmentCount = course['enrollments'] as int? ?? 0;
            totalEnrollments += enrollmentCount;
            if (enrollmentCount > 0) {
              activeCourses++;
            }
          }

          setState(() {
            _courseEnrollments = enrollments;
            _totalEnrollments = totalEnrollments;
            _activeCourses = activeCourses;
            _totalInstituteStudents = totalInstituteStudents;
          });
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Widget _buildCourseEnrollmentChart(bool isMobile, bool isTablet) {
    if (_courseEnrollments.isEmpty) {
      final padding = isMobile
          ? 20.0
          : isTablet
          ? 22.0
          : 24.0;
      final borderRadius = isMobile
          ? 10.0
          : isTablet
          ? 11.0
          : 12.0;
      final iconSize = isMobile
          ? 40.0
          : isTablet
          ? 44.0
          : 48.0;
      final fontSize = isMobile
          ? 13.0
          : isTablet
          ? 13.5
          : 14.0;

      return Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: isMobile
                  ? 8
                  : isTablet
                  ? 9
                  : 10,
              offset: Offset(0, isMobile ? 1.5 : 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: iconSize,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: isMobile ? 10 : 12),
              Text(
                'No enrollment data available',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxEnrollment = _courseEnrollments.isNotEmpty
        ? _courseEnrollments
              .map((e) => e['enrollments'] as int? ?? 0)
              .reduce((a, b) => a > b ? a : b)
        : 1;
    final maxY = maxEnrollment > 0 ? ((maxEnrollment / 5).ceil() * 5) : 5;

    // Responsive values
    final padding = isMobile
        ? 16.0
        : isTablet
        ? 20.0
        : 24.0;
    final borderRadius = isMobile
        ? 12.0
        : isTablet
        ? 14.0
        : 16.0;
    final iconPadding = isMobile
        ? 6.0
        : isTablet
        ? 7.0
        : 8.0;
    final iconSize = isMobile
        ? 18.0
        : isTablet
        ? 19.0
        : 20.0;
    final titleFontSize = isMobile
        ? 15.0
        : isTablet
        ? 16.0
        : 17.0;
    final subtitleFontSize = isMobile
        ? 10.0
        : isTablet
        ? 10.5
        : 11.0;
    final badgePadding = isMobile
        ? 8.0
        : isTablet
        ? 9.0
        : 10.0;
    final badgeFontSize = isMobile
        ? 10.0
        : isTablet
        ? 10.5
        : 11.0;
    final chartSpacing = isMobile
        ? 18.0
        : isTablet
        ? 20.0
        : 24.0;
    final legendSpacing = isMobile
        ? 10.0
        : isTablet
        ? 11.0
        : 12.0;
    final summarySpacing = isMobile
        ? 18.0
        : isTablet
        ? 20.0
        : 24.0;
    final chartHeight = isMobile
        ? (_courseEnrollments.length > 10
              ? 350
              : (_courseEnrollments.length * 50.0).clamp(180.0, 350.0))
        : isTablet
        ? (_courseEnrollments.length > 10
              ? 375
              : (_courseEnrollments.length * 55.0).clamp(190.0, 375.0))
        : (_courseEnrollments.length > 10
              ? 400
              : (_courseEnrollments.length * 60.0).clamp(200.0, 400.0));

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isMobile
                ? 16
                : isTablet
                ? 18
                : 20,
            offset: Offset(
              0,
              isMobile
                  ? 3
                  : isTablet
                  ? 3.5
                  : 4,
            ),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(iconPadding),
                          decoration: BoxDecoration(
                            color: DashboardStyles.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            size: iconSize,
                            color: DashboardStyles.primary,
                          ),
                        ),
                        SizedBox(width: isMobile ? 10 : 12),
                        Expanded(
                          child: Text(
                            'Course Enrollment Distribution',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: badgePadding,
                        vertical: isMobile ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.15),
                            const Color(0xFF3B82F6).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Total: ${_totalInstituteStudents > 0 ? _totalInstituteStudents : _totalStudents}',
                        style: TextStyle(
                          fontSize: badgeFontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B82F6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 5 : 6),
              Text(
                'Enrollment breakdown by course from your institute.',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(height: chartSpacing),
          // Horizontal scrollable bar chart for scalability
          SizedBox(
            height: chartHeight.toDouble(),
            child: _buildHorizontalBarChart(maxY, isMobile, isTablet),
          ),
          SizedBox(height: legendSpacing),
          // Legend
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMobile ? 10 : 12,
                  height: isMobile ? 10 : 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DashboardStyles.primary,
                        DashboardStyles.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  'Enrollments',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: summarySpacing),
          // Summary Statistics
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  value:
                      (_totalInstituteStudents > 0
                              ? _totalInstituteStudents
                              : _totalStudents)
                          .toString(),
                  label: 'Total Students',
                  color: const Color(0xFF1F2937),
                  icon: Icons.people_outline_rounded,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(
                width: isMobile
                    ? 8
                    : isTablet
                    ? 10
                    : 12,
              ),
              Expanded(
                child: _buildSummaryStat(
                  value: _activeCourses.toString(),
                  label: 'Active Courses',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.book_outlined,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(
                width: isMobile
                    ? 8
                    : isTablet
                    ? 10
                    : 12,
              ),
              Expanded(
                child: _buildSummaryStat(
                  value: _totalEnrollments.toString(),
                  label: 'Total Enrollments',
                  color: DashboardStyles.accentGreen,
                  icon: Icons.school_outlined,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required String value,
    required String label,
    required Color color,
    IconData? icon,
    required bool isMobile,
    required bool isTablet,
  }) {
    final padding = isMobile
        ? 10.0
        : isTablet
        ? 11.0
        : 12.0;
    final horizontalPadding = isMobile ? 6.0 : 8.0;
    final borderRadius = isMobile
        ? 10.0
        : isTablet
        ? 11.0
        : 12.0;
    final iconSize = isMobile
        ? 18.0
        : isTablet
        ? 19.0
        : 20.0;
    final valueFontSize = isMobile
        ? 18.0
        : isTablet
        ? 20.0
        : 22.0;
    final labelFontSize = isMobile
        ? 10.0
        : isTablet
        ? 10.5
        : 11.0;
    final iconSpacing = isMobile ? 6.0 : 8.0;
    final valueSpacing = isMobile ? 3.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: padding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(height: iconSpacing),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
          SizedBox(height: valueSpacing),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Color> _getBarGradient(int index) {
    final gradients = [
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildHorizontalBarChart(int maxY, bool isMobile, bool isTablet) {
    if (_courseEnrollments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Chart header with axis label
        Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Number of Students (out of ${_totalInstituteStudents > 0 ? _totalInstituteStudents : _totalStudents})',
                  style: TextStyle(
                    fontSize: isMobile
                        ? 9
                        : isTablet
                        ? 9.5
                        : 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_courseEnrollments.length > 10)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: isMobile ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_vertical,
                        size: isMobile ? 10 : 12,
                        color: Colors.blue.shade700,
                      ),
                      SizedBox(width: isMobile ? 3 : 4),
                      Text(
                        '${_courseEnrollments.length} courses',
                        style: TextStyle(
                          fontSize: isMobile ? 8 : 9,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Scrollable horizontal bars
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _courseEnrollments.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: isMobile ? 10 : 12),
            itemBuilder: (context, index) {
              final course = _courseEnrollments[index];
              final courseName =
                  course['courseName'] as String? ?? 'Unknown Course';
              final enrollments = course['enrollments'] as int? ?? 0;
              final gradients = _getBarGradient(index);
              final percentage = maxY > 0
                  ? (enrollments / maxY).clamp(0.0, 1.0)
                  : 0.0;

              return _buildHorizontalBarItem(
                courseName: courseName,
                enrollments: enrollments,
                percentage: percentage,
                gradient: gradients,
                maxY: maxY,
                isMobile: isMobile,
                isTablet: isTablet,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBarItem({
    required String courseName,
    required int enrollments,
    required double percentage,
    required List<Color> gradient,
    required int maxY,
    required bool isMobile,
    required bool isTablet,
  }) {
    final courseNameFontSize = isMobile
        ? 11.0
        : isTablet
        ? 11.5
        : 12.0;
    final enrollmentFontSize = isMobile
        ? 11.0
        : isTablet
        ? 11.5
        : 12.0;
    final badgePadding = isMobile
        ? 6.0
        : isTablet
        ? 7.0
        : 8.0;
    final badgeVerticalPadding = isMobile ? 3.0 : 4.0;
    final barHeight = isMobile
        ? 24.0
        : isTablet
        ? 26.0
        : 28.0;
    final percentageFontSize = isMobile ? 9.0 : 10.0;
    final spacing = isMobile
        ? 6.0
        : isTablet
        ? 7.0
        : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                courseName,
                style: TextStyle(
                  fontSize: courseNameFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: badgePadding,
                vertical: badgeVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: gradient[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$enrollments',
                style: TextStyle(
                  fontSize: enrollmentFontSize,
                  fontWeight: FontWeight.bold,
                  color: gradient[0],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Stack(
          children: [
            // Background bar
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(barHeight / 2),
              ),
            ),
            // Progress bar with gradient
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: isMobile ? 3 : 4,
                      offset: Offset(0, isMobile ? 1.5 : 2),
                    ),
                  ],
                ),
                child: percentage > 0.1
                    ? Center(
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: percentageFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
