import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final AuthService _authService = AuthService();

  Future<List<AnnouncementModel>> getStudentAnnouncements() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentAnnouncements),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['announcements'] != null) {
          final List<dynamic> announcementsJson = data['announcements'];
          return announcementsJson
              .map((json) => AnnouncementModel.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch announcements');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch announcements',
        );
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String priority;
  final String audience;
  final String university;
  final String? principalName;
  final DateTime createdAt;
  final DateTime? expiresAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.audience,
    required this.university,
    this.principalName,
    required this.createdAt,
    this.expiresAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'normal',
      audience: json['audience'] ?? 'all',
      university: json['university'] ?? '',
      principalName: json['createdBy']?['principalName'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon => Icons.campaign;
  Color get color => const Color(0xFFE91E63);
}
