import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for images that uses file-based storage
/// This avoids SQLite dependency issues
class CustomImageCacheManager {
  static CacheManager? _instance;

  static Future<CacheManager> getInstance() async {
    if (_instance != null) return _instance!;

    _instance = CacheManager(
      Config(
        'imageCache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: 'imageCache.db'),
        fileService: HttpFileService(),
      ),
    );

    return _instance!;
  }
}

