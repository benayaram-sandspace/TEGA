import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/quick_actions.dart';
import 'package:tega/features/4_college_panel/presentation/0_dashboard/widgets/recent_student_registrations.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  
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
    _loadDashboardData();
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

  Future<void> _loadDashboardData() async {
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
                year: student['year']?.toString() ?? student['yearOfStudy']?.toString(),
                isActive: student['isActive'] as bool? ?? false,
                createdAt: _parseDateTime(student['createdAt']),
              );
            }).toList();
          }
          
          setState(() {
            _totalStudents = stats['totalCollegeUsers'] as int? ?? 0;
            _activeStudents = stats['activeStudents'] as int? ?? 0;
            _recentRegistrations = stats['recentCollegeRegistrations'] as int? ?? 0;
            // For unique courses, we'll need to calculate or get from API
            // For now, using a placeholder
            _uniqueCourses = 1;
            _students = students;
            
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
            const SizedBox(height: 32),
            // Recent Student Registrations
            RecentStudentRegistrations(students: _students),
          ],
        ),
      ),
    );
  }
}
