import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class ExamRepository {
  final AuthService _authService = AuthService();

  // Get exam by ID (fresh from backend)
  Future<Map<String, dynamic>> getExamById(String examId) async {
    final headers = await _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.examById(examId)),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Backend uses 'exam' key
        return Map<String, dynamic>.from(data['exam'] ?? {});
      }
    }

    throw Exception(
      'Failed to load exam details. Status code: ${response.statusCode}',
    );
  }

  // Get all exams
  Future<List<Map<String, dynamic>>> getAllExams() async {
    final headers = await _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminExamsAll),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] ?? data['exams'] ?? []);
      }
    }

    throw Exception(
      'Failed to load exams. Status code: ${response.statusCode}',
    );
  }

  // Get available courses for exam creation
  Future<List<Map<String, dynamic>>> getAvailableCourses() async {
    final headers = await _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminOffersCourses),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }

    throw Exception(
      'Failed to load available courses. Status code: ${response.statusCode}',
    );
  }

  // Create exam
  Future<Map<String, dynamic>> createExam(Map<String, dynamic> examData) async {
    final headers = await _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse(ApiEndpoints.adminCreateExam),
      headers: headers,
      body: json.encode(examData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }

    final errorData = json.decode(response.body);
    throw Exception(
      errorData['message'] ??
          'Failed to create exam. Status code: ${response.statusCode}',
    );
  }

  // Update exam
  Future<Map<String, dynamic>> updateExam(
    String examId,
    Map<String, dynamic> examData,
  ) async {
    final headers = await _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      Uri.parse(ApiEndpoints.adminUpdateExam(examId)),
      headers: headers,
      body: json.encode(examData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }

    final errorData = json.decode(response.body);
    throw Exception(
      errorData['message'] ??
          'Failed to update exam. Status code: ${response.statusCode}',
    );
  }

  // Delete exam
  Future<void> deleteExam(String examId) async {
    final headers = await _authService.getAuthHeaders();

    final response = await http.delete(
      Uri.parse(ApiEndpoints.adminDeleteExam(examId)),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to delete exam. Status code: ${response.statusCode}',
      );
    }
  }

  // Get registrations for a specific exam
  Future<List<Map<String, dynamic>>> getExamRegistrations(String examId) async {
    final headers = await _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminExamRegistrations(examId)),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // backend could return { registrations: [] } or { data: [] }
        final list = (data['registrations'] ?? data['data'] ?? []) as List<dynamic>;
        return List<Map<String, dynamic>>.from(list);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch registrations');
      }
    }

    throw Exception('Failed to fetch registrations: ${response.statusCode}');
  }

  // Get results for admin by exam (using query param examId)
  Future<List<Map<String, dynamic>>> getAdminExamResults(String examId) async {
    final headers = await _authService.getAuthHeaders();
    // Build URL with query params
    final url = ApiEndpoints.buildUrlWithParams(
      ApiEndpoints.adminExamResults,
      {'examId': examId},
    );
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Backend returns grouped results in 'results' array
        final list = (data['results'] ?? data['data'] ?? []) as List<dynamic>;
        return List<Map<String, dynamic>>.from(list);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch results');
      }
    }
    throw Exception('Failed to fetch results: ${response.statusCode}');
  }

  // Publish exam results for a specific exam and date
  Future<Map<String, dynamic>> publishExamResults({
    required String examId,
    required String examDate,
    required bool publish,
  }) async {
    final headers = await _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse(ApiEndpoints.adminPublishExamResults),
      headers: headers,
      body: json.encode({
        'examId': examId,
        'examDate': examDate,
        'publish': publish,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }

    final errorData = json.decode(response.body);
    throw Exception(
      errorData['message'] ?? 'Failed to publish exam results: ${response.statusCode}',
    );
  }
}

