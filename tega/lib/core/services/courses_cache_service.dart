import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for courses data
/// Provides caching with TTL (Time To Live) for courses and enrolled courses
class CoursesCacheService {
  static final CoursesCacheService _instance = CoursesCacheService._internal();
  factory CoursesCacheService() => _instance;
  CoursesCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _allCoursesKey = 'all_courses';
  static const String _enrolledCoursesKey = 'enrolled_courses';
  static const String _cacheTimestampKey = 'courses_cache_timestamp';

  // Cache TTL - 10 minutes (courses don't change as frequently)
  static const Duration _cacheTTL = Duration(minutes: 10);

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get cached all courses
  Future<List<dynamic>?> getAllCourses() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString(_allCoursesKey);
      if (dataJson == null) return null;

      final timestamp = _prefs?.getString(_cacheTimestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await clearCache();
        return null;
      }

      return json.decode(dataJson) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached enrolled courses
  Future<List<dynamic>?> getEnrolledCourses() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString(_enrolledCoursesKey);
      if (dataJson == null) return null;

      final timestamp = _prefs?.getString(_cacheTimestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await clearCache();
        return null;
      }

      return json.decode(dataJson) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get all cached data at once
  Future<Map<String, dynamic>?> getAllCachedData() async {
    await _ensurePrefs();
    try {
      final timestamp = _prefs?.getString(_cacheTimestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await clearCache();
        return null;
      }

      final allCoursesJson = _prefs?.getString(_allCoursesKey);
      final enrolledCoursesJson = _prefs?.getString(_enrolledCoursesKey);

      if (allCoursesJson == null || enrolledCoursesJson == null) {
        return null;
      }

      return {
        'allCourses': json.decode(allCoursesJson) as List<dynamic>,
        'enrolledCourses': json.decode(enrolledCoursesJson) as List<dynamic>,
      };
    } catch (e) {
      return null;
    }
  }

  /// Cache all courses
  Future<void> setAllCourses(List<dynamic> courses) async {
    await _ensurePrefs();
    try {
      final dataJson = json.encode(courses);
      await _prefs?.setString(_allCoursesKey, dataJson);
      await _prefs?.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache enrolled courses
  Future<void> setEnrolledCourses(List<dynamic> enrolledCourses) async {
    await _ensurePrefs();
    try {
      final dataJson = json.encode(enrolledCourses);
      await _prefs?.setString(_enrolledCoursesKey, dataJson);
      await _prefs?.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache all data at once
  Future<void> setAllData({
    required List<dynamic> allCourses,
    required List<dynamic> enrolledCourses,
  }) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString(_allCoursesKey, json.encode(allCourses));
      await _prefs?.setString(
        _enrolledCoursesKey,
        json.encode(enrolledCourses),
      );
      await _prefs?.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    try {
      await _prefs?.remove(_allCoursesKey);
      await _prefs?.remove(_enrolledCoursesKey);
      await _prefs?.remove(_cacheTimestampKey);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Check if cache is valid (not expired)
  Future<bool> isCacheValid() async {
    await _ensurePrefs();
    try {
      final timestamp = _prefs?.getString(_cacheTimestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) <= _cacheTTL;
    } catch (e) {
      return false;
    }
  }
}
