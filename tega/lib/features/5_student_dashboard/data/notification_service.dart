import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AuthService _authService = AuthService();

  /// Get all notifications for the current student
  Future<List<NotificationModel>> getStudentNotifications() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentNotifications),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          final List<dynamic> notificationsJson = data['notifications'];
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch notifications');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch notifications',
        );
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Mark notifications as read (using the mark-read endpoint)
  Future<bool> markNotificationsAsRead() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse(ApiEndpoints.studentMarkNotificationsRead),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to mark notifications as read',
        );
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

/// Notification data model
class NotificationModel {
  final String id;
  final String title;
  final String? message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'],
      type: json['type'] ?? 'general',
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Get formatted time ago string
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

  /// Get notification icon based on type
  IconData get icon {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'exam':
        return Icons.quiz;
      case 'course':
        return Icons.school;
      case 'payment':
        return Icons.payment;
      case 'announcement':
        return Icons.campaign;
      case 'reminder':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color based on type
  Color get color {
    switch (type.toLowerCase()) {
      case 'assignment':
        return const Color(0xFF4CAF50);
      case 'exam':
        return const Color(0xFF2196F3);
      case 'course':
        return const Color(0xFF6B5FFF);
      case 'payment':
        return const Color(0xFFFF9800);
      case 'announcement':
        return const Color(0xFFE91E63);
      case 'reminder':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF6B5FFF);
    }
  }
}
