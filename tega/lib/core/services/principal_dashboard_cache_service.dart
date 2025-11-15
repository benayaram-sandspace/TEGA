import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for principal dashboard data
/// Provides caching with TTL (Time To Live) for dashboard data
class PrincipalDashboardCacheService {
  static final PrincipalDashboardCacheService _instance =
      PrincipalDashboardCacheService._internal();
  factory PrincipalDashboardCacheService() => _instance;
  PrincipalDashboardCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _dashboardDataKey = 'principal_dashboard_data';
  static const String _cacheTimestampKey = 'principal_dashboard_cache_timestamp';

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

  /// Set dashboard data in cache
  Future<void> setDashboardData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString(_dashboardDataKey, json.encode(data));
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

  /// Get cached principal data
  Future<Map<String, dynamic>?> getPrincipalData() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString('principal_data');
      if (dataJson == null) return null;

      final timestamp = _prefs?.getString('principal_data_timestamp');
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await _prefs?.remove('principal_data');
        await _prefs?.remove('principal_data_timestamp');
        return null;
      }

      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Set principal data in cache
  Future<void> setPrincipalData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString('principal_data', json.encode(data));
      await _prefs?.setString('principal_data_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached students data
  Future<List<dynamic>?> getStudentsData() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString('principal_students_data');
      if (dataJson == null) return null;

      final timestamp = _prefs?.getString('principal_students_timestamp');
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await _prefs?.remove('principal_students_data');
        await _prefs?.remove('principal_students_timestamp');
        return null;
      }

      return json.decode(dataJson) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Set students data in cache
  Future<void> setStudentsData(List<dynamic> data) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString('principal_students_data', json.encode(data));
      await _prefs?.setString('principal_students_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached analytics data
  Future<Map<String, dynamic>?> getAnalyticsData() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString('principal_analytics_data');
      if (dataJson == null) return null;

      final timestamp = _prefs?.getString('principal_analytics_timestamp');
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await _prefs?.remove('principal_analytics_data');
        await _prefs?.remove('principal_analytics_timestamp');
        return null;
      }

      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Set analytics data in cache
  Future<void> setAnalyticsData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString('principal_analytics_data', json.encode(data));
      await _prefs?.setString('principal_analytics_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get cached reports/insights data
  Future<Map<String, dynamic>?> getReportsInsightsData() async {
    await _ensurePrefs();
    try {
      final dataJson = _prefs?.getString('principal_reports_insights_data');
      if (dataJson == null) return null;

      final timestamp = _prefs?.getString('principal_reports_insights_timestamp');
      if (timestamp == null) return null;

      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > _cacheTTL) {
        await _prefs?.remove('principal_reports_insights_data');
        await _prefs?.remove('principal_reports_insights_timestamp');
        return null;
      }

      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Set reports/insights data in cache
  Future<void> setReportsInsightsData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    try {
      await _prefs?.setString('principal_reports_insights_data', json.encode(data));
      await _prefs?.setString('principal_reports_insights_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle errors
    }
  }

  // Connectivity state tracking
  bool _isCurrentlyOffline = false;
  bool _hasShownOfflineToast = false;
  bool _hasShownOnlineToast = false;

  /// Handle offline state and show toast
  void handleOfflineState(BuildContext? context) {
    if (!_isCurrentlyOffline && !_hasShownOfflineToast) {
      _isCurrentlyOffline = true;
      _hasShownOfflineToast = true;
      _hasShownOnlineToast = false; // Reset online toast flag
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Offline'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Handle online state and show toast
  void handleOnlineState(BuildContext? context) {
    if (_isCurrentlyOffline && !_hasShownOnlineToast) {
      _isCurrentlyOffline = false;
      _hasShownOnlineToast = true;
      _hasShownOfflineToast = false; // Reset offline toast flag
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Back online'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

