import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for learning history data
/// Provides caching with TTL (Time To Live) for learning stats and enrolled courses
class LearningHistoryCacheService {
  static final LearningHistoryCacheService _instance = LearningHistoryCacheService._internal();
  factory LearningHistoryCacheService() => _instance;
  LearningHistoryCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _learningStatsKey = 'learning_stats_data';
  static const String _enrolledCoursesKey = 'learning_history_enrolled_courses';
  static const String _cacheTimestampKey = 'learning_history_cache_timestamp';

  // Cache TTL - 5 minutes
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if the cache is valid (not expired)
  Future<bool> _isCacheValid() async {
    await _ensurePrefs();
    final timestamp = _prefs?.getString(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime) <= _cacheTTL;
  }

  /// Get cached learning stats data if valid
  Future<Map<String, dynamic>?> getLearningStats() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearLearningStats();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_learningStatsKey);
      return dataJson != null ? json.decode(dataJson) : null;
    } catch (e) {
      await clearLearningStats();
      return null;
    }
  }

  /// Set learning stats data in cache
  Future<void> setLearningStats(Map<String, dynamic> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_learningStatsKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Get cached enrolled courses data if valid
  Future<List<Map<String, dynamic>>?> getEnrolledCourses() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearEnrolledCourses();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_enrolledCoursesKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) {
        final map = e as Map<String, dynamic>;
        // Convert enrollmentDate from string to DateTime
        if (map['enrollmentDate'] is String) {
          map['enrollmentDate'] = DateTime.parse(map['enrollmentDate'] as String);
        }
        return map;
      }).toList();
    } catch (e) {
      await clearEnrolledCourses();
      return null;
    }
  }

  /// Set enrolled courses data in cache
  Future<void> setEnrolledCourses(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    // Convert DateTime to string for JSON encoding
    final serializedData = data.map((course) {
      final courseCopy = Map<String, dynamic>.from(course);
      if (courseCopy['enrollmentDate'] is DateTime) {
        courseCopy['enrollmentDate'] = (courseCopy['enrollmentDate'] as DateTime).toIso8601String();
      }
      return courseCopy;
    }).toList();
    await _prefs?.setString(_enrolledCoursesKey, json.encode(serializedData));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Clear learning stats cache
  Future<void> clearLearningStats() async {
    await _ensurePrefs();
    await _prefs?.remove(_learningStatsKey);
  }

  /// Clear enrolled courses cache
  Future<void> clearEnrolledCourses() async {
    await _ensurePrefs();
    await _prefs?.remove(_enrolledCoursesKey);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_learningStatsKey);
    await _prefs?.remove(_enrolledCoursesKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

