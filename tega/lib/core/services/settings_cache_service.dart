import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for settings data
/// Provides caching with TTL (Time To Live) for account settings
class SettingsCacheService {
  static final SettingsCacheService _instance =
      SettingsCacheService._internal();
  factory SettingsCacheService() => _instance;
  SettingsCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _accountDataKey = 'settings_account_data';
  static const String _cacheTimestampKey = 'settings_cache_timestamp';

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

  /// Get cached account data if valid
  Future<Map<String, dynamic>?> getAccountData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearAccountData();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_accountDataKey);
      if (dataJson == null) return null;
      return json.decode(dataJson) as Map<String, dynamic>;
    } catch (e) {
      await clearAccountData();
      return null;
    }
  }

  /// Set account data in cache
  Future<void> setAccountData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_accountDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Clear account data cache
  Future<void> clearAccountData() async {
    await _ensurePrefs();
    await _prefs?.remove(_accountDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await clearAccountData();
  }
}
