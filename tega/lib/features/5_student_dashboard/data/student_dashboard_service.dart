import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';

class StudentDashboardService {
  Future<Map<String, dynamic>> getSidebarCounts(
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse(ApiEndpoints.studentSidebarCounts);

    final res = await http.get(uri, headers: headers);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final counts = body['counts'] as Map<String, dynamic>;
        return counts;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getDashboard(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.studentDashboard);

    final res = await http.get(uri, headers: headers);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final dashboardData = body['data'] as Map<String, dynamic>;
        return dashboardData;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getProfile(Map<String, String> headers) async {
    final uri = Uri.parse(ApiEndpoints.studentProfile);

    final res = await http.get(uri, headers: headers);

    try {
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        final profileData = body['data'] as Map<String, dynamic>;
        return profileData;
      } else {
        return {};
      }
    } catch (e) {
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
    final uri = Uri.parse(ApiEndpoints.realTimeCourses);
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
}
