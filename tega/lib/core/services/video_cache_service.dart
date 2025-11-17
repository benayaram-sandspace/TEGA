import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Secure video cache service
/// Stores videos in app-specific directory (not accessible to users)
/// Similar to Netflix - downloaded but not visible in file manager
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  Directory? _cacheDirectory;
  SharedPreferences? _prefs;
  static const String _cacheMetadataKey = 'video_cache_metadata';

  // Cache configuration
  static const int _maxCacheSizeMB = 2048; // 2GB max cache
  static const Duration _cacheExpiryDays = Duration(days: 30); // Videos expire after 30 days

  // Track active downloads
  final Map<String, Future<String?>> _activeDownloads = {};

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      // Get app-specific directory (not accessible to users)
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/video_cache');
      
      // Create cache directory if it doesn't exist
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      // Clean up expired videos on startup
      await _cleanupExpiredVideos();
      
      // Manage cache size
      await _manageCacheSize();
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    if (_cacheDirectory == null) {
      await initialize();
    }
    return _cacheDirectory!;
  }

  /// Generate cache key from video URL
  String _generateCacheKey(String videoUrl) {
    final bytes = utf8.encode(videoUrl);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get cached video file path if exists
  Future<String?> getCachedVideoPath(String videoUrl) async {
    try {
      final cacheKey = _generateCacheKey(videoUrl);
      final cacheDir = await _getCacheDirectory();
      final videoFile = File('${cacheDir.path}/$cacheKey.mp4');
      
      if (await videoFile.exists()) {
        // Check if video is expired
        final metadata = await _getVideoMetadata(cacheKey);
        if (metadata != null) {
          final cachedDate = DateTime.parse(metadata['cachedDate'] as String);
          final now = DateTime.now();
          
          if (now.difference(cachedDate) > _cacheExpiryDays) {
            // Video expired, delete it
            await videoFile.delete();
            await _removeVideoMetadata(cacheKey);
            return null;
          }
          
          // Update last accessed date
          await _updateVideoMetadata(cacheKey, {
            'lastAccessed': now.toIso8601String(),
          });
          
          return videoFile.path;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download and cache video
  Future<String?> cacheVideo(String videoUrl, {
    Function(int downloaded, int total)? onProgress,
  }) async {
    final cacheKey = _generateCacheKey(videoUrl);
    
    // Check if already cached
    final cachedPath = await getCachedVideoPath(videoUrl);
    if (cachedPath != null) {
      return cachedPath;
    }

    // Check if already downloading
    if (_activeDownloads.containsKey(cacheKey)) {
      return await _activeDownloads[cacheKey];
    }

    // Start download
    final downloadFuture = _downloadVideo(videoUrl, cacheKey, onProgress);
    _activeDownloads[cacheKey] = downloadFuture;

    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _activeDownloads.remove(cacheKey);
    }
  }

  /// Download video from URL
  Future<String?> _downloadVideo(
    String videoUrl,
    String cacheKey,
    Function(int, int)? onProgress,
  ) async {
    File? tempFile;
    try {
      final cacheDir = await _getCacheDirectory();
      final videoFile = File('${cacheDir.path}/$cacheKey.mp4');
      
      // Create temporary file for download
      tempFile = File('${cacheDir.path}/$cacheKey.tmp');
      
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(videoUrl));
      
      // Set headers for video download
      request.headers.addAll({
        'Accept': 'video/*',
        'Range': 'bytes=0-', // Support resumable downloads
      });
      
      final streamedResponse = await client.send(request).timeout(
        const Duration(minutes: 30), // 30 minute timeout for large videos
      );
      
      if (streamedResponse.statusCode != 200 && streamedResponse.statusCode != 206) {
        client.close();
        return null;
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      int downloaded = 0;

      // Write to temporary file
      final sink = tempFile.openWrite();
      try {
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloaded += chunk.length;
          
          if (onProgress != null && contentLength > 0) {
            onProgress(downloaded, contentLength);
          }
        }
      } finally {
        await sink.close();
        client.close();
      }

      // Move temp file to final location
      if (await tempFile.exists()) {
        final fileSize = await tempFile.length();
        
        // Only cache if file is valid (at least 1KB)
        if (fileSize > 1024) {
          await tempFile.rename(videoFile.path);
          
          // Save metadata
          await _saveVideoMetadata(cacheKey, {
            'videoUrl': videoUrl,
            'cachedDate': DateTime.now().toIso8601String(),
            'lastAccessed': DateTime.now().toIso8601String(),
            'fileSize': fileSize,
          });

          return videoFile.path;
        } else {
          // File too small, likely an error response
          await tempFile.delete();
        }
      }
      
      return null;
    } catch (e) {
      // Clean up temp file on error
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      
      return null;
    }
  }

  /// Get video metadata
  Future<Map<String, dynamic>?> _getVideoMetadata(String cacheKey) async {
    try {
      await _ensurePrefs();
      final metadataJson = _prefs?.getString(_cacheMetadataKey);
      if (metadataJson == null) return null;

      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      return metadata[cacheKey] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Save video metadata
  Future<void> _saveVideoMetadata(String cacheKey, Map<String, dynamic> data) async {
    try {
      await _ensurePrefs();
      final metadataJson = _prefs?.getString(_cacheMetadataKey);
      Map<String, dynamic> metadata = {};
      
      if (metadataJson != null) {
        metadata = json.decode(metadataJson) as Map<String, dynamic>;
      }
      
      metadata[cacheKey] = data;
      await _prefs?.setString(_cacheMetadataKey, json.encode(metadata));
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Update video metadata
  Future<void> _updateVideoMetadata(String cacheKey, Map<String, dynamic> updates) async {
    try {
      final existing = await _getVideoMetadata(cacheKey);
      if (existing != null) {
        existing.addAll(updates);
        await _saveVideoMetadata(cacheKey, existing);
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Remove video metadata
  Future<void> _removeVideoMetadata(String cacheKey) async {
    try {
      await _ensurePrefs();
      final metadataJson = _prefs?.getString(_cacheMetadataKey);
      if (metadataJson == null) return;

      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      metadata.remove(cacheKey);
      await _prefs?.setString(_cacheMetadataKey, json.encode(metadata));
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      int totalSize = 0;
      
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clean up expired videos
  Future<void> _cleanupExpiredVideos() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final now = DateTime.now();
      
      await for (final entity in cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          final fileName = entity.path.split('/').last;
          final cacheKey = fileName.replaceAll('.mp4', '');
          
          final metadata = await _getVideoMetadata(cacheKey);
          if (metadata != null) {
            final cachedDate = DateTime.parse(metadata['cachedDate'] as String);
            if (now.difference(cachedDate) > _cacheExpiryDays) {
              await entity.delete();
              await _removeVideoMetadata(cacheKey);
            }
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Manage cache size - delete oldest videos if cache is too large
  Future<void> _manageCacheSize() async {
    try {
      final cacheSize = await getCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      
      if (cacheSize > maxSizeBytes) {
        // Get all videos sorted by last accessed date
        final videos = await _getAllCachedVideos();
        videos.sort((a, b) {
          final aDate = DateTime.parse(a['lastAccessed'] as String);
          final bDate = DateTime.parse(b['lastAccessed'] as String);
          return aDate.compareTo(bDate);
        });
        
        // Delete oldest videos until under limit
        int currentSize = cacheSize;
        for (final video in videos) {
          if (currentSize <= maxSizeBytes) break;
          
          final cacheKey = video['cacheKey'] as String;
          final fileSize = video['fileSize'] as int;
          
          final cacheDir = await _getCacheDirectory();
          final videoFile = File('${cacheDir.path}/$cacheKey.mp4');
          
          if (await videoFile.exists()) {
            await videoFile.delete();
            await _removeVideoMetadata(cacheKey);
            currentSize -= fileSize;
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get all cached videos with metadata
  Future<List<Map<String, dynamic>>> _getAllCachedVideos() async {
    try {
      await _ensurePrefs();
      final metadataJson = _prefs?.getString(_cacheMetadataKey);
      if (metadataJson == null) return [];

      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      final videos = <Map<String, dynamic>>[];

      for (final entry in metadata.entries) {
        final videoData = entry.value as Map<String, dynamic>;
        videos.add({
          'cacheKey': entry.key,
          ...videoData,
        });
      }

      return videos;
    } catch (e) {
      return [];
    }
  }

  /// Clear all cached videos
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      
      await _ensurePrefs();
      await _prefs?.remove(_cacheMetadataKey);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear specific video from cache
  Future<void> clearVideoCache(String videoUrl) async {
    try {
      final cacheKey = _generateCacheKey(videoUrl);
      final cacheDir = await _getCacheDirectory();
      final videoFile = File('${cacheDir.path}/$cacheKey.mp4');
      
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
      
      await _removeVideoMetadata(cacheKey);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Pre-download video in background (for offline access)
  Future<void> preloadVideo(String videoUrl) async {
    // Don't await - let it download in background
    cacheVideo(videoUrl).catchError((_) {
      // Silently handle preload errors
      return null;
    });
  }

  /// Check if video is cached
  Future<bool> isVideoCached(String videoUrl) async {
    final cachedPath = await getCachedVideoPath(videoUrl);
    return cachedPath != null;
  }
}

