import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class NotificationService {
  final AuthService _authService = AuthService();
  // Get all admin notifications
  Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminNotifications),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to load notifications');
        }
      } else {
        throw Exception(
          'Failed to load notifications. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching notifications: ${e.toString()}');
    }
  }

  // Get notification by ID
  Future<Map<String, dynamic>> getNotificationById(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminNotificationById(id)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['notification'];
        } else {
          throw Exception(data['message'] ?? 'Failed to load notification');
        }
      } else {
        throw Exception(
          'Failed to load notification. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching notification: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse(ApiEndpoints.adminNotificationMarkRead(id)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to mark notification as read. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error marking notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse(ApiEndpoints.adminNotificationMarkAllRead),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to mark all notifications as read. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Error marking all notifications as read: ${e.toString()}',
      );
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiEndpoints.adminNotificationById(id)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to delete notification. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting notification: ${e.toString()}');
    }
  }

  // Create notification
  Future<Map<String, dynamic>> createNotification({
    required String message,
    required String type,
    required String recipient,
    required String recipientModel,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse(ApiEndpoints.adminNotifications),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'type': type,
          'recipient': recipient,
          'recipientModel': recipientModel,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['notification'];
        } else {
          throw Exception(data['message'] ?? 'Failed to create notification');
        }
      } else {
        throw Exception(
          'Failed to create notification. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating notification: ${e.toString()}');
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final notifications = await getAdminNotifications();

      final totalNotifications = notifications.length;
      final sentNotifications = notifications
          .where((n) => n['status']?.toString() == 'sent')
          .length;
      final draftNotifications = notifications
          .where((n) => n['status']?.toString() == 'draft')
          .length;
      final unreadNotifications = notifications
          .where((n) => n['isRead'] == false)
          .length;

      // Get this month's notifications
      final now = DateTime.now();
      final thisMonthNotifications = notifications.where((n) {
        try {
          final createdAt = DateTime.parse(n['createdAt']?.toString() ?? '');
          return createdAt.year == now.year && createdAt.month == now.month;
        } catch (e) {
          return false;
        }
      }).length;

      return {
        'totalNotifications': totalNotifications,
        'sentNotifications': sentNotifications,
        'draftNotifications': draftNotifications,
        'unreadNotifications': unreadNotifications,
        'thisMonthNotifications': thisMonthNotifications,
      };
    } catch (e) {
      throw Exception('Error fetching notification stats: ${e.toString()}');
    }
  }
}
