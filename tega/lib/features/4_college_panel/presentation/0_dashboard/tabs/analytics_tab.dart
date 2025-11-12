import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
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
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.principalDashboard),
        headers: headers,
      ).timeout(
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
          
          setState(() {
            _totalStudents = totalStudents;
            _activeLearners = activeLearners;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculatePerformanceAndRisk(Map<String, String> headers, int totalStudents) async {
    try {
      // Use course-engagement endpoint to get average completion/performance from backend
      final engagementResponse = await http.get(
        Uri.parse(ApiEndpoints.principalCourseEngagement),
        headers: headers,
      ).timeout(
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
    return Scaffold(
      backgroundColor: DashboardStyles.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    _buildCourseEnrollmentChart(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.trending_up_outlined,
              iconColor: DashboardStyles.accentGreen,
              title: 'Active Learners',
              value: _activeLearners.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.track_changes_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Avg Performance',
              value: '${_avgPerformance.toInt()}%',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Future<void> _loadCourseEnrollments(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.principalCourseEnrollments),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['courseEnrollments'] != null) {
          final enrollments = List<Map<String, dynamic>>.from(data['courseEnrollments']);
          
          // Get totalInstituteStudents from backend
          final totalInstituteStudents = data['totalInstituteStudents'] as int? ?? 0;
          
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

  Widget _buildCourseEnrollmentChart() {
    if (_courseEnrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No enrollment data available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxEnrollment = _courseEnrollments.isNotEmpty
        ? _courseEnrollments.map((e) => e['enrollments'] as int? ?? 0).reduce((a, b) => a > b ? a : b)
        : 1;
    final maxY = maxEnrollment > 0 ? ((maxEnrollment / 5).ceil() * 5) : 5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DashboardStyles.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            size: 20,
                            color: DashboardStyles.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Course Enrollment Distribution',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B82F6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enrollment breakdown by course from your institute.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Horizontal scrollable bar chart for scalability
          SizedBox(
            height: _courseEnrollments.length > 10 ? 400 : (_courseEnrollments.length * 60.0).clamp(200.0, 400.0),
            child: _buildHorizontalBarChart(maxY),
          ),
          const SizedBox(height: 12),
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
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
                const SizedBox(width: 8),
                const Text(
                  'Enrollments',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Summary Statistics
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  value: (_totalInstituteStudents > 0 ? _totalInstituteStudents : _totalStudents).toString(),
                  label: 'Total Students',
                  color: const Color(0xFF1F2937),
                  icon: Icons.people_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStat(
                  value: _activeCourses.toString(),
                  label: 'Active Courses',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.book_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStat(
                  value: _totalEnrollments.toString(),
                  label: 'Total Enrollments',
                  color: DashboardStyles.accentGreen,
                  icon: Icons.school_outlined,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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

  Widget _buildHorizontalBarChart(int maxY) {
    if (_courseEnrollments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Chart header with axis label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of Students (out of ${_totalInstituteStudents > 0 ? _totalInstituteStudents : _totalStudents})',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_courseEnrollments.length > 10)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_vertical,
                        size: 12,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_courseEnrollments.length} courses',
                        style: TextStyle(
                          fontSize: 9,
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
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = _courseEnrollments[index];
              final courseName = course['courseName'] as String? ?? 'Unknown Course';
              final enrollments = course['enrollments'] as int? ?? 0;
              final gradients = _getBarGradient(index);
              final percentage = maxY > 0 ? (enrollments / maxY).clamp(0.0, 1.0) : 0.0;

              return _buildHorizontalBarItem(
                courseName: courseName,
                enrollments: enrollments,
                percentage: percentage,
                gradient: gradients,
                maxY: maxY,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                courseName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gradient[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$enrollments',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: gradient[0],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            // Progress bar with gradient
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: percentage > 0.1
                    ? Center(
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
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

