import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/3_admin_panel/data/models/offer_model.dart';

class OfferRepository {
  final AuthService _authService = AuthService();

  // Get all offers with pagination and filters
  Future<Map<String, dynamic>> getOffers({
    int page = 1,
    int limit = 10,
    String? institute,
    String? status,
  }) async {
    final headers = _authService.getAuthHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (institute != null) queryParams['institute'] = institute;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      ApiEndpoints.adminOffers,
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> offersJson = data['data'];
        final offers = offersJson.map((json) => Offer.fromJson(json)).toList();
        return {'offers': offers, 'pagination': data['pagination']};
      }
    }

    throw Exception(
      'Failed to load offers. Status code: ${response.statusCode}',
    );
  }

  // Get single offer by ID
  Future<Offer> getOfferById(String id) async {
    final headers = _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminOfferById(id)),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Offer.fromJson(data['data']);
      }
    }

    throw Exception(
      'Failed to load offer. Status code: ${response.statusCode}',
    );
  }

  // Create new offer
  Future<Offer> createOffer(Map<String, dynamic> offerData) async {
    final headers = _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse(ApiEndpoints.adminCreateOffer),
      headers: headers,
      body: json.encode(offerData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Offer.fromJson(data['data']);
      }
    }

    final errorData = json.decode(response.body);
    throw Exception(
      errorData['message'] ??
          'Failed to create offer. Status code: ${response.statusCode}',
    );
  }

  // Update offer
  Future<Offer> updateOffer(String id, Map<String, dynamic> offerData) async {
    final headers = _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      Uri.parse(ApiEndpoints.adminUpdateOffer(id)),
      headers: headers,
      body: json.encode(offerData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Offer.fromJson(data['data']);
      }
    }

    final errorData = json.decode(response.body);
    throw Exception(
      errorData['message'] ??
          'Failed to update offer. Status code: ${response.statusCode}',
    );
  }

  // Delete offer
  Future<void> deleteOffer(String id) async {
    final headers = _authService.getAuthHeaders();

    final response = await http.delete(
      Uri.parse(ApiEndpoints.adminDeleteOffer(id)),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to delete offer. Status code: ${response.statusCode}',
      );
    }
  }

  // Toggle offer status
  Future<Offer> toggleOfferStatus(String id) async {
    final headers = _authService.getAuthHeaders();

    final response = await http.patch(
      Uri.parse(ApiEndpoints.adminToggleOffer(id)),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Offer.fromJson(data['data']);
      }
    }

    final errorData = json.decode(response.body);
    throw Exception(
      errorData['message'] ??
          'Failed to toggle offer status. Status code: ${response.statusCode}',
    );
  }

  // Get offer statistics
  Future<Map<String, dynamic>> getOfferStats() async {
    final headers = _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminOffersStats),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }

    throw Exception(
      'Failed to load offer statistics. Status code: ${response.statusCode}',
    );
  }

  // Get available courses for offer creation
  Future<List<Map<String, dynamic>>> getAvailableCourses() async {
    final headers = _authService.getAuthHeaders();

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

  // Get available TEGA exams for offer creation
  Future<List<Map<String, dynamic>>> getAvailableTegaExams() async {
    final headers = _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminOffersTegaExams),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }

    throw Exception(
      'Failed to load available TEGA exams. Status code: ${response.statusCode}',
    );
  }

  // Get available institutes
  Future<List<String>> getAvailableInstitutes() async {
    final headers = _authService.getAuthHeaders();

    final response = await http.get(
      Uri.parse(ApiEndpoints.adminOffersInstitutes),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<String>.from(data['data']);
      }
    }

    throw Exception(
      'Failed to load available institutes. Status code: ${response.statusCode}',
    );
  }
}
