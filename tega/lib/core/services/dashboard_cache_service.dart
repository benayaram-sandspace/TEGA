import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for student dashboard data
/// Provides caching with TTL (Time To Live) for dashboard, sidebar counts, and profile data
class DashboardCacheService {
  static final DashboardCacheService _instance = DashboardCacheService._internal();
  factory DashboardCacheService() => _instance;
  DashboardCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _dashboardDataKey = 'dashboard_data';
  static const String _sidebarCountsKey = 'sidebar_counts';
  static const String _profileDataKey = 'profile_data';
  static const String _cacheTimestampKey = 'cache_timestamp';

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

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getDashboardData() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString(_dashboardDataKey);
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

      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached sidebar counts
  Future<Map<String, dynamic>?> getSidebarCounts() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString(_sidebarCountsKey);
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

      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached profile data
  Future<Map<String, dynamic>?> getProfileData() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString(_profileDataKey);
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

      return json.decode(dataJson) as Map<String, dynamic>;
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

      final dashboardJson = _prefs?.getString(_dashboardDataKey);
      final sidebarJson = _prefs?.getString(_sidebarCountsKey);
      final profileJson = _prefs?.getString(_profileDataKey);

      if (dashboardJson == null || sidebarJson == null || profileJson == null) {
        return null;
      }

      return {
        'dashboard': json.decode(dashboardJson) as Map<String, dynamic>,
        'sidebarCounts': json.decode(sidebarJson) as Map<String, dynamic>,
        'profile': json.decode(profileJson) as Map<String, dynamic>,
      };
    } catch (e) {
      return null;
    }
  }

  /// Cache dashboard data
  Future<void> setDashboardData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    try {
      final dataJson = json.encode(data);
      await _prefs?.setString(_dashboardDataKey, dataJson);
      await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache sidebar counts
  Future<void> setSidebarCounts(Map<String, dynamic> counts) async {
    await _ensurePrefs();
    try {
      final countsJson = json.encode(counts);
      await _prefs?.setString(_sidebarCountsKey, countsJson);
      await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache profile data
  Future<void> setProfileData(Map<String, dynamic> profile) async {
    await _ensurePrefs();
    try {
      final profileJson = json.encode(profile);
      await _prefs?.setString(_profileDataKey, profileJson);
      await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache all data at once
  Future<void> setAllData({
    required Map<String, dynamic> dashboard,
    required Map<String, dynamic> sidebarCounts,
    required Map<String, dynamic> profile,
  }) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString(_dashboardDataKey, json.encode(dashboard));
      await _prefs?.setString(_sidebarCountsKey, json.encode(sidebarCounts));
      await _prefs?.setString(_profileDataKey, json.encode(profile));
      await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    try {
      await _prefs?.remove(_dashboardDataKey);
      await _prefs?.remove(_sidebarCountsKey);
      await _prefs?.remove(_profileDataKey);
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

  /// Get cache age (time since last cache update)
  Future<Duration?> getCacheAge() async {
    await _ensurePrefs();
    try {
      final timestamp = _prefs?.getString(_cacheTimestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime);
    } catch (e) {
      return null;
    }
  }
}

