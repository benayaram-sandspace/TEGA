import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/core/services/principal_dashboard_cache_service.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/dashboard_styles.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/quick_actions.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/recent_student_registrations.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final AuthService _authService = AuthService();
  final PrincipalDashboardCacheService _cacheService =
      PrincipalDashboardCacheService();
  bool _isLoading = true;
  bool _isLoadingFromCache = false;
  String? _errorMessage;

  // Stats data
  int _totalStudents = 0;
  int _activeStudents = 0;
  int _recentRegistrations = 0;
  int _uniqueCourses = 0;

  // Student registrations
  List<StudentRegistration> _students = [];

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
    await _loadDashboardData();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _cacheService.getDashboardData();
      if (cachedData != null && mounted) {
        setState(() {
          _isLoadingFromCache = true;
        });

        final stats = cachedData['stats'] as Map<String, dynamic>?;
        final studentsList = cachedData['students'] as List<dynamic>?;

        if (stats != null) {
          List<StudentRegistration> students = [];
          if (studentsList != null) {
            students = studentsList.map((studentData) {
              final student = studentData as Map<String, dynamic>;
              return StudentRegistration(
                id: (student['id'] ?? '').toString(),
                firstName: student['firstName'] as String? ?? '',
                lastName: student['lastName'] as String? ?? '',
                email: student['email'] as String? ?? '',
                course: student['course'] as String?,
                year: student['year']?.toString(),
                isActive: student['isActive'] as bool? ?? false,
                createdAt: _parseDateTime(student['createdAt']),
              );
            }).toList();
          }

          if (mounted) {
            setState(() {
              _totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
              _activeStudents = stats['activeStudents'] as int? ?? 0;
              _recentRegistrations =
                  stats['recentCollegeRegistrations'] as int? ?? 0;
              _uniqueCourses = stats['uniqueCourses'] as int? ?? 1;
              _students = students;
              _isLoading = false;
              _isLoadingFromCache = false;
            });
          }
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

  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (dateValue is int) {
      // Handle Unix timestamp (milliseconds)
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }

    return DateTime.now();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    // If we have cached data and not forcing refresh, load in background
    if (!forceRefresh && !_isLoadingFromCache && _students.isNotEmpty) {
      _loadDashboardDataInBackground();
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

          // Parse students data
          List<StudentRegistration> students = [];
          if (data['students'] != null) {
            final studentsList = data['students'] as List<dynamic>;
            students = studentsList.map((studentData) {
              final student = studentData as Map<String, dynamic>;
              return StudentRegistration(
                id: (student['_id'] ?? student['id'] ?? '').toString(),
                firstName: student['firstName'] as String? ?? '',
                lastName: student['lastName'] as String? ?? '',
                email: student['email'] as String? ?? '',
                course: student['course'] as String?,
                year:
                    student['year']?.toString() ??
                    student['yearOfStudy']?.toString(),
                isActive: student['isActive'] as bool? ?? false,
                createdAt: _parseDateTime(student['createdAt']),
              );
            }).toList();
          }

          if (mounted) {
            setState(() {
              _totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
              _activeStudents = stats['activeStudents'] as int? ?? 0;
              _recentRegistrations =
                  stats['recentCollegeRegistrations'] as int? ?? 0;
              _uniqueCourses = stats['uniqueCourses'] as int? ?? 1;
              _students = students;
              _isLoading = false;
              _isLoadingFromCache = false;
              _errorMessage = null;
            });

            // Cache the data
            final studentsListForCache = data['students'] as List<dynamic>?;
            await _cacheService.setDashboardData({
              'stats': stats,
              'students': studentsListForCache != null
                  ? studentsListForCache.map((s) {
                      final student = s as Map<String, dynamic>;
                      return {
                        'id': (student['_id'] ?? student['id'] ?? '')
                            .toString(),
                        'firstName': student['firstName'],
                        'lastName': student['lastName'],
                        'email': student['email'],
                        'course': student['course'],
                        'year':
                            student['year']?.toString() ??
                            student['yearOfStudy']?.toString(),
                        'isActive': student['isActive'],
                        'createdAt': student['createdAt'],
                      };
                    }).toList()
                  : [],
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
        final cachedData = await _cacheService.getDashboardData();
        if (cachedData != null) {
          final stats = cachedData['stats'] as Map<String, dynamic>?;
          final studentsList = cachedData['students'] as List<dynamic>?;

          if (stats != null) {
            List<StudentRegistration> students = [];
            if (studentsList != null) {
              students = studentsList.map((studentData) {
                final student = studentData as Map<String, dynamic>;
                return StudentRegistration(
                  id: (student['id'] ?? '').toString(),
                  firstName: student['firstName'] as String? ?? '',
                  lastName: student['lastName'] as String? ?? '',
                  email: student['email'] as String? ?? '',
                  course: student['course'] as String?,
                  year: student['year']?.toString(),
                  isActive: student['isActive'] as bool? ?? false,
                  createdAt: _parseDateTime(student['createdAt']),
                );
              }).toList();
            }

            if (mounted) {
              setState(() {
                _totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
                _activeStudents = stats['activeStudents'] as int? ?? 0;
                _recentRegistrations =
                    stats['recentCollegeRegistrations'] as int? ?? 0;
                _uniqueCourses = stats['uniqueCourses'] as int? ?? 1;
                _students = students;
                _isLoading = false;
                _isLoadingFromCache = false;
                _errorMessage = null; // Clear error since we have cached data
              });

              // Handle offline state
              _cacheService.handleOfflineState(context);
            }
            return;
          }
        }

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
      } else {
        // Other errors
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingFromCache = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  Future<void> _loadDashboardDataInBackground() async {
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

          // Parse students data
          List<StudentRegistration> students = [];
          if (data['students'] != null) {
            final studentsList = data['students'] as List<dynamic>;
            students = studentsList.map((studentData) {
              final student = studentData as Map<String, dynamic>;
              return StudentRegistration(
                id: (student['_id'] ?? student['id'] ?? '').toString(),
                firstName: student['firstName'] as String? ?? '',
                lastName: student['lastName'] as String? ?? '',
                email: student['email'] as String? ?? '',
                course: student['course'] as String?,
                year:
                    student['year']?.toString() ??
                    student['yearOfStudy']?.toString(),
                isActive: student['isActive'] as bool? ?? false,
                createdAt: _parseDateTime(student['createdAt']),
              );
            }).toList();
          }

          if (mounted) {
            setState(() {
              _totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
              _activeStudents = stats['activeStudents'] as int? ?? 0;
              _recentRegistrations =
                  stats['recentCollegeRegistrations'] as int? ?? 0;
              _uniqueCourses = stats['uniqueCourses'] as int? ?? 1;
              _students = students;
            });

            // Cache the data
            final studentsListForCache = data['students'] as List<dynamic>?;
            await _cacheService.setDashboardData({
              'stats': stats,
              'students': studentsListForCache != null
                  ? studentsListForCache.map((s) {
                      final student = s as Map<String, dynamic>;
                      return {
                        'id': (student['_id'] ?? student['id'] ?? '')
                            .toString(),
                        'firstName': student['firstName'],
                        'lastName': student['lastName'],
                        'email': student['email'],
                        'course': student['course'],
                        'year':
                            student['year']?.toString() ??
                            student['yearOfStudy']?.toString(),
                        'isActive': student['isActive'],
                        'createdAt': student['createdAt'],
                      };
                    }).toList()
                  : [],
            });

            // Handle online state
            _cacheService.handleOnlineState(context);
          }
        }
      }
    } catch (e) {
      // Silently fail in background refresh
      if (_isNoInternetError(e)) {
        _cacheService.handleOfflineState(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Responsive padding
    final padding = isMobile
        ? 16.0
        : isTablet
        ? 18.0
        : 20.0;
    final spacing = isMobile
        ? 24.0
        : isTablet
        ? 28.0
        : 32.0;

    if (_isLoading && !_isLoadingFromCache) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _students.isEmpty) {
      return _buildErrorState(isMobile, isTablet);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards (replacing Quick Actions)
            QuickActions(
              totalStudents: _totalStudents,
              activeStudents: _activeStudents,
              recentRegistrations: _recentRegistrations,
              uniqueCourses: _uniqueCourses,
            ),
            SizedBox(height: spacing),
            // Recent Student Registrations
            RecentStudentRegistrations(students: _students),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile
            ? 24
            : isTablet
            ? 28
            : 32,
      ),
      child: Center(
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
            SizedBox(
              height: isMobile
                  ? 16
                  : isTablet
                  ? 18
                  : 20,
            ),
            Text(
              _errorMessage == 'No internet connection'
                  ? 'No internet connection'
                  : 'Failed to load dashboard',
              style: TextStyle(
                fontSize: isMobile
                    ? 18
                    : isTablet
                    ? 19
                    : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != 'No internet connection') ...[
              SizedBox(
                height: isMobile
                    ? 8
                    : isTablet
                    ? 9
                    : 10,
              ),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              SizedBox(
                height: isMobile
                    ? 8
                    : isTablet
                    ? 9
                    : 10,
              ),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(
              height: isMobile
                  ? 20
                  : isTablet
                  ? 24
                  : 28,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadDashboardData(forceRefresh: true);
              },
              icon: Icon(
                Icons.refresh,
                size: isMobile
                    ? 18
                    : isTablet
                    ? 20
                    : 22,
                color: Colors.white,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile
                      ? 14
                      : isTablet
                      ? 15
                      : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardStyles.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? 20
                      : isTablet
                      ? 24
                      : 28,
                  vertical: isMobile
                      ? 12
                      : isTablet
                      ? 14
                      : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 8
                        : isTablet
                        ? 9
                        : 10,
                  ),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
