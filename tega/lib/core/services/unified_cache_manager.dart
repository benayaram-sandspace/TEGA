import 'package:tega/core/services/sqlite_cache_service.dart';

/// Unified cache manager to consolidate all caching operations
/// Provides a single interface for all cache services to use
class UnifiedCacheManager {
  static final UnifiedCacheManager _instance = UnifiedCacheManager._internal();
  factory UnifiedCacheManager() => _instance;
  UnifiedCacheManager._internal();

  final SQLiteCacheService _cache = SQLiteCacheService.instance;

  /// Store data in cache with category and TTL
  Future<void> store({
    required String key,
    required String category,
    required dynamic data,
    required Duration ttl,
  }) async {
    await _cache.set(key: key, category: category, value: data, ttl: ttl);
  }

  /// Retrieve data from cache
  Future<dynamic> retrieve({
    required String key,
    required String category,
  }) async {
    return await _cache.get(key: key, category: category);
  }

  /// Delete specific cache entry
  Future<void> delete({required String key, required String category}) async {
    await _cache.delete(key: key, category: category);
  }

  /// Delete all entries in a category
  Future<void> deleteCategory(String category) async {
    await _cache.deleteCategory(category);
  }

  /// Check if key exists and is valid
  Future<bool> has({required String key, required String category}) async {
    return await _cache.has(key: key, category: category);
  }

  /// Clear all expired entries
  Future<void> clearExpired() async {
    await _cache.clearExpired();
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await _cache.clearAll();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    return await _cache.getStats();
  }

  /// Get category list with entry counts
  Future<Map<String, int>> getCategoryStats() async {
    final stats = await _cache.getStats();
    return Map<String, int>.from(stats['byCategory'] ?? {});
  }

  /// Get total cache size
  Future<String> getCacheSize() async {
    final stats = await _cache.getStats();
    return '${stats['sizeMB']} MB';
  }

  /// Optimize cache by removing expired entries
  Future<int> optimize() async {
    final statsBefore = await _cache.getStats();
    final expiredBefore = statsBefore['expired'] as int;

    await _cache.clearExpired();

    return expiredBefore;
  }
}
