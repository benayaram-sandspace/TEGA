import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for exam results data
/// Provides caching with TTL (Time To Live) for exam results
class ResultsCacheService {
  static final ResultsCacheService _instance = ResultsCacheService._internal();
  factory ResultsCacheService() => _instance;
  ResultsCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _resultsDataKey = 'results_data';
  static const String _cacheTimestampKey = 'results_cache_timestamp';

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

  /// Get cached results data if valid
  Future<List<Map<String, dynamic>>?> getResultsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_resultsDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Set results data in cache
  Future<void> setResultsData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_resultsDataKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_resultsDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

