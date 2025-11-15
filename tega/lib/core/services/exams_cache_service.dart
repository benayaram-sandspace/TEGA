import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for exams data
/// Provides caching with TTL (Time To Live) for exams and enrolled courses
class ExamsCacheService {
  static final ExamsCacheService _instance = ExamsCacheService._internal();
  factory ExamsCacheService() => _instance;
  ExamsCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _examsDataKey = 'exams_data';
  static const String _enrolledCoursesKey = 'enrolled_courses_data';
  static const String _cacheTimestampKey = 'exams_cache_timestamp';

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

  /// Get cached exams data if valid
  Future<List<Map<String, dynamic>>?> getExamsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearExamsCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_examsDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearExamsCache();
      return null;
    }
  }

  /// Set exams data in cache
  Future<void> setExamsData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_examsDataKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Get cached enrolled courses data if valid
  Future<List<Map<String, dynamic>>?> getEnrolledCoursesData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearEnrolledCoursesCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_enrolledCoursesKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearEnrolledCoursesCache();
      return null;
    }
  }

  /// Set enrolled courses data in cache
  Future<void> setEnrolledCoursesData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_enrolledCoursesKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Clear exams cache
  Future<void> clearExamsCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_examsDataKey);
  }

  /// Clear enrolled courses cache
  Future<void> clearEnrolledCoursesCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_enrolledCoursesKey);
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_examsDataKey);
    await _prefs?.remove(_enrolledCoursesKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

