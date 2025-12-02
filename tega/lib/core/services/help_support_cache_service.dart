import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for help & support data
/// Provides caching with TTL (Time To Live) for help articles and categories
class HelpSupportCacheService {
  static final HelpSupportCacheService _instance =
      HelpSupportCacheService._internal();
  factory HelpSupportCacheService() => _instance;
  HelpSupportCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _categoriesDataKey = 'help_categories_data';
  static const String _articlesDataKey = 'help_articles_data';
  static const String _cacheTimestampKey = 'help_support_cache_timestamp';

  // Cache TTL - 1 hour (help content doesn't change frequently)
  static const Duration _cacheTTL = Duration(hours: 1);

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

  /// Get cached categories data if valid
  Future<List<Map<String, dynamic>>?> getCategoriesData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_categoriesDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Set categories data in cache
  Future<void> setCategoriesData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_categoriesDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached articles data if valid
  Future<List<Map<String, dynamic>>?> getArticlesData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_articlesDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Set articles data in cache
  Future<void> setArticlesData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_articlesDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_categoriesDataKey);
    await _prefs?.remove(_articlesDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}
