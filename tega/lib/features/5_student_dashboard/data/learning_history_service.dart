import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class LearningHistoryService {
  static final LearningHistoryService _instance =
      LearningHistoryService._internal();
  factory LearningHistoryService() => _instance;
  LearningHistoryService._internal();

  final AuthService _authService = AuthService();

  /// Get student's overall learning progress
  Future<LearningStats> getLearningStats() async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentDashboard),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final dashboardData = data['data'];
          final userProgress = dashboardData['userProgress'];

          return LearningStats(
            totalLectures: 0, // Not available in dashboard data
            completedLectures: 0, // Not available in dashboard data
            totalTimeSpent:
                (userProgress['totalHours'] ?? 0) *
                60, // Convert hours to minutes
            coursesEnrolled:
                (userProgress['completedCourses'] ?? 0) +
                (userProgress['inProgress'] ?? 0),
            completionRate:
                userProgress['completedCourses'] != null &&
                    userProgress['inProgress'] != null
                ? (userProgress['completedCourses'] /
                      ((userProgress['completedCourses'] +
                                  userProgress['inProgress']) ==
                              0
                          ? 1
                          : (userProgress['completedCourses'] +
                                userProgress['inProgress'])) *
                      100)
                : 0.0,
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch learning stats');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch learning stats',
        );
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get student's progress for all courses
  Future<List<CourseProgress>> getAllCourseProgress() async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentDashboard),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final dashboardData = data['data'];
          final enrolledCourses = dashboardData['enrolledCourses'] ?? [];

          return enrolledCourses.map<CourseProgress>((course) {
            return CourseProgress(
              courseId: course['id'] ?? '',
              courseName: course['title'] ?? 'Unknown Course',
              courseDescription: '', // Not available in dashboard data
              courseImage: course['thumbnail'],
              totalModules: 0, // Not available in dashboard data
              completedModules: 0, // Not available in dashboard data
              totalLectures: 0, // Not available in dashboard data
              completedLectures: 0, // Not available in dashboard data
              progressPercentage: 0.0, // Not available in dashboard data
              lastAccessed: course['enrolledDate'] != null
                  ? DateTime.parse(course['enrolledDate'])
                  : DateTime.now(),
              completedAt: null, // Not available in dashboard data
              modules: [], // Not available in dashboard data
            );
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch course progress');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch course progress',
        );
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get student's progress for a specific course
  Future<CourseProgress> getCourseProgress(String courseId) async {
    try {
      // For now, return a placeholder since we don't have a specific course progress endpoint
      // This would need to be implemented in the backend
      throw Exception('Individual course progress endpoint not available');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get student's learning history (recent activities)
  Future<List<LearningActivity>> getLearningHistory() async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentDashboard),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final dashboardData = data['data'];
          final recentActivity = dashboardData['recentActivity'] ?? [];

          return recentActivity.map<LearningActivity>((activity) {
            return LearningActivity(
              id: activity['id'] ?? '',
              type: activity['type'] ?? 'lecture_completed',
              title: activity['title'] ?? 'Learning Activity',
              description: activity['description'] ?? '',
              courseId: activity['courseId'] ?? '',
              courseName:
                  activity['courseTitle'] ??
                  activity['courseName'] ??
                  'Unknown Course',
              timestamp: activity['timestamp'] != null
                  ? DateTime.parse(activity['timestamp'])
                  : DateTime.now(),
              metadata: activity['metadata'],
            );
          }).toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch learning history',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to fetch learning history',
        );
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

/// Learning statistics data model
class LearningStats {
  final int totalLectures;
  final int completedLectures;
  final int totalTimeSpent; // in minutes
  final int coursesEnrolled;
  final double completionRate;

  LearningStats({
    required this.totalLectures,
    required this.completedLectures,
    required this.totalTimeSpent,
    required this.coursesEnrolled,
    required this.completionRate,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      totalLectures: json['totalLectures'] ?? 0,
      completedLectures: json['completedLectures'] ?? 0,
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      coursesEnrolled: json['coursesEnrolled'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
    );
  }

  /// Get formatted time spent string
  String get formattedTimeSpent {
    if (totalTimeSpent < 60) {
      return '${totalTimeSpent}m';
    } else if (totalTimeSpent < 1440) {
      // less than 24 hours
      final hours = (totalTimeSpent / 60).floor();
      final minutes = totalTimeSpent % 60;
      return '${hours}h ${minutes}m';
    } else {
      final days = (totalTimeSpent / 1440).floor();
      final hours = ((totalTimeSpent % 1440) / 60).floor();
      return '${days}d ${hours}h';
    }
  }
}

/// Course progress data model
class CourseProgress {
  final String courseId;
  final String courseName;
  final String courseDescription;
  final String? courseImage;
  final int totalModules;
  final int completedModules;
  final int totalLectures;
  final int completedLectures;
  final double progressPercentage;
  final DateTime lastAccessed;
  final DateTime? completedAt;
  final List<ModuleProgress> modules;

  CourseProgress({
    required this.courseId,
    required this.courseName,
    required this.courseDescription,
    this.courseImage,
    required this.totalModules,
    required this.completedModules,
    required this.totalLectures,
    required this.completedLectures,
    required this.progressPercentage,
    required this.lastAccessed,
    this.completedAt,
    required this.modules,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] ?? json['_id'] ?? '',
      courseName: json['courseName'] ?? json['name'] ?? 'Unknown Course',
      courseDescription: json['courseDescription'] ?? json['description'] ?? '',
      courseImage: json['courseImage'] ?? json['image'],
      totalModules: json['totalModules'] ?? 0,
      completedModules: json['completedModules'] ?? 0,
      totalLectures: json['totalLectures'] ?? 0,
      completedLectures: json['completedLectures'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
      lastAccessed: DateTime.parse(
        json['lastAccessed'] ??
            json['updatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      modules: (json['modules'] as List<dynamic>? ?? [])
          .map((module) => ModuleProgress.fromJson(module))
          .toList(),
    );
  }

  /// Check if course is completed
  bool get isCompleted => progressPercentage >= 100;

  /// Get progress status text
  String get statusText {
    if (isCompleted) return 'Completed';
    if (progressPercentage > 0) return 'In Progress';
    return 'Not Started';
  }

  /// Get progress color
  Color get progressColor {
    if (isCompleted) return const Color(0xFF4CAF50);
    if (progressPercentage > 0) return const Color(0xFF9C88FF);
    return Colors.grey;
  }
}

/// Module progress data model
class ModuleProgress {
  final String moduleId;
  final String moduleName;
  final int totalLectures;
  final int completedLectures;
  final double progressPercentage;
  final DateTime? lastAccessed;

  ModuleProgress({
    required this.moduleId,
    required this.moduleName,
    required this.totalLectures,
    required this.completedLectures,
    required this.progressPercentage,
    this.lastAccessed,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId'] ?? json['_id'] ?? '',
      moduleName: json['moduleName'] ?? json['name'] ?? 'Unknown Module',
      totalLectures: json['totalLectures'] ?? 0,
      completedLectures: json['completedLectures'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : null,
    );
  }
}

/// Learning activity data model
class LearningActivity {
  final String id;
  final String
  type; // 'lecture_completed', 'course_enrolled', 'quiz_completed', etc.
  final String title;
  final String description;
  final String courseId;
  final String courseName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  LearningActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.courseId,
    required this.courseName,
    required this.timestamp,
    this.metadata,
  });

  factory LearningActivity.fromJson(Map<String, dynamic> json) {
    return LearningActivity(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? 'activity',
      title: json['title'] ?? 'Learning Activity',
      description: json['description'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? 'Unknown Course',
      timestamp: DateTime.parse(
        json['timestamp'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'],
    );
  }

  /// Get activity icon based on type
  IconData get icon {
    switch (type.toLowerCase()) {
      case 'lecture_completed':
        return Icons.play_circle_filled;
      case 'course_enrolled':
        return Icons.school;
      case 'quiz_completed':
        return Icons.quiz;
      case 'assignment_submitted':
        return Icons.assignment_turned_in;
      case 'certificate_earned':
        return Icons.emoji_events;
      default:
        return Icons.timeline;
    }
  }

  /// Get activity color based on type
  Color get color {
    switch (type.toLowerCase()) {
      case 'lecture_completed':
        return const Color(0xFF4CAF50);
      case 'course_enrolled':
        return const Color(0xFF2196F3);
      case 'quiz_completed':
        return const Color(0xFFFF9800);
      case 'assignment_submitted':
        return const Color(0xFF9C27B0);
      case 'certificate_earned':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF9C88FF);
    }
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}
