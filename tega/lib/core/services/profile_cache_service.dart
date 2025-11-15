import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for profile data
/// Provides caching with TTL (Time To Live) for student profile information
class ProfileCacheService {
  static final ProfileCacheService _instance = ProfileCacheService._internal();
  factory ProfileCacheService() => _instance;
  ProfileCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _profileDataKey = 'profile_data';
  static const String _cacheTimestampKey = 'profile_cache_timestamp';

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

  /// Get cached profile data if valid
  Future<Map<String, dynamic>?> getProfileData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_profileDataKey);
      if (dataJson == null) return null;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Set profile data in cache
  Future<void> setProfileData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_profileDataKey, json.encode(data));
    await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_profileDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}

