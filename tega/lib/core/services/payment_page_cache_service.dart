import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for payment page data (courses and exams)
/// Provides caching with TTL (Time To Live) for payment listings
class PaymentPageCacheService {
  static final PaymentPageCacheService _instance = PaymentPageCacheService._internal();
  factory PaymentPageCacheService() => _instance;
  PaymentPageCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _coursesDataKey = 'payment_page_courses_data';
  static const String _examsDataKey = 'payment_page_exams_data';
  static const String _cacheTimestampKey = 'payment_page_cache_timestamp';

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

  /// Get cached courses data if valid
  Future<List<Map<String, dynamic>>?> getCoursesData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCourses();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_coursesDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCourses();
      return null;
    }
  }

  /// Set courses data in cache
  Future<void> setCoursesData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_coursesDataKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Get cached exams data if valid
  Future<List<Map<String, dynamic>>?> getExamsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearExams();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_examsDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearExams();
      return null;
    }
  }

  /// Set exams data in cache
  Future<void> setExamsData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_examsDataKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Clear courses cache
  Future<void> clearCourses() async {
    await _ensurePrefs();
    await _prefs?.remove(_coursesDataKey);
  }

  /// Clear exams cache
  Future<void> clearExams() async {
    await _ensurePrefs();
    await _prefs?.remove(_examsDataKey);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_coursesDataKey);
    await _prefs?.remove(_examsDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

