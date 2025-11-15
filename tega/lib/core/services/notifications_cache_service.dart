import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for notifications data
/// Provides caching with TTL (Time To Live) for notifications
class NotificationsCacheService {
  static final NotificationsCacheService _instance = NotificationsCacheService._internal();
  factory NotificationsCacheService() => _instance;
  NotificationsCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _notificationsDataKey = 'notifications_data';
  static const String _cacheTimestampKey = 'notifications_cache_timestamp';

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

  /// Get cached notifications data if valid
  Future<List<Map<String, dynamic>>?> getNotificationsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_notificationsDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Set notifications data in cache
  Future<void> setNotificationsData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_notificationsDataKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_notificationsDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

