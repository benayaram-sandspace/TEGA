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

  /// Get all students
  Future<Map<String, dynamic>> getAllStudents() async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http
          .get(Uri.parse(ApiEndpoints.adminStudents), headers: headers)
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
          return {'success': true, 'students': data['students']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load students');
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
          throw Exception(errorData['message'] ?? 'Failed to load students');
        } catch (e) {
          throw Exception('Failed to load students (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to load students: $e');
    }
  }

  /// Get students by college name
  Future<Map<String, dynamic>> getStudentsByCollege(String collegeName) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http
          .get(
            Uri.parse(ApiEndpoints.adminStudentsByCollege(collegeName)),
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
          return {
            'success': true,
            'students': data['students'],
            'collegeName': data['collegeName'],
            'count': data['count'],
          };
        } else {
          throw Exception(
            data['message'] ?? 'Failed to load students for this college',
          );
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Invalid college name provided',
        );
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
            errorData['message'] ?? 'Failed to load students for this college',
          );
        } catch (e) {
          throw Exception(
            'Failed to load students for this college (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to load students for this college: $e');
    }
  }

  /// Get student by ID
  Future<Map<String, dynamic>> getStudentById(String studentId) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http
          .get(
            Uri.parse(ApiEndpoints.adminStudentById(studentId)),
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
          return {'success': true, 'student': data['student']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load student details');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Student not found');
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
            errorData['message'] ?? 'Failed to load student details',
          );
        } catch (e) {
          throw Exception(
            'Failed to load student details (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to load student details: $e');
    }
  }

  /// Bulk import students
  Future<Map<String, dynamic>> bulkImportStudents(
    List<Map<String, dynamic>> students,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminBulkImportStudents),
            headers: headers,
            body: json.encode({'students': students}),
          )
          .timeout(
            const Duration(seconds: 60), // Longer timeout for bulk operations
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
            'importedStudents': data['importedStudents'],
            'totalImported': data['totalImported'],
            'errors': data['errors'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to import students');
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
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to import students');
        } catch (e) {
          throw Exception('Failed to import students (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to import students: $e');
    }
  }

  /// Get all principals
  Future<Map<String, dynamic>> getAllPrincipals() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(Uri.parse(ApiEndpoints.adminPrincipals), headers: headers)
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
          return {'success': true, 'principals': data['principals']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load principals');
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
          throw Exception(errorData['message'] ?? 'Failed to load principals');
        } catch (e) {
          throw Exception('Failed to load principals (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to load principals: $e');
    }
  }

  /// Get principal by ID
  Future<Map<String, dynamic>> getPrincipalById(String principalId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.adminPrincipalById(principalId)),
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
          return {'success': true, 'principal': data['principal']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load principal');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode == 404) {
        throw Exception('Principal not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to load principal');
        } catch (e) {
          throw Exception('Failed to load principal (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to load principal: $e');
    }
  }

  /// Register a new principal
  Future<Map<String, dynamic>> registerPrincipal(
    Map<String, dynamic> principalData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminRegisterPrincipal),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: json.encode(principalData),
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
            'principal': data['principal'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to register principal');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Invalid principal data provided',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Principal already exists');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to register principal',
          );
        } catch (e) {
          throw Exception(
            'Failed to register principal (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to register principal: $e');
    }
  }

  /// Update principal
  Future<Map<String, dynamic>> updatePrincipal(
    String principalId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse(ApiEndpoints.adminPrincipalById(principalId)),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: json.encode(updateData),
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
            'principal': data['principal'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to update principal');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid update data provided');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You may not have admin permissions.');
      } else if (response.statusCode == 404) {
        throw Exception('Principal not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to update principal');
        } catch (e) {
          throw Exception(
            'Failed to update principal (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update principal: $e');
    }
  }

  /// Bulk import principals
  Future<Map<String, dynamic>> bulkImportPrincipals(
    List<Map<String, dynamic>> principals,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminBulkImportPrincipals),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: json.encode({'principals': principals}),
          )
          .timeout(
            const Duration(seconds: 60), // Longer timeout for bulk operations
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
            'importedPrincipals': data['importedPrincipals'],
            'totalImported': data['totalImported'],
            'errors': data['errors'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to import principals');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Invalid principal data provided',
        );
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
            errorData['message'] ?? 'Failed to import principals',
          );
        } catch (e) {
          throw Exception(
            'Failed to import principals (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to import principals: $e');
    }
  }

  /// Get all courses for admin
  Future<Map<String, dynamic>> getAllCourses() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.adminRealTimeCoursesAll),
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
          return {'success': true, 'courses': data['courses']};
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

  /// Get course by ID
  Future<Map<String, dynamic>> getCourseById(String courseId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.realTimeCourseById(courseId)),
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
          return {'success': true, 'course': data['course']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load course');
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
          throw Exception(errorData['message'] ?? 'Failed to load course');
        } catch (e) {
          throw Exception('Failed to load course (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  /// Create a new course
  Future<Map<String, dynamic>> createCourse(
    Map<String, dynamic> courseData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminCreateRealTimeCourse),
            headers: {...headers, 'Content-Type': 'application/json'},
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

  /// Update course
  Future<Map<String, dynamic>> updateCourse(
    String courseId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse(ApiEndpoints.adminUpdateRealTimeCourse(courseId)),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: json.encode(updateData),
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
        throw Exception(errorData['message'] ?? 'Invalid update data provided');
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

  /// Delete course
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

  /// Publish course
  Future<Map<String, dynamic>> publishCourse(String courseId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.adminPublishRealTimeCourse(courseId)),
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
          return {
            'success': true,
            'message': data['message'],
            'course': data['course'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to publish course');
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
          throw Exception(errorData['message'] ?? 'Failed to publish course');
        } catch (e) {
          throw Exception('Failed to publish course (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Failed to publish course: $e');
    }
  }

  /// Get course analytics
  Future<Map<String, dynamic>> getCourseAnalytics(String courseId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.adminRealTimeCourseAnalytics(courseId)),
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
          return {'success': true, 'analytics': data['analytics']};
        } else {
          throw Exception(data['message'] ?? 'Failed to load course analytics');
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
          throw Exception(
            errorData['message'] ?? 'Failed to load course analytics',
          );
        } catch (e) {
          throw Exception(
            'Failed to load course analytics (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to load course analytics: $e');
    }
  }
}
