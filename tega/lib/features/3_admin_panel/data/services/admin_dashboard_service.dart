import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class AdminDashboardService {
  final AuthService _authService = AuthService();

  /// Fetch dashboard statistics and recent students
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http
          .get(Uri.parse(ApiEndpoints.adminDashboard), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'stats': data['stats'],
            'recentStudents': data['recentStudents'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to load dashboard data');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to load dashboard data',
          );
        } catch (e) {
          throw Exception(
            'Failed to load dashboard data (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  /// Create a new student
  Future<Map<String, dynamic>> createStudent(
    Map<String, dynamic> studentData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminCreateStudent),
            headers: headers,
            body: json.encode(studentData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'student': data['student'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create student');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Invalid student data provided',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Student already exists');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to create student');
        } catch (e) {
          throw Exception('Failed to create student (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  /// Get all courses
  Future<Map<String, dynamic>> getCourses() async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http
          .get(Uri.parse(ApiEndpoints.adminCourses), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return {'success': true, 'data': data['courses']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load courses');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to load courses');
        } catch (e) {
          throw Exception('Failed to load courses (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to load courses: $e');
    }
  }

  /// Create a new course
  Future<Map<String, dynamic>> createCourse(
    Map<String, dynamic> courseData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminCreateRealTimeCourse),
            headers: headers,
            body: json.encode(courseData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'course': data['course'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create course');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid course data provided');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to create course');
        } catch (e) {
          throw Exception('Failed to create course (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  /// Update a course
  Future<Map<String, dynamic>> updateCourse(
    String courseId,
    Map<String, dynamic> courseData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http
          .put(
            Uri.parse(ApiEndpoints.adminUpdateRealTimeCourse(courseId)),
            headers: headers,
            body: json.encode(courseData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'course': data['course'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to update course');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid course data provided');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode == 404) {
        throw Exception('Course not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to update course');
        } catch (e) {
          throw Exception('Failed to update course (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  /// Delete a course
  Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http
          .delete(
            Uri.parse(ApiEndpoints.adminDeleteRealTimeCourse(courseId)),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return {'success': true, 'message': data['message']};
        } else {
          throw Exception(data['message'] ?? 'Failed to delete course');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode == 404) {
        throw Exception('Course not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to delete course');
        } catch (e) {
          throw Exception('Failed to delete course (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }
}
