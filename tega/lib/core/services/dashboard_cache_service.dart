import 'package:tega/core/services/sqlite_cache_service.dart';

/// Cache service for student dashboard data
/// Provides caching with TTL (Time To Live) for dashboard, sidebar counts, and profile data
class DashboardCacheService {
  static final DashboardCacheService _instance =
      DashboardCacheService._internal();
  factory DashboardCacheService() => _instance;
  DashboardCacheService._internal();

  final SQLiteCacheService _cache = SQLiteCacheService.instance;

  // Cache keys
  static const String _dashboardDataKey = 'dashboard_data';
  static const String _sidebarCountsKey = 'sidebar_counts';
  static const String _profileDataKey = 'profile_data';
  static const String _category = 'student_dashboard';

  // Cache TTL - 10 minutes
  static const Duration _cacheTTL = Duration(minutes: 10);

  /// Initialize the cache service
  Future<void> initialize() async {
    // SQLite cache initializes automatically
  }

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final data = await _cache.get(
        key: _dashboardDataKey,
        category: _category,
      );
      return data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Get cached sidebar counts
  Future<Map<String, dynamic>?> getSidebarCounts() async {
    try {
      final data = await _cache.get(
        key: _sidebarCountsKey,
        category: _category,
      );
      return data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Get cached profile data
  Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final data = await _cache.get(key: _profileDataKey, category: _category);
      return data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Get all cached data at once
  Future<Map<String, dynamic>?> getAllCachedData() async {
    try {
      final dashboard = await getDashboardData();
      final sidebarCounts = await getSidebarCounts();
      final profile = await getProfileData();

      if (dashboard == null || sidebarCounts == null || profile == null) {
        return null;
      }

      return {
        'dashboard': dashboard,
        'sidebarCounts': sidebarCounts,
        'profile': profile,
      };
    } catch (e) {
      return null;
    }
  }

  /// Cache dashboard data
  Future<void> setDashboardData(Map<String, dynamic> data) async {
    try {
      await _cache.set(
        key: _dashboardDataKey,
        category: _category,
        value: data,
        ttl: _cacheTTL,
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache sidebar counts
  Future<void> setSidebarCounts(Map<String, dynamic> counts) async {
    try {
      await _cache.set(
        key: _sidebarCountsKey,
        category: _category,
        value: counts,
        ttl: _cacheTTL,
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Cache profile data
  Future<void> setProfileData(Map<String, dynamic> profile) async {
    try {
      await _cache.set(
        key: _profileDataKey,
        category: _category,
        value: profile,
        ttl: _cacheTTL,
      );
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
    try {
      await setDashboardData(dashboard);
      await setSidebarCounts(sidebarCounts);
      await setProfileData(profile);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cache.deleteCategory(_category);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Check if cache is valid (not expired)
  Future<bool> isCacheValid() async {
    try {
      return await _cache.has(key: _dashboardDataKey, category: _category);
    } catch (e) {
      return false;
    }
  }

  /// Get cache age (not directly supported by SQLite cache)
  Future<Duration?> getCacheAge() async {
    // SQLite cache handles TTL internally
    return null;
  }
}
