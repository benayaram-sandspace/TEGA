import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for placement prep data
/// Provides caching with TTL (Time To Live) for placement prep, companies, and skill assessments
class PlacementPrepCacheService {
  static final PlacementPrepCacheService _instance =
      PlacementPrepCacheService._internal();
  factory PlacementPrepCacheService() => _instance;
  PlacementPrepCacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String _placementPrepDataKey = 'placement_prep_data';
  static const String _companiesDataKey = 'companies_data';
  static const String _skillAssessmentsDataKey = 'skill_assessments_data';
  static const String _cacheTimestampKey = 'placement_prep_cache_timestamp';

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

  /// Get cached placement prep data if valid
  Future<Map<String, dynamic>?> getPlacementPrepData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearPlacementPrepCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_placementPrepDataKey);
      return dataJson != null ? json.decode(dataJson) : null;
    } catch (e) {
      await clearPlacementPrepCache();
      return null;
    }
  }

  /// Set placement prep data in cache
  Future<void> setPlacementPrepData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_placementPrepDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached companies data if valid
  Future<List<Map<String, dynamic>>?> getCompaniesData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearCompaniesCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_companiesDataKey);
      if (dataJson == null) return null;
      final List<dynamic> decoded = json.decode(dataJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      await clearCompaniesCache();
      return null;
    }
  }

  /// Set companies data in cache
  Future<void> setCompaniesData(List<Map<String, dynamic>> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_companiesDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cached skill assessments data if valid
  Future<Map<String, dynamic>?> getSkillAssessmentsData() async {
    await _ensurePrefs();
    if (!(await _isCacheValid())) {
      await clearSkillAssessmentsCache();
      return null;
    }

    try {
      final dataJson = _prefs?.getString(_skillAssessmentsDataKey);
      return dataJson != null ? json.decode(dataJson) : null;
    } catch (e) {
      await clearSkillAssessmentsCache();
      return null;
    }
  }

  /// Set skill assessments data in cache
  Future<void> setSkillAssessmentsData(Map<String, dynamic> data) async {
    await _ensurePrefs();
    await _prefs?.setString(_skillAssessmentsDataKey, json.encode(data));
    await _prefs?.setString(
      _cacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Clear placement prep cache
  Future<void> clearPlacementPrepCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_placementPrepDataKey);
  }

  /// Clear companies cache
  Future<void> clearCompaniesCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_companiesDataKey);
  }

  /// Clear skill assessments cache
  Future<void> clearSkillAssessmentsCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_skillAssessmentsDataKey);
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _ensurePrefs();
    await _prefs?.remove(_placementPrepDataKey);
    await _prefs?.remove(_companiesDataKey);
    await _prefs?.remove(_skillAssessmentsDataKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}
