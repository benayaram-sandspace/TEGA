import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';

class StudentDashboardService {
  Future<Map<String, dynamic>> getSidebarCounts(
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse('$baseUrl/api/student/sidebar-counts');
    final res = await http.get(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return body['counts'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getDashboard(Map<String, String> headers) async {
    final uri = Uri.parse('$baseUrl/api/student/dashboard');
    final res = await http.get(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getProfile(Map<String, String> headers) async {
    final uri = Uri.parse('$baseUrl/api/student/profile');
    final res = await http.get(uri, headers: headers);
    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
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
}
