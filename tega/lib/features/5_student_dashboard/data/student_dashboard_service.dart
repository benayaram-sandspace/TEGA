import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';

class StudentDashboardService {
  Future<Map<String, dynamic>> getSidebarCounts(
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse(ApiEndpoints.studentSidebarCounts);
    print('🔍 [API] Fetching sidebar counts from: $uri');

    final res = await http.get(uri, headers: headers);
    print('🔍 [API] Sidebar counts response status: ${res.statusCode}');
    print('🔍 [API] Sidebar counts response body: ${res.body}');

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final counts = body['counts'] as Map<String, dynamic>;
        print('🔍 [API] Sidebar counts extracted: $counts');
        return counts;
      }
      return {};
    } catch (e) {
      print('❌ [API] Sidebar counts parsing error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getDashboard(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.studentDashboard);
    print('🔍 [API] Fetching dashboard from: $uri');

    final res = await http.get(uri, headers: headers);
    print('🔍 [API] Dashboard response status: ${res.statusCode}');
    print('🔍 [API] Dashboard response body: ${res.body}');

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final dashboardData = body['data'] as Map<String, dynamic>;
        print('🔍 [API] Dashboard data extracted: $dashboardData');
        return dashboardData;
      }
      return {};
    } catch (e) {
      print('❌ [API] Dashboard parsing error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getProfile(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.studentProfile);
    print('🔍 [API] Fetching profile from: $uri');
    print('🔍 [API] Headers: $headers');

    final res = await http.get(uri, headers: headers);
    print('🔍 [API] Profile response status: ${res.statusCode}');
    print('🔍 [API] Profile response body: ${res.body}');

    try {
      final body = json.decode(res.body);
      print('🔍 [API] Parsed profile response: $body');

      if (res.statusCode == 200 && body['success'] == true) {
        final profileData = body['data'] as Map<String, dynamic>;
        print('🔍 [API] Profile data extracted: $profileData');
        return profileData;
      } else {
        print(
          '❌ [API] Profile request failed - Status: ${res.statusCode}, Success: ${body['success']}',
        );
        return {};
      }
    } catch (e) {
      print('❌ [API] Profile parsing error: $e');
      return {};
    }
  }

  Future<List<dynamic>> getEnrolledCourses(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.studentDashboard);
    final res = await http.get(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        return data['enrolledCourses'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getAllCourses(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.courses);
    final res = await http.get(uri, headers: headers);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        if (body is List) {
          return body;
        } else if (body['success'] == true && body['courses'] != null) {
          return body['courses'] as List<dynamic>;
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getExamResults(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.studentExamResults);
    final res = await http.get(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return body['results'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getJobs(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.jobs);

    final res = await http.get(uri, headers: headers);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        if (body is List) {
          return body;
        } else if (body['success'] == true && body['jobs'] != null) {
          return body['jobs'] as List<dynamic>;
        } else if (body['data'] != null) {
          if (body['data'] is List) {
            return body['data'] as List<dynamic>;
          } else if (body['data']['jobs'] != null) {
            return body['data']['jobs'] as List<dynamic>;
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> applyForJob(
    String jobId,
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse(ApiEndpoints.studentApplyJob(jobId));
    final res = await http.post(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return body as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Failed to apply'};
    } catch (_) {
      return {'success': false, 'message': 'Error applying for job'};
    }
  }

  // ==================== INTERNSHIPS ====================
  Future<List<dynamic>> getInternships(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.internships);

    final res = await http.get(uri, headers: headers);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        if (body is List) {
          return body;
        } else if (body['success'] == true && body['internships'] != null) {
          return body['internships'] as List<dynamic>;
        } else if (body['data'] != null) {
          if (body['data'] is List) {
            return body['data'] as List<dynamic>;
          } else if (body['data']['internships'] != null) {
            return body['data']['internships'] as List<dynamic>;
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> applyForInternship(
    String internshipId,
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse(ApiEndpoints.studentApplyInternship(internshipId));
    final res = await http.post(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return body as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Failed to apply'};
    } catch (_) {
      return {'success': false, 'message': 'Error applying for internship'};
    }
  }
}
